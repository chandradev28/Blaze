import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blaze/app.dart';
import 'package:blaze/controllers/blaze_controller.dart';
import 'package:blaze/models/blaze_theme.dart';
import 'package:blaze/models/dial_profile.dart';
import 'package:blaze/models/speed_result.dart';
import 'package:blaze/services/speed_test_service.dart';
import 'package:blaze/widgets/blaze_gauge.dart';

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
}
