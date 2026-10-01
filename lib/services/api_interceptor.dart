import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'network_guard.dart';
import 'session_manager.dart';

class HelixApiInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    // Connectivity guard — fail fast with a user-friendly error before
    // the OS has a chance to queue a TCP timeout
    final results = await Connectivity().checkConnectivity();
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      throw const NetworkOfflineException();
    }

    if (kDebugMode) debugPrint('API ▶ ${request.method} ${request.url}');

    request.headers[HttpHeaders.userAgentHeader] =
        'Mozilla/5.0 (Linux; Android) HelixApp/1.0';
    request.headers[HttpHeaders.acceptHeader] = 'application/json';
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    if (kDebugMode) {
      debugPrint('API ◀ ${response.statusCode} ${response.request?.url}');
    }

    // Detect token expiry — fire async so the 401 response still propagates
    // to the calling service method immediately. Only authenticated requests
    // count: a 401 from /auth/token just means a wrong password.
    if (response.statusCode == 401) {
      final auth = response.request?.headers[HttpHeaders.authorizationHeader];
      if (auth != null && auth.startsWith('Bearer ')) {
        SessionManager.onUnauthorized(auth.substring(7)); // intentionally unawaited
      }
    }

    return response;
  }
}
