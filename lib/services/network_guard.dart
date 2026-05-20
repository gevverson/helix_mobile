import 'package:connectivity_plus/connectivity_plus.dart';

/// Thrown before any API call when the device has no network connection.
class NetworkOfflineException implements Exception {
  final String message;
  const NetworkOfflineException([
    this.message = 'No internet connection. Please check your network.',
  ]);

  @override
  String toString() => message;
}

/// Throws [NetworkOfflineException] if the device is currently offline.
///
/// Call this at the start of any operation that requires the network.
/// Used by [HelixApiInterceptor] so that every API call is guarded in
/// one place rather than duplicated across service methods.
class NetworkGuard {
  NetworkGuard._();

  static Future<void> check() async {
    final results = await Connectivity().checkConnectivity();
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (offline) throw const NetworkOfflineException();
  }
}
