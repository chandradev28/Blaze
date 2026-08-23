import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/blaze_theme.dart';
import '../services/speed_test_service.dart';

class BlazeGauge extends StatefulWidget {
  const BlazeGauge({
    required this.theme,
    required this.value,
    required this.phase,
    this.download,
    this.upload,
    this.ping,
    this.jitter,
    this.height,
    super.key,
  });

  final BlazeTheme theme;
  final double value;
  final TestPhase phase;
  final double? download;
  final double? upload;
  final double? ping;
  final double? jitter;
  final double? height;

  @override
  State<BlazeGauge> createState() => _BlazeGaugeState();
}

class _BlazeGaugeState extends State<BlazeGauge> with TickerProviderStateMixin {
  late final AnimationController _valueController;
  late final AnimationController _effectController;
  late Animation<double> _valueAnimation;

  @override
  void initState() {
    super.initState();
    _valueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _effectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _valueAnimation = AlwaysStoppedAnimation(widget.value);
  }

  @override
  void didUpdateWidget(covariant BlazeGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final begin = _valueAnimation.value;
      _valueAnimation = Tween<double>(begin: begin, end: widget.value).animate(
        CurvedAnimation(parent: _valueController, curve: Curves.easeOutCubic),
      );
      _valueController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _effectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svgAsset = switch (widget.theme.gaugeStyle) {
      GaugeStyle.f1 => 'assets/svg/f1_peak_details.svg',
      GaugeStyle.motoGp => 'assets/svg/motogp_peak_details.svg',
      _ => null,
    };
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              isComplex: true,
              willChange: true,
              painter: GaugePainter(
                theme: widget.theme,
                valueAnimation: _valueAnimation,
                effectAnimation: _effectController,
                phase: widget.phase,
                download: widget.download,
                upload: widget.upload,
                ping: widget.ping,
                jitter: widget.jitter,
              ),
            ),
            if (svgAsset != null)
              IgnorePointer(
                child: Opacity(
                  opacity: 0.60,
                  child: SvgPicture.asset(svgAsset, fit: BoxFit.contain),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  GaugePainter({
    required this.theme,
    required this.valueAnimation,
    required this.effectAnimation,
    required this.phase,
    this.download,
    this.upload,
    this.ping,
    this.jitter,
  }) : super(repaint: Listenable.merge([valueAnimation, effectAnimation]));

  final BlazeTheme theme;
  final Animation<double> valueAnimation;
  final Animation<double> effectAnimation;
  final TestPhase phase;
  final double? download;
  final double? upload;
  final double? ping;
  final double? jitter;

  double get value => valueAnimation.value;
  double get effect => effectAnimation.value;
  double get progress => (value / theme.maxSpeed).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    switch (theme.gaugeStyle) {
      case GaugeStyle.f1:
        _paintF1(canvas, size);
      case GaugeStyle.motoGp:
        _paintMotoGp(canvas, size);
      case GaugeStyle.classic:
      case GaugeStyle.electric:
      case GaugeStyle.neon:
        _paintRadial(canvas, size);
    }
  }

  void _paintF1(Canvas canvas, Size size) {
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.035, size.height * 0.13, size.width * 0.93,
          size.height * 0.74),
      const Radius.circular(28),
    );
    final center = Offset(size.width / 2, size.height * 0.52);
    final panelRect = panel.outerRect;
    final background = Paint()..color = theme.surface;
    canvas.drawRRect(panel, background);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = theme.primary.withOpacity(0.48);
    canvas.drawRRect(panel, border);

    final wing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = theme.primary.withOpacity(0.26);
    canvas.drawLine(Offset(panelRect.left + 18, panelRect.bottom - 22),
        Offset(center.dx - 54, panelRect.top + 28), wing);
    canvas.drawLine(Offset(panelRect.right - 18, panelRect.bottom - 22),
        Offset(center.dx + 54, panelRect.top + 28), wing);

