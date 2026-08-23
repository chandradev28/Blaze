import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'blaze_theme.dart';

class DialNeedleSpec {
  const DialNeedleSpec({
    required this.pivot,
    required this.startAngle,
    required this.sweepAngle,
    required this.length,
    required this.color,
    this.width = 5,
    this.hubRadius = 0.035,
    this.hubColor = const Color(0xFF17181A),
    this.speedMultiplier = 1,
  });

  final Offset pivot;
  final double startAngle;
  final double sweepAngle;
  final double length;
  final Color color;
  final double width;
  final double hubRadius;
  final Color hubColor;
  final double speedMultiplier;
}

class DialProfile {
  const DialProfile({
    required this.themeId,
    required this.name,
    required this.subtitle,
    this.assetPath,
    this.imageScale = 1,
    this.imageAlignment = Alignment.center,
    this.needles = const [],
  });

  final String themeId;
  final String name;
  final String subtitle;
  final String? assetPath;
  final double imageScale;
  final Alignment imageAlignment;
  final List<DialNeedleSpec> needles;

  BlazeTheme get theme => BlazeTheme.presets.firstWhere(
        (item) => item.id == themeId,
        orElse: () => BlazeTheme.presets.first,
      );

  bool get usesPhoto => assetPath != null;

  static const presets = <DialProfile>[
    DialProfile(
      themeId: 'blaze-core',
      name: 'Reference Classic',
      subtitle: 'Mechanical white face',
    ),
    DialProfile(
      themeId: 'aventador-blue',
      name: 'Aventador',
      subtitle: 'V12 blue instrument',
      assetPath: 'assets/dials/lamborghini-clean.png',
      needles: [
        DialNeedleSpec(
          pivot: Offset(0.50, 0.50),
          startAngle: math.pi / 2,
          sweepAngle: math.pi * 1.50,
          length: 0.34,
          color: Color(0xFFFF3448),
          width: 5,
          hubRadius: 0.034,
          hubColor: Color(0xFFD4F4FF),
        ),
      ],
    ),
    DialProfile(
      themeId: 'ferrari-center',
      name: 'Ferrari Center',
      subtitle: 'Central race tachometer',
      assetPath: 'assets/dials/ferrari-dashboard-clean.png',
      needles: [
        DialNeedleSpec(
          pivot: Offset(0.50, 0.515),
          startAngle: math.pi / 2,
          sweepAngle: math.pi * 1.50,
          length: 0.31,
          color: Color(0xFFF4F6FF),
          width: 4,
          hubRadius: 0.029,
          hubColor: Color(0xFFCACDD1),
        ),
      ],
    ),
    DialProfile(
      themeId: 'bmw-touring',
      name: 'M Touring',
      subtitle: 'Classic dual-scale dial',
      assetPath: 'assets/dials/bmw-classic-clean.png',
      imageScale: 1.12,
      imageAlignment: Alignment(0, 0.28),
      needles: [
        DialNeedleSpec(
          pivot: Offset(0.50, 0.572),
          startAngle: math.pi * 0.75,
          sweepAngle: math.pi * 1.50,
          length: 0.31,
          color: Color(0xFFFF2737),
          width: 5,
          hubRadius: 0.032,
          hubColor: Color(0xFFBFC3C7),
        ),
      ],
    ),
    DialProfile(
      themeId: 'ferrari-tach',
      name: 'Ferrari Tach',
      subtitle: 'High-RPM sweep',
      assetPath: 'assets/dials/ferrari-tach-clean.png',
      imageScale: 1.04,
      needles: [
        DialNeedleSpec(
          pivot: Offset(0.50, 0.76),
          startAngle: math.pi / 2,
          sweepAngle: math.pi * 1.50,
          length: 0.25,
          color: Color(0xFFFF2434),
          width: 5,
          hubRadius: 0.026,
          hubColor: Color(0xFF15171A),
        ),
      ],
    ),
    DialProfile(
      themeId: 'classic-redline',
      name: 'Redline Classic',
      subtitle: 'Orange analog dial',
      assetPath: 'assets/dials/classic-red-clean.png',
      needles: [
        DialNeedleSpec(
          pivot: Offset(0.50, 0.57),
          startAngle: math.pi * 0.75,
          sweepAngle: math.pi * 1.50,
          length: 0.34,
          color: Color(0xFFF5F6F7),
          width: 5,
          hubRadius: 0.038,
          hubColor: Color(0xFF111214),
        ),
      ],
    ),
    DialProfile(
      themeId: 'digital-dual',
      name: 'Digital Dual',
      subtitle: 'Twin live needles',
      assetPath: 'assets/dials/digital-dual-clean.png',
      needles: [
        DialNeedleSpec(
          pivot: Offset(0.238, 0.506),
          startAngle: math.pi * 0.75,
          sweepAngle: math.pi * 1.50,
          length: 0.14,
          color: Color(0xFFFF3346),
          width: 3.5,
          hubRadius: 0.020,
          hubColor: Color(0xFFB8BABC),
        ),
        DialNeedleSpec(
          pivot: Offset(0.748, 0.506),
          startAngle: -math.pi / 2,
          sweepAngle: math.pi * 1.84,
          length: 0.14,
          color: Color(0xFFFF3346),
          width: 3.5,
          hubRadius: 0.020,
          hubColor: Color(0xFFB8BABC),
          speedMultiplier: 0.82,
        ),
      ],
    ),
    DialProfile(
      themeId: 'neon-pulse',
      name: 'Neon Pulse',
      subtitle: 'Purple electric dial',
      assetPath: 'assets/dials/neon-clean.png',
      needles: [
        DialNeedleSpec(
          pivot: Offset(0.50, 0.50),
          startAngle: math.pi * 0.75,
          sweepAngle: math.pi * 1.50,
          length: 0.34,
          color: Color(0xFFFF3B30),
          width: 8,
          hubRadius: 0.050,
          hubColor: Color(0xFF0A0B0D),
        ),
      ],
    ),
  ];
}
