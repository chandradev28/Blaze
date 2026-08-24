import 'dart:math' as math;

import 'package:flutter/material.dart';

class GarageBackdrop extends StatelessWidget {
  const GarageBackdrop({
    required this.accent,
    required this.profileId,
    required this.enabled,
    super.key,
  });

  final Color accent;
  final String profileId;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: RepaintBoundary(
        child: CustomPaint(
          isComplex: true,
          painter: GarageBackdropPainter(
            accent: accent,
            profileId: profileId,
            enabled: enabled,
          ),
        ),
      ),
    );
  }
}

class GarageBackdropPainter extends CustomPainter {
  const GarageBackdropPainter({
    required this.accent,
    required this.profileId,
    required this.enabled,
  });

  final Color accent;
  final String profileId;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFF030304));

    if (enabled) {
      switch (profileId) {
        case 'blaze-core':
          _paintLeather(
            canvas,
            size,
            base: const Color(0xFF2A1912),
            stitch: const Color(0xFFD09A68),
            diamond: true,
          );
          break;
        case 'aventador-blue':
          _paintForgedCarbon(canvas, size, const Color(0xFF3D8FFF));
          break;
        case 'ferrari-center':
          _paintLeather(
            canvas,
            size,
            base: const Color(0xFF310708),
            stitch: const Color(0xFFE0B16A),
            diamond: true,
          );
          break;
        case 'bmw-touring':
          _paintPerforatedLeather(canvas, size, const Color(0xFF2B3035));
          break;
        case 'ferrari-tach':
          _paintAlcantara(canvas, size, const Color(0xFFFF2737));
          break;
        case 'classic-redline':
          _paintBrushedChrome(canvas, size);
          break;
        case 'digital-dual':
          _paintHexTech(canvas, size, const Color(0xFF00C8FF));
          break;
        case 'neon-pulse':
          _paintNeonVinyl(canvas, size);
          break;
        default:
          _paintLeather(
            canvas,
            size,
            base: const Color(0xFF121214),
            stitch: accent,
          );
      }
    }

    if (enabled) _paintChromeRails(canvas, size);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.48),
          radius: 0.92,
          colors: [
            Colors.white.withOpacity(enabled ? 0.055 : 0.018),
            accent.withOpacity(enabled ? 0.065 : 0.018),
            Colors.transparent,
          ],
        ).createShader(bounds),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          radius: 0.92,
          colors: [Colors.transparent, Colors.black.withOpacity(0.54)],
          stops: const [0.30, 1],
        ).createShader(bounds),
    );
  }

  void _paintLeather(
    Canvas canvas,
    Size size, {
    required Color base,
    required Color stitch,
    bool diamond = false,
  }) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, 0.10)!,
            base,
            Color.lerp(base, Colors.black, 0.48)!,
          ],
        ).createShader(bounds),
    );

    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var index = 0; index < 90; index++) {
      final y = size.height * index / 90;
      final wobble = math.sin(index * 1.91) * 5;
      grain.color = index.isEven
          ? Colors.white.withOpacity(0.018)
          : Colors.black.withOpacity(0.07);
      canvas.drawPath(
        Path()
          ..moveTo(0, y)
          ..quadraticBezierTo(
            size.width * 0.46,
            y + wobble,
            size.width,
            y - wobble * 0.4,
          ),
        grain,
      );
    }

    if (!diamond) return;
    const spacing = 92.0;
    final seamShadow = Paint()
      ..color = Colors.black.withOpacity(0.48)
      ..strokeWidth = 3;
    final seam = Paint()
      ..color = stitch.withOpacity(0.38)
      ..strokeWidth = 0.9;
    for (double offset = -size.height; offset < size.width; offset += spacing) {
      final a = Offset(offset, 0);
      final b = Offset(offset + size.height, size.height);
      final c = Offset(size.width - offset, 0);
      final d = Offset(size.width - offset - size.height, size.height);
      canvas.drawLine(a, b, seamShadow);
      canvas.drawLine(a.translate(0, -1), b.translate(0, -1), seam);
      canvas.drawLine(c, d, seamShadow);
      canvas.drawLine(c.translate(0, -1), d.translate(0, -1), seam);
    }
  }

  void _paintForgedCarbon(Canvas canvas, Size size, Color highlight) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF17191C), Color(0xFF050607), Color(0xFF101215)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );
    final random = math.Random(370);
    for (var index = 0; index < 180; index++) {
      final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = 8 + random.nextDouble() * 22;
      final path = Path();
      for (var point = 0; point < 5; point++) {
        final angle = point * math.pi * 2 / 5 + random.nextDouble() * 0.32;
        final vertex =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        point == 0
            ? path.moveTo(vertex.dx, vertex.dy)
            : path.lineTo(vertex.dx, vertex.dy);
      }
      path.close();
      final brightness = random.nextDouble();
      canvas.drawPath(
        path,
        Paint()
          ..color = brightness > 0.88
              ? highlight.withOpacity(0.045)
              : Colors.white.withOpacity(0.012 + brightness * 0.035),
      );
    }
  }

  void _paintPerforatedLeather(Canvas canvas, Size size, Color base) {
    _paintLeather(canvas, size, base: base, stitch: const Color(0xFF5D9CFF));
    final hole = Paint()..color = Colors.black.withOpacity(0.56);
    final glint = Paint()..color = Colors.white.withOpacity(0.035);
    for (double y = 12; y < size.height; y += 15) {
      final shift = ((y / 15).round()).isEven ? 0.0 : 7.5;
      for (double x = 10 + shift; x < size.width; x += 15) {
        canvas.drawCircle(Offset(x, y), 1.45, hole);
        canvas.drawCircle(Offset(x - 0.35, y - 0.4), 0.45, glint);
      }
    }
    _paintAccentSeam(canvas, size, const [
      Color(0xFF52A8FF),
      Color(0xFF172BCE),
      Color(0xFFE13C48),
    ]);
  }

  void _paintAlcantara(Canvas canvas, Size size, Color stitch) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF242326), Color(0xFF09090A), Color(0xFF171619)],
        ).createShader(bounds),
    );
    final fiber = Paint()..strokeWidth = 0.55;
    for (var index = 0; index < 520; index++) {
      final x = (index * 47) % math.max(1, size.width.floor());
      final y = (index * 83) % math.max(1, size.height.floor());
      fiber.color = index.isEven
          ? Colors.white.withOpacity(0.025)
          : Colors.black.withOpacity(0.15);
      canvas.drawLine(
          Offset(x.toDouble(), y.toDouble()), Offset(x + 3, y + 1), fiber);
    }
    _paintAccentSeam(canvas, size, [stitch, const Color(0xFF72020A)]);
  }

  void _paintBrushedChrome(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1D2022),
            Color(0xFF73787B),
            Color(0xFF202326),
            Color(0xFF575C60),
            Color(0xFF0A0B0C),
          ],
          stops: [0, 0.18, 0.44, 0.68, 1],
        ).createShader(bounds),
    );
    for (double y = 1; y < size.height; y += 3) {
      final alpha = 0.015 + ((math.sin(y * 0.37) + 1) * 0.012);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.white.withOpacity(alpha)
          ..strokeWidth = 0.55,
      );
    }
  }

  void _paintHexTech(Canvas canvas, Size size, Color glow) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF02090C));
    const radius = 20.0;
    final hex = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (double y = -radius; y < size.height + radius; y += radius * 1.5) {
      final row = (y / (radius * 1.5)).round();
      for (double x = -radius; x < size.width + radius; x += radius * 1.74) {
        final center = Offset(x + (row.isOdd ? radius * 0.87 : 0), y);
        final path = Path();
        for (var point = 0; point < 6; point++) {
          final angle = point * math.pi / 3;
          final vertex =
              center + Offset(math.cos(angle), math.sin(angle)) * radius;
          point == 0
              ? path.moveTo(vertex.dx, vertex.dy)
              : path.lineTo(vertex.dx, vertex.dy);
        }
        path.close();
        hex.color = glow.withOpacity(row % 3 == 0 ? 0.075 : 0.035);
        canvas.drawPath(path, hex);
      }
    }
  }

  void _paintNeonVinyl(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF120524), Color(0xFF020207), Color(0xFF06152A)],
        ).createShader(bounds),
    );
    final center = Offset(size.width * 0.68, size.height * 0.28);
    for (var index = 0; index < 9; index++) {
      canvas.drawCircle(
        center,
        50.0 + index * 48,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Color.lerp(
            const Color(0xFF8A2CFF),
            const Color(0xFF00D7FF),
            index / 8,
          )!
              .withOpacity(0.055),
      );
    }
  }

  void _paintAccentSeam(Canvas canvas, Size size, List<Color> colors) {
    final center = size.width * 0.78;
    for (var index = 0; index < colors.length; index++) {
      canvas.drawLine(
        Offset(center + index * 4, 0),
        Offset(center - size.height * 0.18 + index * 4, size.height),
        Paint()
          ..color = colors[index].withOpacity(0.34)
          ..strokeWidth = 1.2,
      );
    }
  }

  void _paintChromeRails(Canvas canvas, Size size) {
    const railShader = LinearGradient(
      colors: [Color(0xFF17191B), Color(0xFFD9DADB), Color(0xFF373A3D)],
    );
    final left = Rect.fromLTWH(0, 0, 3, size.height);
    final right = Rect.fromLTWH(size.width - 3, 0, 3, size.height);
    canvas.drawRect(left, Paint()..shader = railShader.createShader(left));
    canvas.drawRect(right, Paint()..shader = railShader.createShader(right));
  }

  @override
  bool shouldRepaint(covariant GarageBackdropPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.profileId != profileId ||
      oldDelegate.enabled != enabled;
}

