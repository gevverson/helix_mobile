import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

/// Handles all authentication-related API calls.
class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Authenticate with email + password. Returns `true` on success.
  ///
  /// On success the JWT access token is persisted to SharedPreferences
  /// so that subsequent authenticated requests can include it.
  static Future<bool> login(String email, String password) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/auth/token');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
      );

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

  /// Authenticate with Google Sign-In. Returns `true` on success.
  static Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false; // User cancelled

      final auth = await account.authentication;
      if (auth.idToken == null) return false;

      final url = Uri.parse('${AppConstants.baseUrl}/api/v1/auth/google');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': auth.idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Register a new account. Returns `true` on success.
  static Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': name,
          'email': email,
          'password': password,
          'consent': true,
          'bio_profile': {},
        }),
      );

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
