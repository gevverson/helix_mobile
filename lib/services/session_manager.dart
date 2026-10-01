import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

/// Handles JWT session lifecycle — detects expiry and attempts silent recovery.
///
/// When the API interceptor receives a 401 on an authenticated request:
///   1. [onUnauthorized] is called (fire-and-forget) with the token that was rejected.
///   2. If that token is no longer the stored one (the user logged out, or a
///      newer token was saved), the 401 is stale and is ignored.
///   3. Only a session that was started with Google is silently renewed: a
///      silent Google sign-in → `POST /auth/google` → new token saved. A
///      password session never is — otherwise a 401 could quietly sign the user
///      in as whatever Google account the device last used.
///   4. Otherwise the stored token is cleared and [sessionExpired] fires `true`.
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

  /// Called by [HelixApiInterceptor] on a 401 for a request sent with [rejectedToken].
  static Future<void> onUnauthorized(String rejectedToken) async {
    if (_isRefreshing) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(AppConstants.tokenKey) != rejectedToken) return;

    _isRefreshing = true;
    try {
      if (prefs.getString(AppConstants.authMethodKey) == 'google') {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          final auth = await account.authentication;
          if (auth.idToken != null) {
            final refreshed = await _reAuthWithBackend(auth.idToken!, rejectedToken);
            if (refreshed) return; // Session silently restored
          }
        }
      }
    } catch (_) {
      // Silent sign-in unavailable (Google error)
    } finally {
      _isRefreshing = false;
    }

    // Could not refresh — clear the stale session (unless it changed meanwhile)
    // and signal the UI.
    if (prefs.getString(AppConstants.tokenKey) != rejectedToken) return;
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.authMethodKey);
    sessionExpired.value = true;
  }

  /// Exchange a Google ID token for a new backend JWT and persist it — but only
  /// if the session is still the one that expired (the user may have logged out
  /// while this was in flight).
  static Future<bool> _reAuthWithBackend(String idToken, String rejectedToken) async {
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
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString(AppConstants.tokenKey) != rejectedToken) return false;
        await prefs.setString(AppConstants.tokenKey, token);
        if (kDebugMode) debugPrint('SessionManager: token silently refreshed');
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SessionManager: silent re-auth failed — $e');
    }
    return false;
  }
}