    _drawText(
        canvas,
        'BLAZE  //  GRAND PRIX TELEMETRY',
        Offset(center.dx, panelRect.top + 18),
        9,
        theme.primary,
        FontWeight.w900,
        letterSpacing: 1.5);
    _drawShiftLights(canvas, center, panelRect.top + 42);
    _drawF1Sweep(canvas, center, panelRect);

    final screen = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: center + const Offset(0, 18),
          width: size.width * 0.54,
          height: size.height * 0.29),
      const Radius.circular(12),
    );
    canvas.drawRRect(screen, Paint()..color = Colors.black.withOpacity(0.62));
    canvas.drawRRect(screen, border..color = theme.primary.withOpacity(0.22));
    _drawText(canvas, _displayValue, screen.center.translate(0, -8), 38,
        Colors.white, FontWeight.w900,
        letterSpacing: -1.2);
    _drawText(canvas, 'Mbps', screen.center.translate(0, 27), 10,
        theme.secondary, FontWeight.w800,
        letterSpacing: 1.6);

    _metricBox(canvas, Offset(panelRect.left + 25, center.dy - 35), 'DL',
        _metricValue(download), theme.primary);
    _metricBox(canvas, Offset(panelRect.right - 25, center.dy - 35), 'UL',
        _metricValue(upload), theme.secondary,
        alignRight: true);
    _metricBox(canvas, Offset(panelRect.left + 25, center.dy + 74), 'PING',
        ping == null ? '--' : '${ping!.toStringAsFixed(0)}ms', Colors.white70);
    _metricBox(
        canvas,
        Offset(panelRect.right - 25, center.dy + 74),
        'JITTER',
        jitter == null ? '--' : '${jitter!.toStringAsFixed(1)}ms',
        Colors.white70,
        alignRight: true);

    _bar(
        canvas,
        Rect.fromLTWH(
            panelRect.left + 26, panelRect.bottom - 42, size.width * 0.31, 5),
        _metricProgress(download),
        theme.primary);
    _bar(
        canvas,
        Rect.fromLTWH(panelRect.right - size.width * 0.31 - 26,
            panelRect.bottom - 42, size.width * 0.31, 5),
        _metricProgress(upload),
        theme.secondary);
    _drawText(canvas, _phaseLabel, Offset(center.dx, panelRect.bottom - 18), 9,
        Colors.white.withOpacity(0.45), FontWeight.w800,
        letterSpacing: 1.4);
  }

  void _drawShiftLights(Canvas canvas, Offset center, double y) {
    const count = 12;
    final active = (progress * count).round();
    const width = 15.0;
    const gap = 5.0;
    final start = center.dx - (count * width + (count - 1) * gap) / 2;
    for (var index = 0; index < count; index++) {
      final isActive = index < active;
      final color = index < 5
          ? const Color(0xFF6DFF68)
          : index < 9
              ? const Color(0xFFFFC857)
              : const Color(0xFFFF4D62);
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(start + index * (width + gap), y, width, 6),
          const Radius.circular(3));
      canvas.drawRRect(
          rect,
          Paint()
            ..color = isActive
                ? color.withOpacity(theme.showPulse
                    ? 0.80 +
                        math.sin(effect * math.pi * 2 + index) *
                            0.16 *
                            theme.motion
                    : 1)
                : color.withOpacity(0.11));
    }
  }

  void _drawF1Sweep(Canvas canvas, Offset center, Rect panel) {
    if (!theme.showSweep) return;
    final x = panel.left + 24 + (panel.width - 48) * effect;
    final sweep = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          theme.primary.withOpacity(0.38),
          Colors.transparent
        ],
      ).createShader(Rect.fromLTWH(x - 26, panel.top, 52, panel.height))
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(x, panel.top + 36), Offset(x, panel.bottom - 46), sweep);
  }

  void _paintMotoGp(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final radius = math.min(size.width, size.height) * 0.38;
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.04, size.height * 0.09, size.width * 0.92,
          size.height * 0.80),
      const Radius.circular(32),
    );
    canvas.drawRRect(panel, Paint()..color = theme.surface);
    canvas.drawRRect(
        panel,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = theme.primary.withOpacity(0.38));

    _drawText(canvas, 'MOTOGP  //  BLAZE CONTROL',
        Offset(center.dx, panel.top + 22), 9, theme.primary, FontWeight.w900,
        letterSpacing: 1.8);
    _drawText(canvas, 'TC 04', Offset(panel.left + 48, panel.top + 52), 11,
        Colors.white.withOpacity(0.54), FontWeight.w800,
        letterSpacing: 1.2);
    _drawText(canvas, 'EB 02', Offset(panel.right - 48, panel.top + 52), 11,
        Colors.white.withOpacity(0.54), FontWeight.w800,
        letterSpacing: 1.2);

    final arcRect =
        Rect.fromCircle(center: center.translate(0, 20), radius: radius * 1.03);
    final arcTrack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawArc(arcRect, math.pi * 0.78, math.pi * 1.44, false, arcTrack);
    final arcProgress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = theme.primary;
    canvas.drawArc(
        arcRect, math.pi * 0.78, math.pi * 1.44 * progress, false, arcProgress);
    _drawMotoSweep(canvas, arcRect);

    for (var index = 0; index < 18; index++) {
      final angle = math.pi * 0.78 + math.pi * 1.44 * index / 17;
      final active = index / 17 <= progress;
      final point = center.translate(0, 20) +
          Offset(math.cos(angle), math.sin(angle)) * radius * 1.19;
      canvas.drawCircle(
          point,
          3.2,
          Paint()
            ..color = active
                ? (index > 12 ? const Color(0xFFFF5166) : theme.secondary)
                : Colors.white.withOpacity(0.12));
    }

    _drawText(canvas, _displayValue, center.translate(0, 4), 42, Colors.white,
        FontWeight.w900,
        letterSpacing: -1.4);
    _drawText(canvas, 'Mbps', center.translate(0, 38), 10, theme.secondary,
        FontWeight.w800,
        letterSpacing: 1.7);
    _drawText(canvas, _phaseLabel, center.translate(0, 59), 9,
        Colors.white.withOpacity(0.43), FontWeight.w800,
        letterSpacing: 1.4);

    _drawVerticalMetric(canvas, Offset(panel.left + 42, center.dy + 72),
        'DOWNLOAD', _metricProgress(download), theme.primary);
    _drawVerticalMetric(canvas, Offset(panel.right - 42, center.dy + 72),
        'UPLOAD', _metricProgress(upload), theme.secondary,
        right: true);
    _drawText(canvas, 'GEAR', Offset(center.dx - 62, panel.bottom - 29), 8,
        Colors.white.withOpacity(0.42), FontWeight.w800,
        letterSpacing: 1.2);
    _drawText(
        canvas,
        progress > 0.94
            ? '6'
            : progress > 0.76
                ? '5'
                : progress > 0.5
                    ? '4'
                    : '3',
        Offset(center.dx - 62, panel.bottom - 12),
        22,
        theme.primary,
        FontWeight.w900);
    _drawText(canvas, 'LEAN', Offset(center.dx + 62, panel.bottom - 29), 8,
        Colors.white.withOpacity(0.42), FontWeight.w800,
        letterSpacing: 1.2);
    _drawText(
        canvas,
        '${((progress - 0.5) * 52).round().abs()}°',
        Offset(center.dx + 62, panel.bottom - 12),
        18,
        theme.secondary,
        FontWeight.w900);
  }

  void _drawMotoSweep(Canvas canvas, Rect arcRect) {
    if (!theme.showSweep) return;
    final sweepAngle = math.pi * 0.78 + math.pi * 1.44 * effect;
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = theme.secondary.withOpacity(0.46 + theme.motion * 0.30);
    canvas.drawArc(arcRect, sweepAngle, 0.12, false, sweep);
  }

  void _drawVerticalMetric(
      Canvas canvas, Offset origin, String label, double amount, Color color,
      {bool right = false}) {
    final x = origin.dx;
    final top = origin.dy;
    _drawText(canvas, label, Offset(x, top), 7, Colors.white.withOpacity(0.42),
        FontWeight.w800,
        letterSpacing: 1.1);
    final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 28, top + 12, 56, 5), const Radius.circular(3));
    canvas.drawRRect(track, Paint()..color = Colors.white.withOpacity(0.09));
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 28, top + 12, 56 * amount, 5),
            const Radius.circular(3)),
        Paint()..color = color);
    _drawText(canvas, _metricValue(right ? upload : download),
        Offset(x, top + 32), 9, color, FontWeight.w800);
  }

  void _paintRadial(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = math.pi * 0.78;
    const sweepAngle = math.pi * 1.44;
    canvas.drawCircle(center, radius * 1.12,
        Paint()..color = theme.surface.withOpacity(0.96));
    if (theme.showPulse) {
      final pulseRadius = radius *
          (1.03 + math.sin(effect * math.pi * 2) * 0.02 * theme.motion);
      canvas.drawCircle(
          center,
          pulseRadius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = theme.primary.withOpacity(0.12));
    }
    if (theme.showGlow) {
      canvas.drawCircle(
          center,
          radius * 0.88,
          Paint()
            ..color = theme.primary.withOpacity(0.13)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28));
    }
    if (theme.showGrid) _drawGrid(canvas, center, radius);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(center, radius * 1.10, ring);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawArc(rect, startAngle, sweepAngle, false, track);
    if (progress > 0) {
      final active = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
                startAngle: startAngle,
                endAngle: startAngle + sweepAngle,
                colors: [theme.primary, theme.secondary, theme.primary])
            .createShader(rect);
      canvas.drawArc(rect, startAngle, sweepAngle * progress, false, active);
    }
    if (theme.showSweep) {
      final sweep = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = theme.secondary.withOpacity(0.46 + theme.motion * 0.30);
      canvas.drawArc(
          rect, startAngle + sweepAngle * effect, 0.11, false, sweep);
    }
    _drawTicks(canvas, center, radius, startAngle, sweepAngle);
    final angle = startAngle + sweepAngle * progress;
    final tip =
        center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.72;
    final tail =
        center - Offset(math.cos(angle), math.sin(angle)) * radius * 0.18;
    canvas.drawLine(
        tail,
        tip,
        Paint()
          ..color = theme.primary
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(center, radius * 0.09, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius * 0.055, Paint()..color = theme.primary);
    _drawText(canvas, _displayValue, center.translate(0, radius * 0.03),
        radius * 0.24, Colors.white, FontWeight.w800);
    _drawText(canvas, 'Mbps', center.translate(0, radius * 0.25), 12,
        theme.secondary, FontWeight.w700);
    _drawText(canvas, _phaseLabel, center.translate(0, radius * 0.41), 10,
        Colors.white.withOpacity(0.42), FontWeight.w700);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = theme.primary.withOpacity(0.055)
      ..strokeWidth = 1;
    for (var index = 0; index < 12; index++) {
      final angle = index * math.pi / 6;
      canvas.drawLine(
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.45,
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 1.02,
          paint);
    }
    canvas.drawCircle(
        center, radius * 0.7, paint..style = PaintingStyle.stroke);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius,
      double startAngle, double sweepAngle) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var index = 0; index <= 40; index++) {
      final angle = startAngle + sweepAngle * index / 40;
      final major = index % 5 == 0;
      paint
        ..strokeWidth = major ? 2.5 : 1
        ..color = major
            ? Colors.white.withOpacity(0.78)
            : Colors.white.withOpacity(0.23);
      canvas.drawLine(
          center +
              Offset(math.cos(angle), math.sin(angle)) *
                  radius *
                  (major ? 0.78 : 0.82),
          center +
              Offset(math.cos(angle), math.sin(angle)) *
                  radius *
                  (major ? 0.91 : 0.88),
          paint);
      if (major && index < 40) {
        _drawText(
            canvas,
            '${((theme.maxSpeed / 8) * (index / 5)).round()}',
            center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.68,
            10,
            Colors.white.withOpacity(0.58),
            FontWeight.w600);
      }
    }
  }

  void _metricBox(
      Canvas canvas, Offset origin, String label, String value, Color color,
      {bool alignRight = false}) {
    final x = alignRight ? origin.dx - 28 : origin.dx + 28;
    _drawText(canvas, label, Offset(x, origin.dy), 8,
        Colors.white.withOpacity(0.42), FontWeight.w800,
        letterSpacing: 1.1);
    _drawText(
        canvas, value, Offset(x, origin.dy + 16), 11, color, FontWeight.w900);
  }

  void _bar(Canvas canvas, Rect rect, double amount, Color color) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = Colors.white.withOpacity(0.08));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                rect.left, rect.top, rect.width * amount, rect.height),
            const Radius.circular(3)),
        Paint()..color = color);
  }

  double _metricProgress(double? metric) =>
      metric == null ? 0 : (metric / theme.maxSpeed).clamp(0.0, 1.0);

  String _metricValue(double? metric) => metric == null
      ? '--'
      : '${metric.toStringAsFixed(metric >= 100 ? 0 : 1)} Mbps';

  String get _displayValue {
    if (value >= 100) return value.round().toString();
    return value.toStringAsFixed(1);
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
    FontWeight weight, {
    double letterSpacing = 0.5,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: weight,
              letterSpacing: letterSpacing,
              fontStyle: fontStyle)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.theme.id != theme.id ||
        oldDelegate.value != value ||
        oldDelegate.phase != phase ||
        oldDelegate.download != download ||
        oldDelegate.upload != upload ||
        oldDelegate.ping != ping ||
        oldDelegate.jitter != jitter;
  }
}

