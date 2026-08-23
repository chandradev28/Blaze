import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/blaze_theme.dart';
import '../services/speed_test_service.dart';

class BlazeGauge extends StatelessWidget {
  const BlazeGauge({
    required this.theme,
    required this.value,
    required this.phase,
    this.height,
    super.key,
  });

  final BlazeTheme theme;
  final double value;
  final TestPhase phase;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: GaugePainter(theme: theme, value: value, phase: phase),
        ),
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  GaugePainter({required this.theme, required this.value, required this.phase});

  final BlazeTheme theme;
  final double value;
  final TestPhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progress = (value / theme.maxSpeed).clamp(0.0, 1.0);
    const startAngle = math.pi * 0.78;
    const sweepAngle = math.pi * 1.44;

    final fill = Paint()..color = theme.surface.withOpacity(0.96);
    canvas.drawCircle(center, radius * 1.12, fill);

    if (theme.showGlow) {
      final glow = Paint()
        ..color = theme.primary.withOpacity(0.13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(center, radius * 0.88, glow);
    }

    if (theme.showGrid) _drawGrid(canvas, center, radius);
    _drawOuterRings(canvas, center, radius);
    _drawTrack(canvas, rect, startAngle, sweepAngle);
    _drawProgress(canvas, rect, startAngle, sweepAngle, progress);
    _drawTicks(canvas, center, radius, startAngle, sweepAngle);
    _drawNeedle(canvas, center, radius, startAngle, sweepAngle, progress);
    _drawCenter(canvas, center, radius, progress);
    _drawTelemetry(canvas, center, radius, progress);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = theme.primary.withOpacity(0.055)
      ..strokeWidth = 1;
    for (var index = 0; index < 12; index++) {
      final angle = index * math.pi / 6;
      final start =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.45;
      final end =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 1.02;
      canvas.drawLine(start, end, paint);
    }
    canvas.drawCircle(
        center, radius * 0.7, paint..style = PaintingStyle.stroke);
    paint.style = PaintingStyle.fill;
  }

  void _drawOuterRings(Canvas canvas, Offset center, double radius) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(center, radius * 1.10, ring);
    canvas.drawCircle(
        center, radius * 0.95, ring..color = theme.primary.withOpacity(0.14));
    if (theme.gaugeStyle == GaugeStyle.neon) {
      canvas.drawCircle(center, radius * 1.16,
          ring..color = theme.secondary.withOpacity(0.14));
    }
  }

  void _drawTrack(
      Canvas canvas, Rect rect, double startAngle, double sweepAngle) {
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawArc(rect, startAngle, sweepAngle, false, track);
  }

  void _drawProgress(
    Canvas canvas,
    Rect rect,
    double startAngle,
    double sweepAngle,
    double progress,
  ) {
    if (progress <= 0) return;
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [theme.primary, theme.secondary, theme.primary],
    );
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);
    canvas.drawArc(
        rect, startAngle, sweepAngle * progress, false, progressPaint);
  }

  void _drawTicks(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    for (var index = 0; index <= 40; index++) {
      final fraction = index / 40;
      final angle = startAngle + sweepAngle * fraction;
      final major = index % 5 == 0;
      final inner = radius * (major ? 0.78 : 0.82);
      final outer = radius * (major ? 0.91 : 0.88);
      tickPaint
        ..strokeWidth = major ? 2.5 : 1
        ..color = major
            ? Colors.white.withOpacity(0.78)
            : Colors.white.withOpacity(0.23);
      final start = center + Offset(math.cos(angle), math.sin(angle)) * inner;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * outer;
      canvas.drawLine(start, end, tickPaint);
      if (major && index < 40) {
        _drawText(
          canvas,
          '${((theme.maxSpeed / 8) * (index / 5)).round()}',
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.68,
          10,
          Colors.white.withOpacity(0.58),
          FontWeight.w600,
        );
      }
    }
  }

  void _drawNeedle(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    double progress,
  ) {
    final angle = startAngle + sweepAngle * progress;
    final tip =
        center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.72;
    final tail =
        center - Offset(math.cos(angle), math.sin(angle)) * radius * 0.18;
    final needle = Paint()
      ..color = theme.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    if (theme.showGlow) {
      canvas.drawLine(
        tail,
        tip,
        needle
          ..color = theme.primary.withOpacity(0.28)
          ..strokeWidth = 12,
      );
    }
    canvas.drawLine(
        tail,
        tip,
        needle
          ..color = theme.primary
          ..strokeWidth = 3.5);
    canvas.drawCircle(center, radius * 0.09, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius * 0.055, Paint()..color = theme.primary);
  }

  void _drawCenter(
      Canvas canvas, Offset center, double radius, double progress) {
    final displayValue =
        (value / (theme.maxSpeed / 1000)).clamp(0.0, theme.maxSpeed.toDouble());
    final label = phase == TestPhase.idle
        ? 'READY'
        : phase == TestPhase.finished
            ? 'COMPLETE'
            : _phaseLabel;
    _drawText(
      canvas,
      displayValue >= 100
          ? displayValue.round().toString()
          : displayValue.toStringAsFixed(1),
      center + Offset(0, radius * 0.03),
      radius * 0.24,
      Colors.white,
      FontWeight.w800,
    );
    _drawText(canvas, 'Mbps', center + Offset(0, radius * 0.25), 12,
        theme.secondary, FontWeight.w700);
    _drawText(canvas, label, center + Offset(0, radius * 0.41), 10,
        Colors.white.withOpacity(0.42), FontWeight.w700);
  }

  void _drawTelemetry(
      Canvas canvas, Offset center, double radius, double progress) {
    if (theme.gaugeStyle != GaugeStyle.telemetry) return;
    final line = Paint()
      ..color = theme.primary.withOpacity(0.55)
      ..strokeWidth = 2;
    final top = center - Offset(radius * 0.70, radius * 0.66);
    canvas.drawLine(top, top + Offset(radius * 0.40, 0), line);
    canvas.drawLine(top + Offset(radius * 0.48, 0),
        top + Offset(radius * 0.70, 0), line..color = theme.secondary);
    _drawText(canvas, 'BLAZE / ${theme.gaugeStyle.label.toUpperCase()}',
        center - Offset(0, radius * 0.61), 9, theme.primary, FontWeight.w800);
    _drawText(
        canvas,
        'SIGNAL ${((progress * 100).round()).toString().padLeft(2, '0')}',
        center + Offset(0, radius * 0.63),
        9,
        Colors.white.withOpacity(0.42),
        FontWeight.w700);
  }

  String get _phaseLabel {
    switch (phase) {
      case TestPhase.connecting:
        return 'CONNECTING';
      case TestPhase.ping:
        return 'PING';
      case TestPhase.download:
        return 'DOWNLOAD';
      case TestPhase.upload:
        return 'UPLOAD';
      case TestPhase.finished:
        return 'COMPLETE';
      case TestPhase.error:
        return 'RETRY';
      case TestPhase.idle:
        return 'READY';
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            letterSpacing: 0.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.theme.id != theme.id ||
        oldDelegate.value != value ||
        oldDelegate.phase != phase;
  }
}
