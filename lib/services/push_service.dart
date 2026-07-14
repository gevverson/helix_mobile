import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Used to surface foreground notifications as a SnackBar without a BuildContext.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Top-level background handler. Notification messages are shown by the OS
/// automatically; this exists so data-only messages don't crash the isolate.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

/// Push notifications: permission, FCM token registration with the backend, and
/// foreground display. Safe to call [init] multiple times (e.g. every app open).
class PushService {
  static final _client = ApiClient.instance;
  static bool _wired = false;

  static Future<Map<String, String>?> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) return null;
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static String get _platform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }

  /// Request permission, register this device's token, and wire up listeners.
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) await _register(token);

      if (!_wired) {
        _wired = true;
        // Token can rotate — keep the backend in sync.
        messaging.onTokenRefresh.listen(_register);
        // Foreground messages: the OS won't show these, so we do.
        FirebaseMessaging.onMessage.listen(_showForeground);
      }
    } catch (_) {
      // Push is best-effort; never block the app if it fails.
    }
  }

  static Future<void> _register(String token) async {
    final headers = await _authHeaders();
    if (headers == null) return;
    try {
      await _client.post(
        Uri.parse('${AppConstants.baseUrl}/api/v1/users/me/devices'),
        headers: headers,
        body: jsonEncode({'token': token, 'platform': _platform}),
      );
    } catch (_) {}
  }

  /// Remove this device's token from the backend (call on logout).
  static Future<void> unregister() async {
    final headers = await _authHeaders();
    if (headers == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _client.delete(
        Uri.parse('${AppConstants.baseUrl}/api/v1/users/me/devices'),
        headers: headers,
        body: jsonEncode({'token': token}),
      );
    } catch (_) {}
  }

  static void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppConstants.bgCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((n.title ?? '').isNotEmpty)
              Text(n.title!,
                  style: const TextStyle(
                      color: AppConstants.textPrimary, fontWeight: FontWeight.w700)),
            if ((n.body ?? '').isNotEmpty)
              Text(n.body!, style: const TextStyle(color: AppConstants.textSecondary)),
          ],
        ),
      ),
    );
  }
}
