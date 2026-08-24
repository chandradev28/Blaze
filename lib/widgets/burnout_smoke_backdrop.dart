import 'dart:math' as math;

import 'package:flutter/material.dart';

class BurnoutSmokeBackdrop extends StatefulWidget {
  const BurnoutSmokeBackdrop({
    required this.active,
    required this.accent,
    super.key,
  });

  final bool active;
  final Color accent;

  @override
  State<BurnoutSmokeBackdrop> createState() => _BurnoutSmokeBackdropState();
}

class _BurnoutSmokeBackdropState extends State<BurnoutSmokeBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant BurnoutSmokeBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat();
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.active ? 1 : 0,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              isComplex: true,
              willChange: widget.active,
              painter: BurnoutSmokePainter(
                progress: _controller.value,
                accent: widget.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BurnoutSmokePainter extends CustomPainter {
  const BurnoutSmokePainter({
    required this.progress,
    required this.accent,
  });

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    _drawTireMarks(canvas, size);
    _drawGroundHaze(canvas, size);

    for (var index = 0; index < 34; index++) {
      final phase = (progress + index * 0.067) % 1;
      final life = math.sin(math.pi * phase).clamp(0.0, 1.0);
      final fromLeft = index.isEven;
      final origin = size.width * (fromLeft ? 0.20 : 0.80);
      final curl = math.sin(
        progress * math.pi * 2 + index * 1.73,
      );
      final drift = curl * (18 + phase * 68);
      final x = origin + drift + (index % 4 - 1.5) * 13;
      final y = size.height * (0.97 - phase * 0.74);
      final radius = 18 + phase * 82 + (index % 5) * 3;
      final smokeColor = Color.lerp(
        const Color(0xFFD8D9DA),
        index % 3 == 0 ? accent : const Color(0xFF74777A),
        index % 3 == 0 ? 0.08 : 0.02,
      )!;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = smokeColor.withOpacity(0.025 + life * 0.105)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            12 + phase * 24,
          ),
      );
    }
  }

  void _drawTireMarks(Canvas canvas, Size size) {
    for (final lane in [0.25, 0.75]) {
      final path = Path()
        ..moveTo(size.width * lane, size.height)
        ..cubicTo(
          size.width * (lane - 0.045),
          size.height * 0.88,
          size.width * (lane + 0.055),
          size.height * 0.76,
          size.width * (lane - 0.018),
          size.height * 0.64,
        );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 13
          ..color = Colors.black.withOpacity(0.26),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.2
          ..color = Colors.white.withOpacity(0.045),
      );
    }
  }

  void _drawGroundHaze(Canvas canvas, Size size) {
    final hazeBounds = Rect.fromLTWH(
      0,
      size.height * 0.63,
      size.width,
      size.height * 0.37,
    );
    canvas.drawRect(
      hazeBounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFBFC1C3).withOpacity(0.10),
            const Color(0xFF777A7D).withOpacity(0.035),
            Colors.transparent,
          ],
        ).createShader(hazeBounds),
    );
  }

  @override
  bool shouldRepaint(covariant BurnoutSmokePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}
