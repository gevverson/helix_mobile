import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

/// The single place the backend JWT is stored.
///
/// Kept in [FlutterSecureStorage] (Android Keystore-wrapped AES-GCM / iOS
/// Keychain), not SharedPreferences, which is a plaintext XML file readable from
/// backups and rooted devices. The token is cached in memory because a Keystore
/// read on every API call is slow.
///
/// Older builds kept the token in SharedPreferences; the first [read] moves it
/// across and deletes the plaintext copy, so existing users stay signed in.
class TokenStore {
  TokenStore._();

  static const _storage = FlutterSecureStorage();

  static String? _cached;
  static bool _loaded = false;

  static Future<String?> read() async {
    if (_loaded) return _cached;
    var token = await _storage.read(key: AppConstants.tokenKey);
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(AppConstants.tokenKey);
    if (legacy != null) {
      token ??= legacy;
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await prefs.remove(AppConstants.tokenKey);
    }
    _cached = token;
    _loaded = true;
    return token;
  }

  static Future<void> write(String token) async {
    _cached = token;
    _loaded = true;
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: AppConstants.tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey); // in case a legacy copy survived
  }

  /// Forget the in-memory cache (tests only).
  static void resetForTest() {
    _cached = null;
    _loaded = false;
  }
}
