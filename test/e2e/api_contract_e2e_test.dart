// End-to-end contract test: drives the app's real service layer against a
// running helix-core. Skipped unless pointed at a backend explicitly:
//
//   flutter test test/e2e --dart-define=HELIX_E2E=true \
//     --dart-define=API_BASE_URL=http://localhost:8000
//
// It creates throwaway users, so only run it against a local/dev backend.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helix_mobile/services/auth_service.dart';
import 'package:helix_mobile/services/dating_service.dart';
import 'package:helix_mobile/services/profile_service.dart';
import 'package:helix_mobile/services/session_manager.dart';
import 'package:helix_mobile/services/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _enabled = bool.fromEnvironment('HELIX_E2E');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final run = DateTime.now().millisecondsSinceEpoch;
  String email(String who) => '$who.$run@helixe2e.dev';
  const password = 'passWord12';

  setUpAll(() {
    HttpOverrides.global = null; // real network, not flutter_test's fake HTTP
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => ['wifi'],
    );
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> signInAs(String who) async {
    await AuthService.logout(unregisterDevice: false);
    expect(await AuthService.login(email(who), password), isTrue, reason: 'login $who');
  }

  test('register, profiles, discovery, match, chat, session, erasure', () async {
    // ── Register two users through the app's register call ──
    for (final (who, genotype) in [('ada', 'AA'), ('ben', 'AS')]) {
      final ok = await AuthService.register('$who Tester', email(who), password,
          consentHealthData: true, consentCrossBorder: true, isOver18: true, genotype: genotype);
      expect(ok, isTrue, reason: 'register $who');
    }

    // ── Wrong password: false, and no session side effects ──
    expect(await AuthService.login(email('ada'), 'wrongPass99'), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(SessionManager.sessionExpired.value, isFalse);

    // ── Dating profiles ──
    for (final (who, gender, seeking) in [('ada', 'female', 'male'), ('ben', 'male', 'female')]) {
      await signInAs(who);
      expect(
        await ProfileService.updateDatingProfile(
            dateOfBirth: '1995-03-02', gender: gender, seeking: seeking, city: 'Kisumu$run'),
        isTrue,
      );
    }
    final ben = (await ProfileService.fetchProfile())!;
    expect(ben.age, isNotNull, reason: '/users/me age parsed into User');
    expect(ben.genotype, 'AS');

    // ── Genotype edits: only set fields sent; cooldown message surfaced ──
    expect(await ProfileService.updateProfile('AA', null), isNull, reason: 'first change ok');
    final blocked = await ProfileService.updateProfile('SS', null);
    expect(blocked, contains('30 days'), reason: 'cooldown message shown to the user');
    expect(await ProfileService.updateProfile(null, 'B+'), isNull, reason: 'blood group alone ok');
    expect(await ProfileService.updateProfile('Unknown', 'Unknown'), isNotNull,
        reason: 'nothing valid to save → error, not a 422 round-trip');

    // ── Discovery: no genetic info ──
    await signInAs('ada');
    final cards = await DatingService.fetchDiscovery(city: 'Kisumu$run');
    final benCard = cards.firstWhere((c) => c['name'] == 'ben');
    expect(benCard.containsKey('compatibility'), isFalse);

    // ── Like → match (compatibility revealed only now) ──
    expect((await DatingService.likeUser(benCard['user_id'] as String))!['matched'], isFalse);
    await signInAs('ben');
    final adaId = (await DatingService.fetchDiscovery(city: 'Kisumu$run'))
        .firstWhere((c) => c['name'] == 'ada')['user_id'] as String;
    final like = (await DatingService.likeUser(adaId))!;
    expect(like['matched'], isTrue);
    expect(like['match']['compatibility'], 'safe'); // AA x AA after Ben's change
    final matchId = (await DatingService.fetchMatches()).single['match_id'] as String;

    // ── Chat ──
    expect(await DatingService.sendMessage(matchId, 'hello ada'), isNotNull);
    await signInAs('ada');
    expect((await DatingService.fetchMatches()).single['unread_count'], 1);
    final thread = await DatingService.fetchMessages(matchId);
    expect(thread!.map((m) => m['body']), ['hello ada']);

    // ── Expired/invalid token on a password session → cleared, UI notified ──
    await TokenStore.write('not-a-valid-jwt');
    await DatingService.fetchMatches();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(await TokenStore.read(), isNull);
    expect(SessionManager.sessionExpired.value, isTrue);
    SessionManager.sessionExpired.value = false;

    // ── Erasure: delete Ben through the app; he can't sign in again ──
    await signInAs('ben');
    expect(await ProfileService.deleteAccount(), isTrue);
    await AuthService.logout(unregisterDevice: false);
    expect(await AuthService.login(email('ben'), password), isFalse);
    expect(SessionManager.sessionExpired.value, isFalse, reason: 'no silent re-auth after deletion');
  }, skip: _enabled ? false : 'set --dart-define=HELIX_E2E=true and API_BASE_URL to run',
      timeout: const Timeout(Duration(minutes: 3)));
}

