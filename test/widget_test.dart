import 'package:flutter_test/flutter_test.dart';

import 'package:helix_mobile/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HelixApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify the splash screen branding is displayed
    expect(find.text('HELIX CORE'), findsOneWidget);
    expect(find.text('Your Genetic Health Companion'), findsOneWidget);
  });
}
