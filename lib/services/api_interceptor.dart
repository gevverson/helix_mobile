import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http_interceptor/http_interceptor.dart';

class HelixApiInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    if (kDebugMode) {
      debugPrint('API ▶ ${request.method} ${request.url}');
    }
    // Custom User-Agent to pass restrictive Cloudflare/Render firewall rules
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
      if (response.statusCode >= 400) {
        // Log status only — never log body in case it echoes sensitive input
        debugPrint('API error: HTTP ${response.statusCode}');
      }
    }
    return response;
  }
}

class HelixRetryPolicy extends RetryPolicy {
  @override
  int get maxRetryAttempts => 3;

  @override
  Future<bool> shouldAttemptRetryOnResponse(BaseResponse response) async {
    return response.statusCode >= 500;
  }

  @override
  Future<bool> shouldAttemptRetryOnException(
    Exception reason,
    BaseRequest request,
  ) async {
    // Fail fast on DNS/offline — no point retrying without a connection
    if (reason is SocketException) return false;
    return true;
  }
}