class MiniGaugePainter extends CustomPainter {
  const MiniGaugePainter({required this.theme});

  final BlazeTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (theme.gaugeStyle == GaugeStyle.f1) {
      _paintF1Mini(canvas, size);
    } else if (theme.gaugeStyle == GaugeStyle.motoGp) {
      _paintMotoMini(canvas, size);
    } else {
      final center = Offset(size.width / 2, size.height * 0.72);
      final radius = size.height * 0.82;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.10);
      canvas.drawArc(rect, 3.72, 2.84, false, paint);
      canvas.drawArc(rect, 3.72, 1.94, false, paint..color = theme.primary);
      canvas.drawCircle(center, 5, Paint()..color = theme.primary);
      canvas.drawLine(
          center,
          center - Offset(radius * 0.55, radius * 0.04),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2);
    }
  }

  void _paintF1Mini(Canvas canvas, Size size) {
    final panel = RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 10, size.width - 8, size.height - 18),
        const Radius.circular(10));
    canvas.drawRRect(panel, Paint()..color = theme.surface);
    final active = Paint()..color = theme.primary;
    for (var index = 0; index < 8; index++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(20 + index * 14, 22, 9, 4),
              const Radius.circular(2)),
          active
            ..color =
                index < 5 ? theme.primary : theme.secondary.withOpacity(0.30));
    }
    canvas.drawRect(Rect.fromLTWH(size.width * 0.30, 40, size.width * 0.40, 28),
        Paint()..color = Colors.black.withOpacity(0.70));
    canvas.drawLine(
        Offset(16, size.height - 20),
        Offset(size.width - 16, size.height - 20),
        Paint()
          ..color = theme.primary
          ..strokeWidth = 3);
  }

  void _paintMotoMini(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.67);
    final radius = size.height * 0.55;
    final arc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
        arc,
        math.pi * 0.78,
        math.pi * 1.44,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = theme.primary);
    for (var index = 0; index < 10; index++) {
      final angle = math.pi * 0.78 + math.pi * 1.44 * index / 9;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + 9);
      canvas.drawCircle(point, 2.4,
          Paint()..color = index > 6 ? theme.secondary : theme.primary);
    }
    canvas.drawRect(Rect.fromLTWH(size.width * 0.30, 42, size.width * 0.40, 24),
        Paint()..color = Colors.black.withOpacity(0.74));
  }

  @override
  bool shouldRepaint(covariant MiniGaugePainter oldDelegate) =>
      oldDelegate.theme.id != theme.id;
}
