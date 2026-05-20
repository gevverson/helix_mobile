import 'package:flutter/material.dart';

/// Centralized app-wide constants.
///
/// Pass environment at build/run time via --dart-define:
/// ```
/// flutter run  --dart-define=API_BASE_URL=http://10.0.2.2:8000
/// flutter build apk --dart-define=API_BASE_URL=https://helix-api-wc16.onrender.com
///                   --dart-define=GOOGLE_CLIENT_ID=YOUR_CLIENT_ID
/// ```
class AppConstants {
  AppConstants._(); // Prevent instantiation

  /// Backend API base URL — injected at compile time via --dart-define=API_BASE_URL.
  /// Default targets the Android emulator loopback; override for real devices and production.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Google OAuth server client ID — injected at compile time via --dart-define=GOOGLE_CLIENT_ID.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const String appName = 'Helix';
  static const String appVersion = '1.0.0';

  // SharedPreferences keys
  static const String tokenKey = 'auth_token';

  // ── Color Palette ──────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFF0D1117);
  static const Color bgSecondary = Color(0xFF161B22);
  static const Color bgCard = Color(0xFF1C2333);
  static const Color bgElevated = Color(0xFF21283B);

  static const Color accentCyan = Color(0xFF00D4AA);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPink = Color(0xFFEC4899);

  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);

  static const Color borderColor = Color(0xFF30363D);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF00D4AA);
  static const Color warningColor = Color(0xFFFBBF24);

  // ── Gradients ──────────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentCyan, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [accentPurple, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [bgPrimary, bgSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
