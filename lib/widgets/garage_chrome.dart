import 'package:flutter/material.dart';

class GarageBackdrop extends StatelessWidget {
  const GarageBackdrop({required this.accent, super.key});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        isComplex: true,
        painter: GarageBackdropPainter(accent: accent),
      ),
    );
  }
}

class GarageBackdropPainter extends CustomPainter {
  const GarageBackdropPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFF030304));

    const tile = 18.0;
    final carbon = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double y = -tile; y < size.height + tile; y += tile) {
      for (double x = -tile; x < size.width + tile; x += tile) {
        final alternate = ((x / tile).round() + (y / tile).round()).isEven;
        carbon.color = Colors.white.withOpacity(alternate ? 0.018 : 0.009);
        canvas.drawLine(Offset(x, y + tile), Offset(x + tile, y), carbon);
        carbon.color = Colors.black.withOpacity(0.30);
        canvas.drawLine(
          Offset(x + tile * 0.45, y + tile),
          Offset(x + tile, y + tile * 0.45),
          carbon,
        );
      }
    }

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.48),
          radius: 0.92,
          colors: [
            Colors.white.withOpacity(0.035),
            accent.withOpacity(0.025),
            Colors.transparent,
          ],
        ).createShader(bounds),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          radius: 0.92,
          colors: [Colors.transparent, Colors.black.withOpacity(0.72)],
          stops: const [0.34, 1],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant GarageBackdropPainter oldDelegate) =>
      oldDelegate.accent != accent;
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.42),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.08),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(7), child: child),
          IgnorePointer(
            child: CustomPaint(
              painter: ChromeGaugeFramePainter(accent: accent),
            ),
          ),
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
    final frame = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(2),
      const Radius.circular(34),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF55595D),
            Color(0xFFF0F1F1),
            Color(0xFF5E6266),
            Color(0xFFBEC1C3),
            Color(0xFF33363A),
          ],
          stops: [0, 0.20, 0.46, 0.70, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(5),
        const Radius.circular(31),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withOpacity(0.22),
    );

    final bolts = [
      const Offset(18, 18),
      Offset(size.width - 18, 18),
      Offset(18, size.height - 18),
      Offset(size.width - 18, size.height - 18),
    ];
    for (final bolt in bolts) {
      _drawBolt(canvas, bolt, 5.2);
    }
  }

  void _drawBolt(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFF6F7F7), Color(0xFF777B7E), Color(0xFF1B1D1F)],
          stops: [0, 0.52, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawLine(
      center.translate(-radius * 0.54, 0),
      center.translate(radius * 0.54, 0),
      Paint()
        ..color = Colors.black.withOpacity(0.66)
        ..strokeWidth = 1.2,
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
