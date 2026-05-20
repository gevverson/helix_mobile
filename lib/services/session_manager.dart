import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

/// Handles JWT session lifecycle — detects expiry and attempts silent recovery.
///
/// When the API interceptor receives a 401:
///   1. [onUnauthorized] is called (fire-and-forget from the interceptor).
///   2. It tries a silent Google Sign-In to get a fresh ID token.
///   3. If successful, it re-authenticates with the backend and saves the
///      new access token — the user notices nothing.
///   4. If silent re-auth fails (email/password user, or Google not available),
///      the stored token is cleared and [sessionExpired] fires `true`.
///
/// [MainShell] listens to [sessionExpired] and navigates to the login screen.
class SessionManager {
  SessionManager._();

  /// Fires `true` when the session has expired and could not be silently renewed.
  /// Reset to `false` after the listener has handled navigation.
  static final sessionExpired = ValueNotifier<bool>(false);

  static bool _isRefreshing = false;

  static final _googleSignIn = GoogleSignIn(
    serverClientId: AppConstants.googleClientId,
    scopes: ['email', 'profile'],
  );

  /// Called by [HelixApiInterceptor] on every 401 response.
  static Future<void> onUnauthorized() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      // Attempt silent Google re-authentication first
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.idToken != null) {
          final refreshed = await _reAuthWithBackend(auth.idToken!);
          if (refreshed) return; // Session silently restored
        }
      }
    } catch (_) {
      // Silent sign-in unavailable (email/password user, or Google error)
    } finally {
      _isRefreshing = false;
    }

    // Could not refresh — clear stale token and signal the UI
    await _clearToken();
    sessionExpired.value = true;
  }

  /// Exchange a Google ID token for a new backend JWT and persist it.
  static Future<bool> _reAuthWithBackend(String idToken) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/v1/auth/google');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': idToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String;
        await _saveToken(token);
        if (kDebugMode) debugPrint('SessionManager: token silently refreshed');
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SessionManager: silent re-auth failed — $e');
    }
    return false;
  }

  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }
}
