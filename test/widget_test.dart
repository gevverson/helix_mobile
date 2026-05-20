import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helix_mobile/main.dart';
import 'package:helix_mobile/providers/auth_provider.dart';
import 'package:helix_mobile/providers/match_provider.dart';
import 'package:helix_mobile/providers/profile_provider.dart';
import 'package:helix_mobile/providers/scan_provider.dart';
import 'package:helix_mobile/models/match_result.dart';
import 'package:helix_mobile/screens/match_screen.dart';

// Suppress image-resource HTTP errors that occur in tests because no real
// backend or CDN is reachable.
void _suppressImageErrors() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.library == 'image resource service') return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ChangeNotifierProvider(create: (_) => ScanProvider()),
      ChangeNotifierProvider(create: (_) => MatchProvider()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Splash screen', () {
    testWidgets('renders branding text', (tester) async {
      _suppressImageErrors();
      await tester.pumpWidget(const HelixApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('HELIX'), findsOneWidget);
      expect(find.text('Your Genetic Health Companion'), findsOneWidget);

      // Advance past 2.5 s navigation timer to drain pending timers
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();
    });
  });

  group('Match screen', () {
    testWidgets('shows loading spinner while fetching profile', (tester) async {
      await tester.pumpWidget(_wrap(const MatchScreen()));
      // First frame triggers the profile load — spinner should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows partner genotype chips', (tester) async {
      await tester.pumpWidget(_wrap(const MatchScreen()));
      // Let the async profile load settle (returns null — no real API)
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      for (final genotype in ['AA', 'AS', 'SS', 'AC', 'SC']) {
        expect(find.text(genotype), findsWidgets,
            reason: '$genotype chip should be present');
      }
    });

    testWidgets('shows error when CHECK is tapped with no genotype selected',
        (tester) async {
      await tester.pumpWidget(_wrap(const MatchScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Button may be below the fold — scroll to it before tapping
      await tester.scrollUntilVisible(
        find.text('CHECK COMPATIBILITY'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('CHECK COMPATIBILITY'));
      await tester.pump();

      expect(find.text("Please select the partner's genotype."), findsOneWidget);
    });
  });

  group('MatchResult model', () {
    test('fromJson parses valid response', () {
      final json = {
        'status': 'safe',
        'messages': ['All good!'],
        'can_unblur_photos': true,
      };
      final result = MatchResult.fromJson(json);
      expect(result.status, 'safe');
      expect(result.messages, ['All good!']);
      expect(result.canUnblurPhotos, true);
    });

    test('fromJson uses defaults for missing keys', () {
      final result = MatchResult.fromJson({});
      expect(result.status, 'unknown');
      expect(result.messages, isEmpty);
      expect(result.canUnblurPhotos, false);
    });
  });
}
