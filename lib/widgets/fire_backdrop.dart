import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FireBackdrop extends StatefulWidget {
  const FireBackdrop({
    required this.active,
    required this.accent,
    super.key,
  });

  final bool active;
  final Color accent;

  @override
  State<FireBackdrop> createState() => _FireBackdropState();
}

class _FireBackdropState extends State<FireBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant FireBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _controller.repeat();
      HapticFeedback.heavyImpact();
    } else {
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
        duration: const Duration(milliseconds: 680),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            isComplex: true,
            willChange: widget.active,
            painter: FireBackdropPainter(
              progress: _controller.value,
              accent: widget.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class FireBackdropPainter extends CustomPainter {
  const FireBackdropPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050000),
            Color(0xFF160000),
            Color(0xFF4D0700),
            Color(0xFF120000),
          ],
          stops: [0, 0.34, 0.76, 1],
        ).createShader(bounds),
    );

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 1.12),
          radius: 1.05,
          colors: [
            const Color(0xFFFFB000).withOpacity(0.54),
            const Color(0xFFFF3100).withOpacity(0.30),
            Colors.transparent,
          ],
          stops: const [0, 0.38, 1],
        ).createShader(bounds),
    );

    for (var index = 0; index < 15; index++) {
      _drawFlame(canvas, size, index);
    }
    for (var index = 0; index < 42; index++) {
      _drawEmber(canvas, size, index);
    }

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.62)],
          stops: const [0.35, 1],
        ).createShader(bounds),
    );
  }

  void _drawFlame(Canvas canvas, Size size, int index) {
    final seed = _seed(index);
    final phase = (progress + seed) % 1;
    final baseX = size.width * (index + 0.38) / 15;
    final sway = math.sin((progress * 2 + seed) * math.pi * 2) * 18;
    final width = 22 + seed * 42;
    final height = size.height * (0.18 + seed * 0.28) * (0.70 + phase * 0.30);
    final bottom = size.height * 1.04;
    final tip = Offset(baseX + sway, bottom - height);
    final path = Path()
      ..moveTo(baseX - width, bottom)
      ..quadraticBezierTo(
        baseX - width * 0.58 + sway * 0.25,
        bottom - height * 0.46,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        baseX + width * 0.72 + sway * 0.18,
        bottom - height * 0.38,
        baseX + width,
        bottom,
      )
      ..close();
    final flameBounds = Rect.fromLTRB(
      baseX - width,
      tip.dy,
      baseX + width,
      bottom,
    );
    canvas.drawPath(
      path,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFFFD54A).withOpacity(0.45),
            accent.withOpacity(0.36),
            const Color(0xFFFF2400).withOpacity(0.12),
            Colors.transparent,
          ],
        ).createShader(flameBounds)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  void _drawEmber(Canvas canvas, Size size, int index) {
    final seed = _seed(index + 41);
    final travel = (progress * (0.45 + seed * 0.8) + seed) % 1;
    final x = size.width * _seed(index + 103) +
        math.sin((travel + seed) * math.pi * 2) * 25;
    final y = size.height * (1.04 - travel * 0.90);
    final radius = 0.8 + _seed(index + 211) * 2.2;
    final opacity = math.sin(travel * math.pi).clamp(0.0, 1.0) * 0.72;
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..color = Color.lerp(const Color(0xFFFF3B00), Colors.white, seed)!
            .withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  double _seed(int value) {
    final mixed = math.sin(value * 91.73 + 17.19) * 43758.5453;
    return mixed - mixed.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant FireBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}