class ChromeGaugeStage extends StatelessWidget {
  const ChromeGaugeStage({
    required this.accent,
    required this.child,
    super.key,
  });

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: ChromeGaugeFramePainter(accent: accent),
          ),
          Padding(padding: const EdgeInsets.all(2), child: child),
        ],
      ),
    );
  }
}

class ChromeGaugeFramePainter extends CustomPainter {
  const ChromeGaugeFramePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.51);
    final radius = math.min(size.width, size.height) * 0.465;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withOpacity(0.60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    final ring = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      ring,
      -math.pi * 0.82,
      math.pi * 1.22,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..shader = const SweepGradient(
          colors: [
            Color(0xFF292C2F),
            Color(0xFFF0F1F1),
            Color(0xFF55595D),
            Color(0xFFBFC2C4),
            Color(0xFF292C2F),
          ],
        ).createShader(ring),
    );
    canvas.drawArc(
      ring.deflate(5),
      -math.pi * 0.35,
      math.pi * 0.78,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.4
        ..color = accent.withOpacity(0.42),
    );
  }

  @override
  bool shouldRepaint(covariant ChromeGaugeFramePainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class ChromePanel extends StatelessWidget {
  const ChromePanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF707478),
            Color(0xFFE4E5E5),
            Color(0xFF292C2F),
            Color(0xFF888C8F),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xF20A0A0C),
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      ),
    );
  }
}

