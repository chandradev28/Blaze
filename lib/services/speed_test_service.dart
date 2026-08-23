import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../models/speed_result.dart';

enum TestPhase { idle, connecting, ping, download, upload, finished, error }

class SpeedTestProgress {
  const SpeedTestProgress({required this.fraction, required this.speedMBps});

  final double fraction;
  final double speedMBps;
}

class SpeedTestException implements Exception {
  const SpeedTestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SpeedTestService {
  static final _base = Uri.parse('https://speed.cloudflare.com');

  // This ramp-up follows the same principle as mature speed-test engines:
  // measure several request sizes concurrently instead of trusting one file.
  // Progress reports expose aggregate decimal megabytes per second while the
  // final result uses the complete batch elapsed time.
  static const _downloadPlan = [
    2 * 1024 * 1024,
    4 * 1024 * 1024,
    8 * 1024 * 1024,
  ];
  static const _uploadPlan = [
    1 * 1024 * 1024,
    2 * 1024 * 1024,
    4 * 1024 * 1024,
  ];

  Future<SpeedResult> run({
    required void Function(TestPhase phase) onPhase,
    required void Function(SpeedTestProgress progress) onProgress,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 12)
      ..maxConnectionsPerHost = 8;
    try {
      onPhase(TestPhase.connecting);
      final metadata = await _metadata(client);

      onPhase(TestPhase.ping);
      final pingSamples = await _measurePing(client, onProgress);
      final ping = _percentile(pingSamples, 0.5);
      final jitter = _averageDelta(pingSamples);

      onPhase(TestPhase.download);
      final downloadBatch = await _measureBatch(
        client,
        direction: _Direction.download,
        plan: _downloadPlan,
        onProgress: onProgress,
      );

      onPhase(TestPhase.upload);
      final uploadBatch = await _measureBatch(
        client,
        direction: _Direction.upload,
        plan: _uploadPlan,
        onProgress: onProgress,
      );

      onPhase(TestPhase.finished);
      return SpeedResult(
        timestamp: DateTime.now(),
        download: downloadBatch.megabytesPerSecond,
        upload: uploadBatch.megabytesPerSecond,
        ping: ping,
        jitter: jitter,
        server: metadata['colo']?.toString() ?? 'Cloudflare edge',
        provider: metadata['asOrganization']?.toString() ?? 'Network detected',
        downloadSamples: downloadBatch.samples,
        uploadSamples: uploadBatch.samples,
        bytesUsed: downloadBatch.bytes + uploadBatch.bytes,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _metadata(HttpClient client) async {
    try {
      final request = await client.getUrl(_base.resolve('/meta'));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        return const {};
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  Future<List<double>> _measurePing(
    HttpClient client,
    void Function(SpeedTestProgress progress) onProgress,
  ) async {
    final samples = <double>[];
    // Ignore the first request as a connection warm-up. Eight samples leave
    // seven observations for the median/jitter calculation.
    for (var index = 0; index < 8; index++) {
      final watch = Stopwatch()..start();
      final request = await client.getUrl(_base.resolve(
        '/__down?bytes=0&measId=${DateTime.now().microsecondsSinceEpoch}',
      ));
      final response = await request.close();
      await response.drain<void>();
      watch.stop();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const SpeedTestException(
            'The test server rejected the latency check.');
      }
      if (index > 0) samples.add(watch.elapsedMicroseconds / 1000);
      onProgress(SpeedTestProgress(fraction: (index + 1) / 8, speedMBps: 0));
    }
    if (samples.length < 3) {
      throw const SpeedTestException(
          'Not enough latency samples were returned.');
    }
    return samples;
  }

  Future<_BatchResult> _measureBatch(
    HttpClient client, {
    required _Direction direction,
    required List<int> plan,
    required void Function(SpeedTestProgress progress) onProgress,
  }) async {
    final expectedBytes = plan.fold<int>(0, (sum, bytes) => sum + bytes);
    var completedBytes = 0;
    final wallClock = Stopwatch()..start();

    void reportProgress([int delta = 0]) {
      completedBytes += delta;
      final elapsedSeconds =
          math.max(wallClock.elapsedMicroseconds / 1000000, 0.001);
      onProgress(SpeedTestProgress(
        fraction: (completedBytes / expectedBytes).clamp(0.0, 1.0),
        speedMBps: completedBytes / elapsedSeconds / 1000000,
      ));
    }

    final measurements = await Future.wait(
      plan.map((bytes) async {
        final measurement = direction == _Direction.download
            ? await _downloadRequest(client, bytes, reportProgress)
            : await _uploadRequest(client, bytes, reportProgress);
        return measurement;
      }),
    );
    wallClock.stop();

    final totalBytes =
        measurements.fold<int>(0, (sum, item) => sum + item.bytes);
    if (totalBytes < expectedBytes * 0.9) {
      throw SpeedTestException(
        '${direction.name.capitalize()} test returned incomplete data. No result was saved.',
      );
    }
    if (wallClock.elapsedMilliseconds < 8) {
      throw const SpeedTestException(
          'The test completed too quickly to produce a reliable result.');
    }

    final seconds = math.max(wallClock.elapsedMicroseconds / 1000000, 0.001);
    final megabytesPerSecond = totalBytes / seconds / 1000000;
    onProgress(SpeedTestProgress(
      fraction: 1,
      speedMBps: megabytesPerSecond,
    ));
    return _BatchResult(
        megabytesPerSecond: megabytesPerSecond,
        bytes: totalBytes,
        samples: measurements.length);
  }

  Future<_TransferResult> _downloadRequest(
    HttpClient client,
    int bytes,
    void Function(int delta) onBytes,
  ) async {
    final request = await client.getUrl(_base.resolve(
      '/__down?bytes=$bytes&measId=${DateTime.now().microsecondsSinceEpoch}',
    ));
    request.headers.add(HttpHeaders.cacheControlHeader, 'no-cache');
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw const SpeedTestException('The download server returned an error.');
    }
    var received = 0;
    await for (final chunk in response) {
      received += chunk.length;
      onBytes(chunk.length);
    }
    if (received < bytes * 0.9) {
      throw const SpeedTestException(
          'The download stream ended early. No result was saved.');
    }
    return _TransferResult(bytes: received);
  }

  Future<_TransferResult> _uploadRequest(
    HttpClient client,
    int bytes,
    void Function(int delta) onBytes,
  ) async {
    final payload = List<int>.filled(bytes, 66);
    final request = await client.postUrl(_base.resolve(
      '/__up?measId=${DateTime.now().microsecondsSinceEpoch}',
    ));
    request.headers
      ..contentType = ContentType.binary
      ..contentLength = payload.length
      ..add(HttpHeaders.cacheControlHeader, 'no-cache');
    request.add(payload);
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const SpeedTestException('The upload server returned an error.');
    }
    onBytes(payload.length);
    return _TransferResult(bytes: payload.length);
  }

  double _percentile(List<double> values, double percentile) {
    final sorted = [...values]..sort();
    final position = (sorted.length - 1) * percentile;
    final lower = position.floor();
    final upper = position.ceil();
    if (lower == upper) return sorted[lower];
    return sorted[lower] + (sorted[upper] - sorted[lower]) * (position - lower);
  }

  double _averageDelta(List<double> values) {
    if (values.length < 2) return 0;
    var total = 0.0;
    for (var index = 1; index < values.length; index++) {
      total += (values[index] - values[index - 1]).abs();
    }
    return total / (values.length - 1);
  }
}

enum _Direction { download, upload }

class _TransferResult {
  const _TransferResult({required this.bytes});

  final int bytes;
}

class _BatchResult {
  const _BatchResult(
      {required this.megabytesPerSecond,
      required this.bytes,
      required this.samples});

  final double megabytesPerSecond;
  final int bytes;
  final int samples;
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
