import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import 'api_client.dart';
import 'push_service.dart';

/// Outcome of a Google sign-in attempt.
class GoogleSignInResult {
  /// Human-readable error, or null on success.
  final String? error;

  /// True when the signed-in user still has to complete the consent + 18+ gate
  /// (a first-time Google user who skipped the registration form).
  final bool needsConsent;

  const GoogleSignInResult({this.error, this.needsConsent = false});

  bool get isSuccess => error == null;
}

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
        await prefs.setString(AppConstants.authMethodKey, 'password');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Authenticate with Google Sign-In.
  ///
  /// Returns a [GoogleSignInResult] — `isSuccess` is true when signed in, and
  /// `needsConsent` is true when the user must still complete the consent gate.
  static Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      // Force account picker by signing out first
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();

      if (account == null) {
        return const GoogleSignInResult(error: 'Google Sign-In was cancelled.');
      }

      final auth = await account.authentication;

      if (auth.idToken == null) {
        return const GoogleSignInResult(
            error: 'Failed to retrieve secure token from Google. Please try again.');
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
        await prefs.setString(AppConstants.authMethodKey, 'google');
        return GoogleSignInResult(needsConsent: data['needs_consent'] == true);
      }

      if (kDebugMode) {
        debugPrint('AuthService: backend returned ${response.statusCode}');
      }
      return GoogleSignInResult(
          error: 'Server error (${response.statusCode}). Please try again later.');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Google Sign-In error — $e');
      }

      final msg = e.toString();
      if (msg.contains('network_error')) {
        return const GoogleSignInResult(error: 'Network error. Please check your connection.');
      } else if (msg.contains('DEVELOPER_ERROR')) {
        return const GoogleSignInResult(error: 'Configuration error. Please contact support.');
      }
      return const GoogleSignInResult(
          error: 'An unexpected error occurred during Google Sign-In.');
    }
  }

  /// Record the user's granular consents + 18+ confirmation (after Google
  /// sign-in). Returns `true` on success.
  static Future<bool> recordConsent({
    required bool consentHealthData,
    required bool consentCrossBorder,
    required bool isOver18,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users/me/consent');
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'consent_health_data': consentHealthData,
          'consent_cross_border': consentCrossBorder,
          'is_over_18': isOver18,
        }),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Whether the logged-in user still needs to complete the consent gate.
  /// Used on startup; fails open (returns false) so a logged-in user is never
  /// stranded by a transient network error.
  static Future<bool> needsConsent() async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users/me/consent');
    final token = await getToken();
    if (token == null) return false;
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['needs_consent'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Register a new account. Returns `true` on success.
  static Future<bool> register(
    String name,
    String email,
    String password, {
    required bool consentHealthData,
    required bool consentCrossBorder,
    required bool isOver18,
    String? genotype,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/users');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': name,
          'email': email,
          'password': password,
          'consent_health_data': consentHealthData,
          'consent_cross_border': consentCrossBorder,
          'is_over_18': isOver18,
          'bio_profile': {
            if (genotype != null && genotype.isNotEmpty) 'genotype': genotype,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Log out: stop pushes to this device, then clear the local session.
  ///
  /// Pass `unregisterDevice: false` after account deletion — the backend has
  /// already erased the device tokens, and calling it with the now-dead token
  /// would only produce a 401.
  static Future<void> logout({bool unregisterDevice = true}) async {
    // Needs the token that's about to be cleared, so it runs first.
    if (unregisterDevice) await PushService.unregister();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.authMethodKey);
    // Sign out of Google too, otherwise SessionManager's signInSilently() could
    // quietly sign the next person in as this account (or re-create a deleted one).
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
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
