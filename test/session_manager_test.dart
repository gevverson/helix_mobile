import 'package:flutter_test/flutter_test.dart';
import 'package:helix_mobile/config/app_constants.dart';
import 'package:helix_mobile/services/api_interceptor.dart';
import 'package:helix_mobile/services/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SessionManager.sessionExpired.value = false;
  });

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('SessionManager.onUnauthorized', () {
    test('expired password session is cleared, never silently renewed', () async {
      final prefs = await prefsWith({
        AppConstants.tokenKey: 'tok-A',
        AppConstants.authMethodKey: 'password',
      });

      await SessionManager.onUnauthorized('tok-A');

      expect(prefs.getString(AppConstants.tokenKey), isNull);
      expect(prefs.getString(AppConstants.authMethodKey), isNull);
      expect(SessionManager.sessionExpired.value, isTrue);
    });

    test('401 for a token that is no longer stored is ignored', () async {
      final prefs = await prefsWith({AppConstants.tokenKey: 'tok-B'});

      await SessionManager.onUnauthorized('tok-A');

      expect(prefs.getString(AppConstants.tokenKey), 'tok-B');
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
      final prefs = await prefsWith({
        AppConstants.tokenKey: 'tok-A',
        AppConstants.authMethodKey: 'password',
      });
      final request = http.Request('POST', Uri.parse('http://x/api/v1/auth/token'));

      await HelixApiInterceptor().interceptResponse(
        response: http.Response('', 401, request: request),
      );
      await Future<void>.delayed(Duration.zero);

      expect(prefs.getString(AppConstants.tokenKey), 'tok-A');
      expect(SessionManager.sessionExpired.value, isFalse);
    });

    test('401 on an authenticated request expires that session', () async {
      final prefs = await prefsWith({
        AppConstants.tokenKey: 'tok-A',
        AppConstants.authMethodKey: 'password',
      });
      final request = http.Request('GET', Uri.parse('http://x/api/v1/users/me'))
        ..headers['Authorization'] = 'Bearer tok-A';

      await HelixApiInterceptor().interceptResponse(
        response: http.Response('', 401, request: request),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(prefs.getString(AppConstants.tokenKey), isNull);
      expect(SessionManager.sessionExpired.value, isTrue);
    });
  });
}
