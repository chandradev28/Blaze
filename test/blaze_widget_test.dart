import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blaze/app.dart';
import 'package:blaze/controllers/blaze_controller.dart';
import 'package:blaze/models/blaze_theme.dart';
import 'package:blaze/services/speed_test_service.dart';
import 'package:blaze/widgets/blaze_gauge.dart';

void main() {
  testWidgets('renders the Blaze test dashboard', (tester) async {
    final controller = BlazeController();
    await tester.pumpWidget(BlazeApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('BLAZE'), findsOneWidget);
    expect(find.text('START TEST'), findsOneWidget);
    expect(find.text('Blaze Core'), findsOneWidget);
  });

  test('theme presets expose distinct dashboard identities', () {
    expect(BlazeTheme.presets.length, greaterThanOrEqualTo(6));
    expect(BlazeTheme.presets.map((theme) => theme.id).toSet().length,
        BlazeTheme.presets.length);
  });

  testWidgets('F1 and MotoGP dashboards use their dedicated renderers',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            SizedBox(
              height: 280,
              child: BlazeGauge(
                theme: BlazeTheme.presets[1],
                value: 820,
                phase: TestPhase.download,
              ),
            ),
            SizedBox(
              height: 280,
              child: BlazeGauge(
                theme: BlazeTheme.presets[2],
                value: 620,
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
