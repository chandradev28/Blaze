import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../models/speed_result.dart';

enum TestPhase { idle, connecting, ping, download, upload, finished, error }

class SpeedTestProgress {
  const SpeedTestProgress({required this.fraction, required this.speedMbps});

  final double fraction;
  final double speedMbps;
}

class SpeedTestException implements Exception {
  const SpeedTestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SpeedTestService {
  static final _base = Uri.parse('https://speed.cloudflare.com');
  static final Uint8List _uploadBuffer = _makeUploadBuffer();

  static const _testDuration = Duration(seconds: 6);
  static const _downloadLimit = 160 * 1024 * 1024;
  static const _uploadLimit = 96 * 1024 * 1024;

  Future<SpeedResult> run({
    required void Function(TestPhase phase) onPhase,
    required void Function(SpeedTestProgress progress) onProgress,
  }) async {
    final client = HttpClient()
      ..autoUncompress = false
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 15)
      ..maxConnectionsPerHost = 8;
    try {
      onPhase(TestPhase.connecting);
      final metadata = await _metadata(client);

      onPhase(TestPhase.ping);
      final pingSamples = await _measurePing(client, onProgress);
      final ping = _percentile(pingSamples, 0.5);
      final jitter = _averageDelta(pingSamples);

      onPhase(TestPhase.download);
      final downloadBatch = await _measureAdaptive(
        client,
        direction: _Direction.download,
        onProgress: onProgress,
      );

      onPhase(TestPhase.upload);
      final uploadBatch = await _measureAdaptive(
        client,
        direction: _Direction.upload,
        onProgress: onProgress,
      );

      onPhase(TestPhase.finished);
      return SpeedResult(
        timestamp: DateTime.now(),
        download: downloadBatch.megabitsPerSecond,
        upload: uploadBatch.megabitsPerSecond,
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
    const requestCount = 12;
    for (var index = 0; index < requestCount; index++) {
      final watch = Stopwatch()..start();
      final request = await client.getUrl(_measurementUri('/__down', 0));
      final response = await request.close();
      watch.stop();
      await response.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const SpeedTestException(
          'The test server rejected the latency check.',
        );
      }
      // Two requests warm DNS, TLS and the persistent connection. The median
      // of the remaining samples is stable without cherry-picking one low ping.
      if (index >= 2) samples.add(watch.elapsedMicroseconds / 1000);
      onProgress(
        SpeedTestProgress(
          fraction: (index + 1) / requestCount,
          speedMbps: 0,
        ),
      );
    }
    if (samples.length < 3) {
      throw const SpeedTestException(
        'Not enough latency samples were returned.',
      );
    }
    return samples;
  }

  Future<_BatchResult> _measureAdaptive(
    HttpClient client, {
    required _Direction direction,
    required void Function(SpeedTestProgress progress) onProgress,
  }) async {
    // A short unscored probe warms the path and sizes the real transfer. This
    // avoids a tiny request on fast links and excessive data on slow links.
    final probeBytes =
        direction == _Direction.download ? 1024 * 1024 : 384 * 1024;
    final probe = direction == _Direction.download
        ? await _downloadRequest(client, probeBytes, (_) {})
        : await _uploadRequest(client, probeBytes, (_) {});
    final estimateMbps = _toMbps(probe.bytes, probe.elapsed);
    final streams = _streamCount(estimateMbps);
    final requestBytes = _requestSize(
      estimateMbps,
      streams,
      direction: direction,
    );
    final byteLimit =
        direction == _Direction.download ? _downloadLimit : _uploadLimit;

    var transferredBytes = 0;
    var completedRequests = 0;
    var lastReportBytes = 0;
    var lastReportMicros = 0;
    var smoothedMbps = 0.0;
    final watch = Stopwatch()..start();

    void reportBytes(int delta) {
      transferredBytes += delta;
      final elapsedMicros = math.max(watch.elapsedMicroseconds, 1);
      final intervalMicros = elapsedMicros - lastReportMicros;
      if (intervalMicros < 80 * 1000 && transferredBytes < byteLimit) return;

      final intervalBytes = transferredBytes - lastReportBytes;
      final instantMbps = intervalBytes * 8 * 1000000 / intervalMicros / 1e6;
      smoothedMbps = smoothedMbps == 0
          ? instantMbps
          : smoothedMbps * 0.62 + instantMbps * 0.38;
      lastReportBytes = transferredBytes;
      lastReportMicros = elapsedMicros;
      onProgress(
        SpeedTestProgress(
          fraction: (watch.elapsedMicroseconds / _testDuration.inMicroseconds)
              .clamp(0.0, 0.99),
          speedMbps: smoothedMbps,
        ),
      );
    }

    Future<void> worker() async {
      while (watch.elapsed < _testDuration && transferredBytes < byteLimit) {
        if (direction == _Direction.download) {
          await _downloadRequest(client, requestBytes, reportBytes);
        } else {
          await _uploadRequest(client, requestBytes, reportBytes);
        }
        completedRequests++;
      }
    }

    await Future.wait(List.generate(streams, (_) => worker()));
    watch.stop();

    if (transferredBytes < 128 * 1024 || completedRequests == 0) {
      throw SpeedTestException(
        '${direction.name.capitalize()} test returned too little data. No result was saved.',
      );
    }
    if (watch.elapsedMilliseconds < 100) {
      throw const SpeedTestException(
        'The test completed too quickly to produce a reliable result.',
      );
    }

    final finalMbps = _toMbps(transferredBytes, watch.elapsed);
    onProgress(SpeedTestProgress(fraction: 1, speedMbps: finalMbps));
    return _BatchResult(
      megabitsPerSecond: finalMbps,
      bytes: transferredBytes + probe.bytes,
      samples: completedRequests + 1,
    );
  }

  int _streamCount(double estimateMbps) {
    if (estimateMbps < 5) return 2;
    if (estimateMbps < 80) return 4;
    if (estimateMbps < 300) return 6;
    return 8;
  }

  int _requestSize(
    double estimateMbps,
    int streams, {
    required _Direction direction,
  }) {
    final bytesPerSecond = estimateMbps * 1000000 / 8;
    final target = (bytesPerSecond * 0.9 / streams).round();
    final maximum =
        direction == _Direction.download ? 8 * 1024 * 1024 : 4 * 1024 * 1024;
    return target.clamp(256 * 1024, maximum);
  }

  Future<_TransferResult> _downloadRequest(
    HttpClient client,
    int bytes,
    void Function(int delta) onBytes,
  ) async {
    final watch = Stopwatch()..start();
    final request = await client.getUrl(_measurementUri('/__down', bytes));
    request.headers.add(HttpHeaders.cacheControlHeader, 'no-store');
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
    watch.stop();
    if (received < bytes * 0.9) {
      throw const SpeedTestException(
        'The download stream ended early. No result was saved.',
      );
    }
    return _TransferResult(bytes: received, elapsed: watch.elapsed);
  }

  Future<_TransferResult> _uploadRequest(
    HttpClient client,
    int bytes,
    void Function(int delta) onBytes,
  ) async {
    final watch = Stopwatch()..start();
    final request = await client.postUrl(_measurementUri('/__up', bytes));
    request
      ..bufferOutput = false
      ..headers.contentType = ContentType.binary
      ..contentLength = bytes;
    request.headers.add(HttpHeaders.cacheControlHeader, 'no-store');

    var sent = 0;
    var unreported = 0;
    while (sent < bytes) {
      final count = math.min(_uploadBuffer.length, bytes - sent);
      request.add(
        count == _uploadBuffer.length
            ? _uploadBuffer
            : Uint8List.sublistView(_uploadBuffer, 0, count),
      );
      sent += count;
      unreported += count;
      if (unreported >= 512 * 1024 || sent == bytes) {
        await request.flush();
        onBytes(unreported);
        unreported = 0;
      }
    }

    final response = await request.close();
    await response.drain<void>();
    watch.stop();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const SpeedTestException('The upload server returned an error.');
    }
    return _TransferResult(bytes: sent, elapsed: watch.elapsed);
  }

