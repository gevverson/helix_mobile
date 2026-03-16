import 'package:http_interceptor/http_interceptor.dart';
import 'dart:io';

class HelixApiInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    print('API REQUEST: ${request.method} ${request.url}');
    // Add custom User-Agent to bypass restrictive firewalls/Cloudflare on Render
    request.headers[HttpHeaders.userAgentHeader] = 'Mozilla/5.0 (Linux; Android) HelixApp/1.0';
    request.headers[HttpHeaders.acceptHeader] = 'application/json';
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    print('API RESPONSE: ${response.statusCode} (${response.request?.url})');
    if (response.statusCode >= 400 && response is Response) {
      print('API ERROR BODY: ${response.body}');
    }
    return response;
  }
}

class HelixRetryPolicy extends RetryPolicy {
  @override
  int get maxRetryAttempts => 3;

  @override
  Future<bool> shouldAttemptRetryOnResponse(BaseResponse response) async {
    if (response.statusCode >= 500) {
      return true;
    }
    return false;
  }

  @override
  Future<bool> shouldAttemptRetryOnException(Exception reason, BaseRequest request) async {
    // Do not retry on pure DNS/Offline issues so the app fails fast instead of hanging
    if (reason is SocketException) {
      return false;
    }
    // Retry on network abortion/timeout exceptions
    return true; 
  }
}
