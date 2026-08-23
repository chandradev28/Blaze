class SpeedResult {
  const SpeedResult({
    required this.timestamp,
    required this.download,
    required this.upload,
    required this.ping,
    required this.jitter,
    required this.server,
    required this.provider,
    required this.downloadSamples,
    required this.uploadSamples,
    required this.bytesUsed,
  });

  final DateTime timestamp;

  /// Decimal megabytes per second (MBps), not megabits per second.
  final double download;
  final double upload;
  final double ping;
  final double jitter;
  final String server;
  final String provider;
  final int downloadSamples;
  final int uploadSamples;
  final int bytesUsed;

  double get confidence {
    final sampleScore =
        ((downloadSamples + uploadSamples) / 10).clamp(0.0, 1.0);
    final dataScore = (bytesUsed / (20 * 1024 * 1024)).clamp(0.0, 1.0);
    return (sampleScore * 0.45 + dataScore * 0.55).clamp(0.0, 1.0);
  }

  String get quality {
    if (download >= 25 && ping < 30) return 'Excellent';
    if (download >= 6.25 && ping < 70) return 'Good';
    if (download >= 1.25) return 'Stable';
    return 'Needs a boost';
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'speedUnit': 'MBps',
        'download': download,
        'upload': upload,
        'ping': ping,
        'jitter': jitter,
        'server': server,
        'provider': provider,
        'downloadSamples': downloadSamples,
        'uploadSamples': uploadSamples,
        'bytesUsed': bytesUsed,
      };

  factory SpeedResult.fromJson(Map<String, dynamic> json) {
    // Results saved by pre-MBps builds were stored as Mbps. Migrate them once
    // so history does not suddenly report values eight times too high.
    final storedUnit = json['speedUnit'] as String?;
    final conversion = storedUnit == 'MBps' ? 1.0 : 1 / 8;
    return SpeedResult(
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      download: ((json['download'] as num?)?.toDouble() ?? 0) * conversion,
      upload: ((json['upload'] as num?)?.toDouble() ?? 0) * conversion,
      ping: (json['ping'] as num?)?.toDouble() ?? 0,
      jitter: (json['jitter'] as num?)?.toDouble() ?? 0,
      server: json['server'] as String? ?? 'Blaze edge',
      provider: json['provider'] as String? ?? 'Network detected',
      downloadSamples: (json['downloadSamples'] as num?)?.toInt() ?? 1,
      uploadSamples: (json['uploadSamples'] as num?)?.toInt() ?? 1,
      bytesUsed: (json['bytesUsed'] as num?)?.toInt() ?? 0,
    );
  }
}