class ChromeIconButton extends StatelessWidget {
  const ChromeIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.accent = Colors.white,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: 38,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF2F3F3),
            Color(0xFF65696C),
            Color(0xFF1E2022),
            Color(0xFF9DA0A2),
          ],
        ),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.10), blurRadius: 12),
        ],
      ),
      child: Material(
        color: const Color(0xFF0B0C0E),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}

class AcceleratorPedalPainter extends CustomPainter {
  const AcceleratorPedalPainter({
    required this.accent,
    required this.active,
  });

  final Color accent;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0F1F1),
            Color(0xFF666A6D),
            Color(0xFF1D1F21),
            Color(0xFFAEB1B3),
          ],
          stops: [0, 0.18, 0.76, 1],
        ).createShader(Offset.zero & size),
    );
    final innerRect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    final inner = RRect.fromRectAndRadius(innerRect, const Radius.circular(19));
    canvas.drawRRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF202226),
            const Color(0xFF08090A),
            active ? accent.withOpacity(0.24) : const Color(0xFF141517),
          ],
        ).createShader(innerRect),
    );

    for (var index = 0; index < 5; index++) {
      final x = size.width * (0.17 + index * 0.055);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height * 0.26, 4, size.height * 0.48),
          const Radius.circular(3),
        ),
        Paint()
          ..color = index.isEven
              ? Colors.white.withOpacity(0.13)
              : Colors.black.withOpacity(0.55),
      );
    }

    final glowX = size.width * 0.68;
    canvas.drawCircle(
      Offset(glowX, size.height * 0.5),
      3.5,
      Paint()
        ..color = active ? accent : const Color(0xFF4B4E50)
        ..maskFilter =
            active ? const MaskFilter.blur(BlurStyle.normal, 5) : null,
    );
  }

  @override
  bool shouldRepaint(covariant AcceleratorPedalPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.active != active;
}
