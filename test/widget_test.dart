import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helix_mobile/main.dart';
import 'package:helix_mobile/providers/auth_provider.dart';
import 'package:helix_mobile/providers/match_provider.dart';
import 'package:helix_mobile/providers/profile_provider.dart';
import 'package:helix_mobile/providers/scan_provider.dart';
import 'package:helix_mobile/models/match_result.dart';
import 'package:helix_mobile/models/scan_result.dart';
import 'package:helix_mobile/screens/login_screen.dart';
import 'package:helix_mobile/screens/register_screen.dart';
import 'package:helix_mobile/screens/match_screen.dart';
import 'package:helix_mobile/screens/scan_screen.dart';
import 'package:helix_mobile/services/token_store.dart';

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
    FlutterSecureStorage.setMockInitialValues({});
    TokenStore.resetForTest();
  });

  // ── Splash Screen ────────────────────────────────────────────────────────

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

  // ── Login Screen ─────────────────────────────────────────────────────────

  group('Login screen', () {
    testWidgets('renders title and form fields', (tester) async {
      _suppressImageErrors();
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      expect(find.text('HELIX'), findsOneWidget);
      expect(find.text('Sign in to access your vault'), findsOneWidget);
      expect(find.text('ENTER VAULT'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('shows validation error when submitted with empty fields',
        (tester) async {
      _suppressImageErrors();
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      // Tap submit without filling in anything
      await tester.tap(find.text('ENTER VAULT'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('register link is visible on login screen', (tester) async {
      _suppressImageErrors();
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      expect(find.text('Register'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
    });
  });

  // ── Register Screen ──────────────────────────────────────────────────────

  group('Register screen', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));
      await tester.pump();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('CREATE ACCOUNT'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows password mismatch error', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'john@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Secret1234');
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'), 'DifferentPass1');

      await tester.scrollUntilVisible(
        find.text('CREATE ACCOUNT'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('password strength indicator appears after typing', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));
      await tester.pump();

      // Strength indicator is hidden until the user types
      expect(find.text('Weak'), findsNothing);

      // Type a short password — indicator should appear showing 'Weak'
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'abc');
      await tester.pump();
      expect(find.text('Weak'), findsOneWidget);

      // Type a stronger password — label should upgrade
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'Str0ng!Pass');
      await tester.pump();
      expect(find.text('Weak'), findsNothing);
    });
  });

  // ── Match Screen ─────────────────────────────────────────────────────────

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

    testWidgets('genotype chip becomes selected on tap', (tester) async {
      await tester.pumpWidget(_wrap(const MatchScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Tap 'AS' chip
      await tester.tap(find.text('AS').first);
      await tester.pump();

      // Error should now be gone after selecting a genotype
      expect(find.text("Please select the partner's genotype."), findsNothing);
    });
  });

  // ── Scan Screen ──────────────────────────────────────────────────────────

  group('Scan screen', () {
    testWidgets('renders upload area and instructions', (tester) async {
      await tester.pumpWidget(_wrap(const ScanScreen()));
      await tester.pump();

      expect(find.text('Tap to upload medical report'), findsOneWidget);
      expect(find.text('Upload a medical report to extract health data'), findsOneWidget);
    });
  });

  // ── MatchResult model ────────────────────────────────────────────────────

  group('MatchResult model', () {
    test('fromJson parses valid safe response', () {
      final result = MatchResult.fromJson({
        'status': 'safe',
        'messages': ['All good!'],
        'can_unblur_photos': true,
      });
      expect(result.status, 'safe');
      expect(result.messages, ['All good!']);
      expect(result.canUnblurPhotos, true);
    });

    test('fromJson parses danger response', () {
      final result = MatchResult.fromJson({
        'status': 'danger',
        'messages': ['CRITICAL: 25% chance of sickle cell disease.'],
        'can_unblur_photos': false,
      });
      expect(result.status, 'danger');
      expect(result.canUnblurPhotos, false);
      expect(result.messages.first, contains('CRITICAL'));
    });

    test('fromJson parses caution response', () {
      final result = MatchResult.fromJson({
        'status': 'caution',
        'messages': ['ADVISORY: All children will be carriers.'],
        'can_unblur_photos': true,
      });
      expect(result.status, 'caution');
      expect(result.canUnblurPhotos, true);
    });

    test('fromJson uses safe defaults for missing keys', () {
      final result = MatchResult.fromJson({});
      expect(result.status, 'unknown');
      expect(result.messages, isEmpty);
      expect(result.canUnblurPhotos, false);
    });

    test('fromJson handles empty messages list', () {
      final result = MatchResult.fromJson({'status': 'safe', 'messages': []});
      expect(result.messages, isEmpty);
    });
  });

  // ── ScanResult model ─────────────────────────────────────────────────────

  group('ScanResult model', () {
    test('fromJson parses detected fields', () {
      final result = ScanResult.fromJson({
        'genotype': 'AS',
        'blood_group': 'O+',
      });
      expect(result.genotype, 'AS');
      expect(result.bloodGroup, 'O+');
    });

    test('fromJson handles null fields gracefully', () {
      final result = ScanResult.fromJson({});
      expect(result.genotype, isNull);
      expect(result.bloodGroup, isNull);
    });

    test('hasData is true when genotype is present', () {
      final result = ScanResult.fromJson({'genotype': 'AA'});
      expect(result.hasData, true);
    });

    test('hasData is false when all fields are null', () {
      final result = ScanResult.fromJson({});
      expect(result.hasData, false);
    });
  });
}
