import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'api_interceptor.dart';

/// Shared HTTP client for all Helix API calls.
///
/// Connectivity checks, request logging and 401 session-expiry detection are
/// wired in via [HelixApiInterceptor]; retries happen underneath it in
/// [IdempotentRetryClient]. Every service uses this singleton so every request
/// goes through the same pipeline.
class ApiClient {
  ApiClient._();

  static final InterceptedClient instance = InterceptedClient.build(
    interceptors: [HelixApiInterceptor()],
    client: IdempotentRetryClient(http.Client()),
  );
}

/// Retries **idempotent** requests (GET/HEAD/PUT/DELETE) on a 5xx or a
/// transient error, with backoff — e.g. while the free Render instance wakes up.
///
/// POST and PATCH are never retried: if the first attempt reached the server
/// (a 502 from the proxy doesn't prove it didn't), a retry sends a second
/// message, like or registration. Multipart uploads can't be re-sent anyway.
///
/// Built on package:http's [RetryClient], which keeps no state between
/// requests (http_interceptor's RetryPolicy shares one retry counter across
/// every request on the client, and never resets it after a failure).
class IdempotentRetryClient extends http.BaseClient {
  IdempotentRetryClient(
    this._inner, {
    int retries = 3,
    Duration Function(int retryCount)? delay,
  }) : _retrying = RetryClient(
          _inner,
          retries: retries,
          when: (response) => response.statusCode >= 500,
          // A SocketException means no route to the server — tell the user now
          // rather than after several retries.
          whenError: (error, _) => error is! SocketException,
          delay: delay ?? (retryCount) => Duration(milliseconds: 500 * (1 << retryCount)),
        );

  static const _idempotent = {'GET', 'HEAD', 'PUT', 'DELETE', 'OPTIONS'};

  final http.Client _inner;
  final RetryClient _retrying;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _idempotent.contains(request.method.toUpperCase())
        ? _retrying.send(request)
        : _inner.send(request);
  }

  @override
  void close() => _retrying.close(); // also closes _inner
}
