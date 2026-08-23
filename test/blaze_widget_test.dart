import 'package:flutter_test/flutter_test.dart';

import 'package:blaze/app.dart';
import 'package:blaze/controllers/blaze_controller.dart';
import 'package:blaze/models/blaze_theme.dart';

void main() {
  testWidgets('renders the Blaze test dashboard', (tester) async {
    final controller = BlazeController();
    await tester.pumpWidget(BlazeApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('BLAZE'), findsOneWidget);
    expect(find.text('START TEST'), findsOneWidget);
    expect(find.text('Blaze Core'), findsOneWidget);
  });

  test('theme presets expose distinct dashboard identities', () {
    expect(BlazeTheme.presets.length, greaterThanOrEqualTo(6));
    expect(BlazeTheme.presets.map((theme) => theme.id).toSet().length,
        BlazeTheme.presets.length);
  });
}
