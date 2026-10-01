import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helix_mobile/config/app_constants.dart';
import 'package:helix_mobile/services/api_interceptor.dart';
import 'package:helix_mobile/services/session_manager.dart';
import 'package:helix_mobile/services/token_store.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SessionManager.sessionExpired.value = false;
  });

  /// Seed storage: `token` goes to secure storage, everything else to prefs.
  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    final token = values[AppConstants.tokenKey] as String?;
    FlutterSecureStorage.setMockInitialValues(
        token == null ? {} : {AppConstants.tokenKey: token});
    TokenStore.resetForTest();
    SharedPreferences.setMockInitialValues(
        Map.of(values)..remove(AppConstants.tokenKey));
    return SharedPreferences.getInstance();
  }

  group('SessionManager.onUnauthorized', () {
    test('expired password session is cleared, never silently renewed', () async {
      final prefs = await prefsWith({
        AppConstants.tokenKey: 'tok-A',
        AppConstants.authMethodKey: 'password',
      });

      await SessionManager.onUnauthorized('tok-A');

      expect(await TokenStore.read(), isNull);
      expect(prefs.getString(AppConstants.authMethodKey), isNull);
      expect(SessionManager.sessionExpired.value, isTrue);
    });

    test('401 for a token that is no longer stored is ignored', () async {
      await prefsWith({AppConstants.tokenKey: 'tok-B'});

      await SessionManager.onUnauthorized('tok-A');

      expect(await TokenStore.read(), 'tok-B');
      expect(SessionManager.sessionExpired.value, isFalse);
    });

    test('401 after logout (no stored token) does nothing', () async {
      await prefsWith({});

      await SessionManager.onUnauthorized('tok-A');

      expect(SessionManager.sessionExpired.value, isFalse);
    });
  });

  group('HelixApiInterceptor', () {
    test('401 on an unauthenticated request (wrong password) does not touch the session', () async {
      await prefsWith({
        AppConstants.tokenKey: 'tok-A',
        AppConstants.authMethodKey: 'password',
      });
      final request = http.Request('POST', Uri.parse('http://x/api/v1/auth/token'));

      await HelixApiInterceptor().interceptResponse(
        response: http.Response('', 401, request: request),
      );
      await Future<void>.delayed(Duration.zero);

      expect(await TokenStore.read(), 'tok-A');
      expect(SessionManager.sessionExpired.value, isFalse);
    });

    test('401 on an authenticated request expires that session', () async {
      await prefsWith({
        AppConstants.tokenKey: 'tok-A',
        AppConstants.authMethodKey: 'password',
      });
      final request = http.Request('GET', Uri.parse('http://x/api/v1/users/me'))
        ..headers['Authorization'] = 'Bearer tok-A';

      await HelixApiInterceptor().interceptResponse(
        response: http.Response('', 401, request: request),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await TokenStore.read(), isNull);
      expect(SessionManager.sessionExpired.value, isTrue);
    });
  });
}
