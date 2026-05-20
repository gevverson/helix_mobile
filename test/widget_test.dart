import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helix_mobile/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    // Provide empty prefs so AuthService.isLoggedIn() doesn't throw
    SharedPreferences.setMockInitialValues({});

    // After the 2.5s splash timer the app navigates to login, which loads a
    // remote Google brand image. In test mode all HTTP returns 400, so we
    // suppress image-resource errors to keep the test focused on app rendering.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.library == 'image resource service') return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(const HelixApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Branding visible during the splash delay
    expect(find.text('HELIX'), findsOneWidget);
    expect(find.text('Your Genetic Health Companion'), findsOneWidget);

    // Advance past the 2.5s navigation timer to resolve pending timers
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
  });
}