  Uri _measurementUri(String path, int bytes) {
    return _base.resolve(path).replace(
      queryParameters: {
        'bytes': '$bytes',
        'measId': '${DateTime.now().microsecondsSinceEpoch}',
      },
    );
  }

  double _toMbps(int bytes, Duration elapsed) {
    final seconds = math.max(elapsed.inMicroseconds / 1000000, 0.001);
    return bytes * 8 / seconds / 1000000;
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

Uint8List _makeUploadBuffer() {
  final bytes = Uint8List(64 * 1024);
  var state = 0x5A17C9E3;
  for (var index = 0; index < bytes.length; index++) {
    state = (state ^ (state << 13)) & 0xFFFFFFFF;
    state = (state ^ (state >> 17)) & 0xFFFFFFFF;
    state = (state ^ (state << 5)) & 0xFFFFFFFF;
    bytes[index] = state & 0xFF;
  }
  return bytes;
}

enum _Direction { download, upload }

class _TransferResult {
  const _TransferResult({required this.bytes, required this.elapsed});

  final int bytes;
  final Duration elapsed;
}

class _BatchResult {
  const _BatchResult({
    required this.megabitsPerSecond,
    required this.bytes,
    required this.samples,
  });

  final double megabitsPerSecond;
  final int bytes;
  final int samples;
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
