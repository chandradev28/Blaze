import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../models/speed_result.dart';

enum TestPhase { idle, connecting, ping, download, upload, finished, error }

class SpeedTestService {
  static final _base = Uri.parse('https://speed.cloudflare.com');
  static const _downloadBytes = 4 * 1024 * 1024;
  static const _uploadBytes = 1 * 1024 * 1024;

  Future<SpeedResult> run({
    required void Function(TestPhase phase) onPhase,
    required void Function(double progress) onProgress,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      onPhase(TestPhase.connecting);
      final metadata = await _metadata(client);

      onPhase(TestPhase.ping);
      final pingSamples = <double>[];
      for (var index = 0; index < 4; index++) {
        final watch = Stopwatch()..start();
        final request = await client.getUrl(
          _base.resolve(
              '/__down?bytes=0&measId=${DateTime.now().microsecondsSinceEpoch}'),
        );
        final response = await request.close();
        await response.drain<void>();
        watch.stop();
        pingSamples.add(watch.elapsedMicroseconds / 1000);
        onProgress((index + 1) / 4);
      }

      final ping = pingSamples.reduce((a, b) => a + b) / pingSamples.length;
      final jitter = _jitter(pingSamples);

      onPhase(TestPhase.download);
      final download = await _download(client, onProgress);

      onPhase(TestPhase.upload);
      final upload = await _upload(client, onProgress);

      onPhase(TestPhase.finished);
      return SpeedResult(
        timestamp: DateTime.now(),
        download: download,
        upload: upload,
        ping: ping,
        jitter: jitter,
        server: metadata['colo']?.toString() ?? 'Cloudflare edge',
        provider: metadata['asOrganization']?.toString() ?? 'Network detected',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _metadata(HttpClient client) async {
    try {
      final request = await client.getUrl(_base.resolve('/meta'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  Future<double> _download(
    HttpClient client,
    void Function(double progress) onProgress,
  ) async {
    final uri = _base.resolve(
      '/__down?bytes=$_downloadBytes&measId=${DateTime.now().microsecondsSinceEpoch}',
    );
    final watch = Stopwatch()..start();
    final request = await client.getUrl(uri);
    final response = await request.close();
    var received = 0;
    await for (final chunk in response) {
      received += chunk.length;
      onProgress((received / _downloadBytes).clamp(0.0, 1.0));
    }
    watch.stop();
    return _mbps(received, watch.elapsed);
  }

  Future<double> _upload(
    HttpClient client,
    void Function(double progress) onProgress,
  ) async {
    final payload = List<int>.filled(_uploadBytes, 66);
    final watch = Stopwatch()..start();
    final request = await client.postUrl(
      _base.resolve('/__up?measId=${DateTime.now().microsecondsSinceEpoch}'),
    );
    request.headers.contentType = ContentType.binary;
    request.contentLength = payload.length;
    request.add(payload);
    final response = await request.close();
    await response.drain<void>();
    watch.stop();
    onProgress(1);
    return _mbps(payload.length, watch.elapsed);
  }

  double _mbps(int bytes, Duration duration) {
    final seconds = math.max(duration.inMicroseconds / 1000000, 0.001);
    return (bytes * 8 / seconds) / 1000000;
  }

  double _jitter(List<double> samples) {
    if (samples.length < 2) return 0;
    var total = 0.0;
    for (var index = 1; index < samples.length; index++) {
      total += (samples[index] - samples[index - 1]).abs();
    }
    return total / (samples.length - 1);
  }
}
