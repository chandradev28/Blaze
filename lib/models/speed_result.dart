class SpeedResult {
  const SpeedResult({
    required this.timestamp,
    required this.download,
    required this.upload,
    required this.ping,
    required this.jitter,
    required this.server,
    required this.provider,
  });

  final DateTime timestamp;
  final double download;
  final double upload;
  final double ping;
  final double jitter;
  final String server;
  final String provider;

  String get quality {
    if (download >= 200 && ping < 30) return 'Excellent';
    if (download >= 50 && ping < 70) return 'Good';
    if (download >= 10) return 'Stable';
    return 'Needs a boost';
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'download': download,
        'upload': upload,
        'ping': ping,
        'jitter': jitter,
        'server': server,
        'provider': provider,
      };

  factory SpeedResult.fromJson(Map<String, dynamic> json) => SpeedResult(
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        download: (json['download'] as num?)?.toDouble() ?? 0,
        upload: (json['upload'] as num?)?.toDouble() ?? 0,
        ping: (json['ping'] as num?)?.toDouble() ?? 0,
        jitter: (json['jitter'] as num?)?.toDouble() ?? 0,
        server: json['server'] as String? ?? 'Blaze edge',
        provider: json['provider'] as String? ?? 'Network detected',
      );
}
