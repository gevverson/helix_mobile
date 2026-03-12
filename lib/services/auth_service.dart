import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import 'api_interceptor.dart';

/// Handles all authentication-related API calls.
class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '270036019497-oaau24hq70o051b9u2tftcif78ak05a2.apps.googleusercontent.com',
  );

  static final _client = InterceptedClient.build(
    interceptors: [HelixApiInterceptor()],
    retryPolicy: HelixRetryPolicy(),
  );

  /// Authenticate with email + password. Returns `true` on success.
  ///
  /// On success the JWT access token is persisted to SharedPreferences
  /// so that subsequent authenticated requests can include it.
  static Future<bool> login(String email, String password) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/auth/token');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Authenticate with Google Sign-In. Returns error message or null on success.
  static Future<String?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return 'User cancelled Google Sign-In.';

      final auth = await account.authentication;
      if (auth.idToken == null) return 'Failed to retrieve Google ID token.';

      final url = Uri.parse('${AppConstants.baseUrl}/api/v1/auth/google');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': auth.idToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        return null; // Success
      }
      return 'Backend error: HTTP ${response.statusCode} - ${response.body}';
    } catch (e, stack) {
      print('Google Sign-In exception: $e');
      print('Stack trace: $stack');
      return 'Google Sign-In exception: $e';
    }
  }

  /// Register a new account. Returns `true` on success.
  static Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': name,
          'email': email,
          'password': password,
          'consent': true,
          'bio_profile': {},
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Remove the stored auth token (log out).
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }

  /// Retrieve the stored auth token, if any.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  /// Whether a token is currently stored.
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
