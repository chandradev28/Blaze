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

  /// Decimal megabits per second (Mbps), the standard consumer speed unit.
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
    if (download >= 200 && ping < 30) return 'Excellent';
    if (download >= 50 && ping < 70) return 'Good';
    if (download >= 10) return 'Stable';
    return 'Needs a boost';
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'speedUnit': 'Mbps',
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
    // The immediately preceding build stored MBps. Convert those values back
    // to the standard Mbps unit. Older/unspecified results already used Mbps.
    final storedUnit = json['speedUnit'] as String?;
    final conversion = storedUnit == 'MBps' ? 8.0 : 1.0;
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
