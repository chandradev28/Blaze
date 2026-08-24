import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/blaze_controller.dart';
import '../models/blaze_theme.dart';
import '../models/dial_profile.dart';
import '../models/speed_result.dart';
import '../services/speed_test_service.dart';
import '../widgets/blaze_gauge.dart';
import '../widgets/blaze_ui.dart';
import '../widgets/fire_backdrop.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.controller, super.key});

  final BlazeController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _profileController;
  late int _profileIndex;

  List<DialProfile> get _profiles => DialProfile.presets;

  @override
  void initState() {
    super.initState();
    final activeId = widget.controller.activeTheme.id;
    final selected =
        _profiles.indexWhere((profile) => profile.themeId == activeId);
    _profileIndex = selected < 0 ? 0 : selected;
    _profileController = PageController(initialPage: _profileIndex);
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  void _selectProfile(int index) {
    if (index == _profileIndex) return;
    setState(() => _profileIndex = index);
    widget.controller.selectTheme(_profiles[index].theme);
  }

  void _openSettings(BlazeController controller, BlazeTheme theme) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => _SettingsSheet(
          controller: controller,
          theme: theme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final selectedProfile = _profiles[_profileIndex];
        final theme = selectedProfile.theme;
        final result = controller.latestResult;
        final value = _gaugeValue(controller);
        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FireBackdrop(
                active: controller.blazeModeActive,
                accent: theme.primary,
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        theme: theme,
                        networkLabel: controller.network.label,
                        onSettings: () => _openSettings(controller, theme),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _StatusPill(
                              phase: controller.phase,
                              isTesting: controller.isTesting),
                          const Spacer(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.08, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: controller.blazeModeActive
                                ? Row(
                                    key: const ValueKey('blaze-mode'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Colors.orange.shade300,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        'BLAZE MODE',
                                        style: TextStyle(
                                          color: Color(0xFFFFB24A),
                                          fontSize: 10,
                                          letterSpacing: 1.4,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    selectedProfile.name.toUpperCase(),
                                    key: ValueKey(selectedProfile.themeId),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.58),
                                      fontSize: 10,
                                      letterSpacing: 1.6,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      _PhaseTrack(
                        progress: controller.gaugeValue,
                        isTesting: controller.isTesting,
                        color: theme.primary,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 362,
                        child: PageView.builder(
                          controller: _profileController,
                          itemCount: _profiles.length,
                          onPageChanged: _selectProfile,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final profile = _profiles[index];
                            return BlazeGauge(
                              theme: profile.theme,
                              profile: profile,
                              value: value,
                              phase: controller.phase,
                              download: result?.download ??
                                  (controller.phase == TestPhase.download
                                      ? value
                                      : null),
                              upload: result?.upload ??
                                  (controller.phase == TestPhase.upload
                                      ? value
                                      : null),
                              ping: result?.ping,
                              jitter: result?.jitter,
                              scaleMax: profile.usesPhoto
                                  ? profile.theme.maxSpeed.toDouble()
                                  : controller.dialMax,
                              height: 350,
                            );
                          },
                        ),
                      ),
                      _SwipeHint(
                        index: _profileIndex,
                        count: _profiles.length,
                        color: theme.primary,
                      ),
                      const SizedBox(height: 14),
                      _StartButton(controller: controller, theme: theme),
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
                      if (result == null &&
                          controller.phase == TestPhase.idle) ...[
                        const SizedBox(height: 12),
                        Text('Swipe the dial to choose a profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.38),
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _gaugeValue(BlazeController controller) {
    final result = controller.latestResult;
    switch (controller.phase) {
      case TestPhase.download:
      case TestPhase.upload:
      case TestPhase.ping:
      case TestPhase.connecting:
        return controller.liveSpeed;
      case TestPhase.finished:
        return result?.download ?? controller.liveSpeed;
      case TestPhase.error:
      case TestPhase.idle:
        return 0;
    }
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.index,
    required this.count,
    required this.color,
  });

  final int index;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(
          count,
          (dot) => AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            width: dot == index ? 18 : 4,
            decoration: BoxDecoration(
              color: dot == index ? color : Colors.white24,
              borderRadius: BorderRadius.circular(8),
              boxShadow: dot == index
                  ? [BoxShadow(color: color.withOpacity(0.38), blurRadius: 9)]
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhaseTrack extends StatelessWidget {
  const _PhaseTrack({
    required this.progress,
    required this.isTesting,
    required this.color,
  });

  final double progress;
  final bool isTesting;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 2,
        child: LinearProgressIndicator(
          value: isTesting ? progress.clamp(0.0, 1.0) : 0,
          backgroundColor: Colors.white.withOpacity(0.05),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.theme,
    required this.networkLabel,
    required this.onSettings,
  });

  final dynamic theme;
  final String networkLabel;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 38,
          width: 30,
          child: CustomPaint(
            painter: _BlazeMarkPainter(color: theme.primary),
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          'BLAZE',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 4.2,
          ),
        ),
        const Spacer(),
        Text(
          networkLabel,
          style: TextStyle(
            color: Colors.white.withOpacity(0.32),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(width: 5),
        IconButton(
          tooltip: 'Settings',
          onPressed: onSettings,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.tune_rounded,
            color: Colors.white.withOpacity(0.58),
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.controller, required this.theme});

  final BlazeController controller;
  final BlazeTheme theme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        decoration: const BoxDecoration(
          color: Color(0xFF0B0B0D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 38,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B18).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFF6A35),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blaze Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Fire and haptic effect when live speed reaches 800 Mbps.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Switch.adaptive(
                  value: controller.fireEffectsEnabled,
                  activeColor: theme.primary,
                  onChanged: controller.setFireEffectsEnabled,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'ACTIVE CONNECTION',
              style: TextStyle(
                color: Colors.white.withOpacity(0.34),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.network.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _NetworkChip('CELLULAR'),
                _NetworkChip('WI-FI'),
                _NetworkChip('HOTSPOT'),
                _NetworkChip('VPN'),
                _NetworkChip('ETHERNET'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkChip extends StatelessWidget {
  const _NetworkChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _BlazeMarkPainter extends CustomPainter {
  const _BlazeMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.66, 0)
      ..lineTo(size.width * 0.17, size.height * 0.56)
      ..lineTo(size.width * 0.47, size.height * 0.53)
      ..lineTo(size.width * 0.25, size.height)
      ..lineTo(size.width * 0.86, size.height * 0.37)
      ..lineTo(size.width * 0.55, size.height * 0.40)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color, const Color(0xFFFF3B30)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _BlazeMarkPainter oldDelegate) =>
      oldDelegate.color != color;
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.45, end: isTesting ? 1 : 0.65),
          duration: const Duration(milliseconds: 700),
          builder: (context, opacity, _) => Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(
              color: color.withOpacity(opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.46), blurRadius: 8),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.54),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
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
  const _StartButton({required this.controller, required this.theme});

  final BlazeController controller;
  final BlazeTheme theme;

  @override
  Widget build(BuildContext context) {
    final canStart = !controller.isTesting;
    final finished = controller.phase == TestPhase.finished;
    return Center(
      child: Semantics(
        button: true,
        label: finished ? 'Test again' : 'Start speed test',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canStart ? controller.startTest : null,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: 78,
              width: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0B0B0D),
                border: Border.all(
                  color: theme.primary.withOpacity(canStart ? 0.82 : 0.28),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withOpacity(
                      controller.isTesting ? 0.10 : 0.28,
                    ),
                    blurRadius: controller.isTesting ? 12 : 25,
                    spreadRadius: controller.isTesting ? 0 : 2,
                  ),
                ],
              ),
              child: controller.isTesting
                  ? Padding(
                      padding: const EdgeInsets.all(23),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primary,
                        backgroundColor: Colors.white.withOpacity(0.08),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          finished
                              ? Icons.refresh_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                        Text(
                          finished ? 'AGAIN' : 'GO',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - progress)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF09090B),
          borderRadius: BorderRadius.circular(24),
        ),
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
