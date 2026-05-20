import 'package:flutter/material.dart';

/// Centralized app-wide constants.
///
/// Use flavor files with --dart-define-from-file instead of individual flags:
/// ```
/// flutter run  --dart-define-from-file=flavors/dev.json
/// flutter run  --dart-define-from-file=flavors/staging.json
/// flutter build apk --dart-define-from-file=flavors/prod.json
/// ```
/// See .vscode/launch.json for pre-configured VS Code run configurations.
class AppConstants {
  AppConstants._(); // Prevent instantiation

  /// Backend API base URL — injected at compile time from flavor JSON.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Google OAuth server client ID — injected at compile time from flavor JSON.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  /// Active flavor: 'dev' | 'staging' | 'prod'
  static const String flavor = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'dev',
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
