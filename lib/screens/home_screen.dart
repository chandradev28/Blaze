import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/blaze_controller.dart';
import '../models/speed_result.dart';
import '../services/speed_test_service.dart';
import '../widgets/blaze_gauge.dart';
import '../widgets/blaze_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});

  final BlazeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = controller.activeTheme;
        final result = controller.latestResult;
        final value = _gaugeValue(theme.maxSpeed, controller);
        return Container(
          color: Colors.black,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(theme: theme),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _StatusPill(
                          phase: controller.phase,
                          isTesting: controller.isTesting),
                      const Spacer(),
                      Text(theme.name,
                          style: TextStyle(
                              color: theme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  BlazeGauge(
                      theme: theme,
                      value: value,
                      phase: controller.phase,
                      download: result?.download ??
                          (controller.phase == TestPhase.download
                              ? value
                              : null),
                      upload: result?.upload ??
                          (controller.phase == TestPhase.upload ? value : null),
                      ping: result?.ping,
                      jitter: result?.jitter,
                      height: 350),
                  const SizedBox(height: 4),
                  _StartButton(controller: controller),
                  const SizedBox(height: 12),
                  if (controller.errorMessage != null)
                    _ErrorCard(
                        message: controller.errorMessage!,
                        onRetry: controller.startTest),
                  if (result != null &&
                      controller.phase == TestPhase.finished) ...[
                    const SizedBox(height: 14),
                    _ResultCard(result: result, theme: theme),
                  ],
                  if (result == null && controller.phase == TestPhase.idle) ...[
                    const SizedBox(height: 14),
                    _IdleHint(theme: theme),
                  ],
                  const SizedBox(height: 22),
                  BlazeCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, color: theme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Make it yours',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 3),
                              Text('Build a new dashboard in Blaze Garage',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.48),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 15, color: theme.secondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _gaugeValue(int maxSpeed, BlazeController controller) {
    final result = controller.latestResult;
    switch (controller.phase) {
      case TestPhase.download:
        return maxSpeed * controller.gaugeValue;
      case TestPhase.upload:
        return maxSpeed * controller.gaugeValue * 0.76;
      case TestPhase.ping:
        return maxSpeed * 0.06 * controller.gaugeValue;
      case TestPhase.finished:
        return result?.download.clamp(0, maxSpeed).toDouble() ?? 0;
      case TestPhase.connecting:
        return maxSpeed * 0.025 * controller.gaugeValue;
      case TestPhase.error:
      case TestPhase.idle:
        return 0;
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});

  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.primary.withOpacity(0.30)),
          ),
          child: Icon(Icons.local_fire_department_rounded,
              color: theme.primary, size: 24),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BLAZE',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3)),
            Text('NETWORK PERFORMANCE',
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: Colors.white54,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const Spacer(),
        const IconButton(
            onPressed: null,
            icon: Icon(Icons.more_horiz_rounded, color: Colors.white54)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.phase, required this.isTesting});

  final TestPhase phase;
  final bool isTesting;

  @override
  Widget build(BuildContext context) {
    final color = isTesting
        ? const Color(0xFFFFC857)
        : phase == TestPhase.error
            ? const Color(0xFFFF5A5F)
            : const Color(0xFF8BFF74);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withOpacity(0.24))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(_label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  String get _label {
    switch (phase) {
      case TestPhase.idle:
        return 'READY TO TEST';
      case TestPhase.connecting:
        return 'CONNECTING';
      case TestPhase.ping:
        return 'CHECKING PING';
      case TestPhase.download:
        return 'DOWNLOADING';
      case TestPhase.upload:
        return 'UPLOADING';
      case TestPhase.finished:
        return 'TEST COMPLETE';
      case TestPhase.error:
        return 'TEST FAILED';
    }
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.controller});

  final BlazeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = controller.activeTheme;
    final label = controller.isTesting
        ? 'TESTING…'
        : controller.phase == TestPhase.finished
            ? 'TEST AGAIN'
            : 'START TEST';
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: controller.isTesting ? null : controller.startTest,
        icon: Icon(
            controller.isTesting
                ? Icons.graphic_eq_rounded
                : Icons.play_arrow_rounded,
            size: 22),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w900, letterSpacing: 1.3)),
        style: FilledButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.black,
          disabledBackgroundColor: theme.primary.withOpacity(0.42),
          disabledForegroundColor: Colors.black54,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class _IdleHint extends StatelessWidget {
  const _IdleHint({required this.theme});

  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    return BlazeCard(
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                'A full run samples about 22 MB across multiple requests. Wi-Fi recommended for your first run.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.56),
                    fontSize: 12,
                    height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BlazeCard(
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5A5F)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 12, height: 1.35))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.theme});

  final SpeedResult result;
  final dynamic theme;

  @override
  Widget build(BuildContext context) {
    final shareText =
        'Blaze result — ${result.download.toStringAsFixed(1)} Mbps down, ${result.upload.toStringAsFixed(1)} Mbps up, ${result.ping.toStringAsFixed(0)} ms ping. ${result.quality} connection.';
    return BlazeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('RESULT',
                    style: TextStyle(
                        color: theme.secondary,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(result.quality,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900)),
              ]),
              const Spacer(),
              IconButton(
                tooltip: 'Share result',
                onPressed: () =>
                    Share.share(shareText, subject: 'My Blaze speed test'),
                icon: Icon(Icons.ios_share_rounded, color: theme.primary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(children: [
            MetricTile(
                label: 'Download',
                value: result.download.toStringAsFixed(1),
                unit: 'Mbps'),
            MetricTile(
                label: 'Upload',
                value: result.upload.toStringAsFixed(1),
                unit: 'Mbps'),
            MetricTile(
                label: 'Ping',
                value: result.ping.toStringAsFixed(0),
                unit: 'ms'),
          ]),
          const SizedBox(height: 16),
          Text(
              '${_confidenceLabel(result)}  •  ${_megabytes(result.bytesUsed)} MB sampled',
              style: TextStyle(
                  color: theme.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
          const SizedBox(height: 7),
          Text('${result.provider}  •  ${result.server}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.38), fontSize: 11)),
        ],
      ),
    );
  }

  String _confidenceLabel(SpeedResult result) {
    if (result.confidence >= 0.75) return 'HIGH CONFIDENCE';
    if (result.confidence >= 0.45) return 'MEDIUM CONFIDENCE';
    return 'LOW CONFIDENCE';
  }

  String _megabytes(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
}
