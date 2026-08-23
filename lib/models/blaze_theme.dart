import 'package:flutter/material.dart';

enum GaugeStyle { classic, f1, motoGp, electric, neon }

extension GaugeStyleLabel on GaugeStyle {
  String get label {
    switch (this) {
      case GaugeStyle.classic:
        return 'Classic';
      case GaugeStyle.f1:
        return 'F1 Telemetry';
      case GaugeStyle.motoGp:
        return 'MotoGP';
      case GaugeStyle.electric:
        return 'Electric';
      case GaugeStyle.neon:
        return 'Neon';
    }
  }
}

class BlazeTheme {
  const BlazeTheme({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.gaugeStyle,
    required this.maxSpeed,
    required this.motion,
    required this.showGrid,
    required this.showGlow,
    required this.showSweep,
    required this.showPulse,
  });

  final String id;
  final String name;
  final String subtitle;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final GaugeStyle gaugeStyle;
  final int maxSpeed;
  final double motion;
  final bool showGrid;
  final bool showGlow;
  final bool showSweep;
  final bool showPulse;

  BlazeTheme copyWith({
    String? id,
    String? name,
    String? subtitle,
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    GaugeStyle? gaugeStyle,
    int? maxSpeed,
    double? motion,
    bool? showGrid,
    bool? showGlow,
    bool? showSweep,
    bool? showPulse,
  }) {
    return BlazeTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      gaugeStyle: gaugeStyle ?? this.gaugeStyle,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      motion: motion ?? this.motion,
      showGrid: showGrid ?? this.showGrid,
      showGlow: showGlow ?? this.showGlow,
      showSweep: showSweep ?? this.showSweep,
      showPulse: showPulse ?? this.showPulse,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'primary': primary.value,
        'secondary': secondary.value,
        'background': background.value,
        'surface': surface.value,
        'gaugeStyle': gaugeStyle.name,
        'maxSpeed': maxSpeed,
        'motion': motion,
        'showGrid': showGrid,
        'showGlow': showGlow,
        'showSweep': showSweep,
        'showPulse': showPulse,
      };

  factory BlazeTheme.fromJson(Map<String, dynamic> json) {
    final styleName = json['gaugeStyle'] as String? ?? 'classic';
    final style = GaugeStyle.values.firstWhere(
      (item) => item.name == styleName,
      orElse: () => GaugeStyle.classic,
    );
    return BlazeTheme(
      id: json['id'] as String? ?? 'saved',
      name: json['name'] as String? ?? 'Saved dashboard',
      subtitle: json['subtitle'] as String? ?? 'Custom build',
      primary: Color((json['primary'] as num?)?.toInt() ?? 0xFFFF6A3D),
      secondary: Color((json['secondary'] as num?)?.toInt() ?? 0xFFFFC857),
      background: Color((json['background'] as num?)?.toInt() ?? 0xFF000000),
      surface: Color((json['surface'] as num?)?.toInt() ?? 0xFF12141B),
      gaugeStyle: style,
      maxSpeed: (json['maxSpeed'] as num?)?.toInt() ?? 100,
      motion: (json['motion'] as num?)?.toDouble() ?? 0.75,
      showGrid: json['showGrid'] as bool? ?? true,
      showGlow: json['showGlow'] as bool? ?? true,
      showSweep: json['showSweep'] as bool? ?? true,
      showPulse: json['showPulse'] as bool? ?? true,
    );
  }

  static const presets = <BlazeTheme>[
    BlazeTheme(
      id: 'blaze-core',
      name: 'Blaze Core',
      subtitle: 'The signature dashboard',
      primary: Color(0xFFFF6A3D),
      secondary: Color(0xFFFFC857),
      background: Color(0xFF000000),
      surface: Color(0xFF12141B),
      gaugeStyle: GaugeStyle.classic,
      maxSpeed: 100,
      motion: 0.80,
      showGrid: true,
      showGlow: true,
      showSweep: true,
      showPulse: true,
    ),
    BlazeTheme(
      id: 'grand-prix',
      name: 'Grand Prix',
      subtitle: 'Telemetry for the fast lane',
      primary: Color(0xFFFF3B30),
      secondary: Color(0xFFFFD166),
      background: Color(0xFF000000),
      surface: Color(0xFF211114),
      gaugeStyle: GaugeStyle.f1,
      maxSpeed: 250,
      motion: 0.92,
      showGrid: true,
      showGlow: true,
      showSweep: true,
      showPulse: true,
    ),
    BlazeTheme(
      id: 'moto-circuit',
      name: 'Moto Circuit',
      subtitle: 'Lean into the next test',
      primary: Color(0xFF42D6FF),
      secondary: Color(0xFFB3F4FF),
      background: Color(0xFF000000),
      surface: Color(0xFF0B2028),
      gaugeStyle: GaugeStyle.motoGp,
      maxSpeed: 150,
      motion: 0.88,
      showGrid: false,
      showGlow: true,
      showSweep: true,
      showPulse: true,
    ),
    BlazeTheme(
      id: 'electric-pulse',
      name: 'Electric Pulse',
      subtitle: 'Silent power, instant torque',
      primary: Color(0xFF8BFF74),
      secondary: Color(0xFFD6FFB8),
      background: Color(0xFF000000),
      surface: Color(0xFF0E1D12),
      gaugeStyle: GaugeStyle.electric,
      maxSpeed: 500,
      motion: 0.66,
      showGrid: true,
      showGlow: true,
      showSweep: true,
      showPulse: true,
    ),
    BlazeTheme(
      id: 'rally-storm',
      name: 'Rally Storm',
      subtitle: 'Grip, grit, and great Wi-Fi',
      primary: Color(0xFFFF9F1C),
      secondary: Color(0xFFFFE29A),
      background: Color(0xFF000000),
      surface: Color(0xFF241A0B),
      gaugeStyle: GaugeStyle.classic,
      maxSpeed: 100,
      motion: 1.0,
      showGrid: true,
      showGlow: false,
      showSweep: true,
      showPulse: true,
    ),
    BlazeTheme(
      id: 'neon-street',
      name: 'Neon Street',
      subtitle: 'Midnight speed, bright signal',
      primary: Color(0xFFFF4ECD),
      secondary: Color(0xFF7C5CFF),
      background: Color(0xFF000000),
      surface: Color(0xFF1D1029),
      gaugeStyle: GaugeStyle.neon,
      maxSpeed: 200,
      motion: 0.78,
      showGrid: true,
      showGlow: true,
      showSweep: true,
      showPulse: true,
    ),
  ];
}
