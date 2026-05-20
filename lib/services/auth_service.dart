import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import 'api_client.dart';

/// Handles all authentication-related API calls.
class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConstants.googleClientId,
    scopes: ['email', 'profile'],
  );

  static final _client = ApiClient.instance;

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
      // Force account picker by signing out first
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();

      if (account == null) {
        return 'Google Sign-In was cancelled.';
      }

      final auth = await account.authentication;

      if (auth.idToken == null) {
        return 'Failed to retrieve secure token from Google. Please try again.';
      }

      if (kDebugMode) {
        debugPrint('AuthService: Google account retrieved — ${account.email}');
      }

      final url = Uri.parse('${AppConstants.baseUrl}/api/v1/auth/google');

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
        return null; // success
      }

      if (kDebugMode) {
        debugPrint('AuthService: backend returned ${response.statusCode}');
      }
      return 'Server error (${response.statusCode}). Please try again later.';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Google Sign-In error — $e');
      }

      final msg = e.toString();
      if (msg.contains('network_error')) {
        return 'Network error. Please check your connection.';
      } else if (msg.contains('DEVELOPER_ERROR')) {
        return 'Configuration error. Please contact support.';
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
