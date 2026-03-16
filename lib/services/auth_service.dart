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
    scopes: ['email', 'profile'],
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
      print('DEBUG: Starting Google Sign-In process (forcing account selection)...');
      // Explicitly sign out before signing in to force the account picker dialog
      await _googleSignIn.signOut();
      
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        print('DEBUG: Google Sign-In cancelled by user or intermittent error.');
        return 'Google Sign-In was cancelled.';
      }

      print('DEBUG: Google account retrieved: ${account.email}');
      final auth = await account.authentication;
      
      if (auth.idToken == null) {
        print('DEBUG: Failed to retrieve Google ID token (it is null).');
        return 'Failed to retrieve secure token from Google. Please try again.';
      }

      // --- DEBUG: Decode ID Token to see claims ---
      try {
        final parts = auth.idToken!.split('.');
        if (parts.length > 1) {
          final payload = parts[1];
          final normalizedPayload = base64.normalize(payload);
          final claims = jsonDecode(utf8.decode(base64.decode(normalizedPayload)));
          print('DEBUG: ID Token Detail - aud: ${claims['aud']}, iss: ${claims['iss']}, email: ${claims['email']}');
        }
      } catch (e) {
        print('DEBUG: Failed to decode ID Token: $e');
      }

      final url = Uri.parse('${AppConstants.baseUrl}/api/v1/auth/google');
      print('DEBUG: Authenticating with backend: $url');
      
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': auth.idToken}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        print('DEBUG: Backend authentication successful.');
        return null;
      }
      
      print('DEBUG: Backend failed with status ${response.statusCode}: ${response.body}');
      return 'Server error: ${response.statusCode}. Please try again later.';
    } catch (e, stack) {
      print('DEBUG: Google Sign-In exception: $e');
      print('DEBUG: Stack trace: $stack');
      
      if (e.toString().contains('network_error')) {
        return 'Network error. Please check your connection.';
      } else if (e.toString().contains('DEVELOPER_ERROR')) {
        return 'Configuration error (Developer Error). Please contact support.';
      }
      return 'An unexpected error occurred during Google Sign-In.';
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
