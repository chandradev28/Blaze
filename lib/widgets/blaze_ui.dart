import 'package:flutter/material.dart';

import '../models/blaze_theme.dart';

class BlazeCard extends StatelessWidget {
  const BlazeCard(
      {required this.child,
      this.padding = const EdgeInsets.all(16),
      super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.70),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 24,
              offset: const Offset(0, 12)),
        ],
      ),
      child: child,
    );
  }
}

class BlazeSectionTitle extends StatelessWidget {
  const BlazeSectionTitle({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        if (action != null) action!,
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile(
      {required this.label,
      required this.value,
      required this.unit,
      super.key});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.42),
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThemePreview extends StatelessWidget {
  const ThemePreview(
      {required this.theme, this.selected = false, this.onTap, super.key});

  final BlazeTheme theme;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 154,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? theme.primary : Colors.white.withOpacity(0.08),
              width: selected ? 2 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: theme.primary.withOpacity(0.22), blurRadius: 18)
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 92,
              width: double.infinity,
              child: CustomPaint(painter: MiniGaugePainter(theme: theme)),
            ),
            const SizedBox(height: 8),
            Text(theme.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(theme.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class MiniGaugePainter extends CustomPainter {
  const MiniGaugePainter({required this.theme});

  final BlazeTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.68);
    final radius = size.height * 0.82;
    const start = 3.72;
    const sweep = 2.84;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.10);
    canvas.drawArc(rect, start, sweep, false, track);
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = theme.primary;
    canvas.drawArc(rect, start, sweep * 0.68, false, accent);
    canvas.drawCircle(center, 5, Paint()..color = theme.primary);
    canvas.drawLine(
        center,
        center - Offset(radius * 0.55, radius * 0.04),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant MiniGaugePainter oldDelegate) =>
      oldDelegate.theme.id != theme.id;
}
