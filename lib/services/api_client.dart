import 'package:http_interceptor/http_interceptor.dart';
import 'api_interceptor.dart';

/// Shared HTTP client for all Helix API calls.
///
/// Connectivity checks, request logging, retry-on-5xx, and 401 session-expiry
/// detection are all wired in via [HelixApiInterceptor] and [HelixRetryPolicy].
/// Both [AuthService] and [ProfileService] use this singleton so every request
/// goes through the same pipeline.
class ApiClient {
  ApiClient._();

  static final InterceptedClient instance = InterceptedClient.build(
    interceptors: [HelixApiInterceptor()],
    retryPolicy: HelixRetryPolicy(),
  );
}
