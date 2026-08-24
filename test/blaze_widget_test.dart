import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blaze/app.dart';
import 'package:blaze/controllers/blaze_controller.dart';
import 'package:blaze/models/blaze_theme.dart';
import 'package:blaze/models/dial_profile.dart';
import 'package:blaze/models/speed_result.dart';
import 'package:blaze/services/network_monitor.dart';
import 'package:blaze/services/speed_test_service.dart';
import 'package:blaze/widgets/blaze_gauge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the Blaze test dashboard', (tester) async {
    final controller = BlazeController();
    await tester.pumpWidget(BlazeApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('BLAZE'), findsOneWidget);
    expect(find.text('GO'), findsOneWidget);
    expect(find.text('CLASSIC 140'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('Garage'), findsNothing);
    expect(find.text('History'), findsNothing);
  });

  testWidgets('settings exposes the persistent Blaze Mode toggle',
      (tester) async {
    final controller = BlazeController();
    await tester.pumpWidget(BlazeApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Blaze Mode'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(controller.fireEffectsEnabled, isTrue);

    tester.widget<Switch>(find.byType(Switch)).onChanged!(false);
    await tester.pump();
    expect(controller.fireEffectsEnabled, isFalse);
  });

  test('swipe carousel has one vector and seven photographic dials', () {
    expect(DialProfile.presets.length, 8);
    expect(DialProfile.presets.where((profile) => profile.usesPhoto).length, 7);
    expect(DialProfile.presets.first.usesPhoto, isFalse);
    expect(BlazeTheme.presets.map((theme) => theme.id).toSet().length,
        BlazeTheme.presets.length);
    expect(
        BlazeTheme.presets
            .every((theme) => theme.gaugeStyle == GaugeStyle.classic),
        isTrue);
  });

  test('speed results are stored and migrated as decimal Mbps', () {
    final legacy = SpeedResult.fromJson({
      'timestamp': DateTime.now().toIso8601String(),
      'download': 100,
      'upload': 40,
      'ping': 20,
      'jitter': 2,
      'server': 'edge',
      'provider': 'network',
      'downloadSamples': 3,
      'uploadSamples': 3,
      'bytesUsed': 100,
    });
    expect(legacy.download, 100);
    expect(legacy.upload, 40);

    final current = SpeedResult.fromJson({
      'speedUnit': 'MBps',
      'download': 12.5,
      'upload': 5,
    });
    expect(current.toJson()['speedUnit'], 'Mbps');
    expect(current.download, 100);
    expect(current.upload, 40);

    final mbps = SpeedResult.fromJson({
      'speedUnit': 'Mbps',
      'download': 26.6,
      'upload': 20.68,
    });
    expect(mbps.download, 26.6);
    expect(mbps.upload, 20.68);
  });

  testWidgets('the main page can render vector and photographic profiles',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            SizedBox(
              height: 280,
              child: BlazeGauge(
                theme: DialProfile.presets[0].theme,
                profile: DialProfile.presets[0],
                value: 12,
                phase: TestPhase.download,
              ),
            ),
            SizedBox(
              height: 280,
              child: BlazeGauge(
                theme: DialProfile.presets[1].theme,
                profile: DialProfile.presets[1],
                value: 12,
                phase: TestPhase.upload,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(BlazeGauge), findsNWidgets(2));
  });

  test('network labels cover cellular, Wi-Fi/hotspot, and wired routes', () {
    expect(
      const NetworkSnapshot(NetworkTransport.mobile).label,
      'MOBILE DATA',
    );
    expect(
      const NetworkSnapshot(NetworkTransport.wifi).label,
      'WI-FI / HOTSPOT',
    );
    expect(
      const NetworkSnapshot(NetworkTransport.ethernet).label,
      'ETHERNET',
    );
  });

  test('800 Mbps latches Blaze Mode and its toggle disables the effect',
      () async {
    final controller = BlazeController(
      speedTestService: _ThresholdSpeedTest(),
      networkMonitor: const _FakeNetworkMonitor(
        NetworkSnapshot(NetworkTransport.mobile),
      ),
    );

    await controller.startTest();
    expect(controller.blazeModeActive, isTrue);

    controller.setFireEffectsEnabled(false);
    expect(controller.blazeModeActive, isFalse);
    controller.setFireEffectsEnabled(true);
    expect(controller.blazeModeActive, isTrue);
  });

  test('Blaze Mode preference survives controller hydration', () async {
    SharedPreferences.setMockInitialValues({'fire_effects_enabled': false});
    final controller = BlazeController(
      networkMonitor: const _FakeNetworkMonitor(
        NetworkSnapshot(NetworkTransport.wifi),
      ),
    );

    await controller.hydrate();
    expect(controller.fireEffectsEnabled, isFalse);

    controller.setFireEffectsEnabled(true);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('fire_effects_enabled'), isTrue);
    controller.dispose();
  });

  test('offline routes are rejected before a transfer begins', () async {
    final controller = BlazeController(
      speedTestService: _ThresholdSpeedTest(),
      networkMonitor: const _FakeNetworkMonitor(
        NetworkSnapshot(NetworkTransport.offline),
      ),
    );

    await controller.startTest();
    expect(controller.phase, TestPhase.error);
    expect(controller.errorMessage, contains('No active internet'));
  });
}

class _FakeNetworkMonitor implements NetworkMonitor {
  const _FakeNetworkMonitor(this.snapshot);

  final NetworkSnapshot snapshot;

  @override
  Future<NetworkSnapshot> check() async => snapshot;

  @override
  Stream<NetworkSnapshot> get changes => const Stream.empty();
}

class _ThresholdSpeedTest extends SpeedTestService {
  @override
  Future<SpeedResult> run({
    required void Function(TestPhase phase) onPhase,
    required void Function(SpeedTestProgress progress) onProgress,
  }) async {
    onPhase(TestPhase.download);
    onProgress(const SpeedTestProgress(fraction: 0.5, speedMbps: 820));
    onPhase(TestPhase.finished);
    return SpeedResult(
      timestamp: DateTime(2026, 8, 24),
      download: 820,
      upload: 90,
      ping: 8,
      jitter: 1,
      server: 'test-edge',
      provider: 'test-network',
      downloadSamples: 8,
      uploadSamples: 4,
      bytesUsed: 10 * 1024 * 1024,
    );
  }
}
