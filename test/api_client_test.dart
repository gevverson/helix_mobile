import 'package:flutter_test/flutter_test.dart';
import 'package:helix_mobile/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late int calls;

  IdempotentRetryClient clientReturning(int status) {
    calls = 0;
    return IdempotentRetryClient(
      MockClient((_) async {
        calls++;
        return http.Response('', status);
      }),
      delay: (_) => Duration.zero,
    );
  }

  final url = Uri.parse('http://x/api/v1/matches');

  test('GET is retried on 5xx (3 retries = 4 attempts)', () async {
    final res = await clientReturning(503).get(url);
    expect(res.statusCode, 503);
    expect(calls, 4);
  });

  test('DELETE is retried on 5xx', () async {
    await clientReturning(502).delete(url);
    expect(calls, 4);
  });

  test('POST is never retried — a retry would duplicate a message or like', () async {
    final res = await clientReturning(502).post(url, body: '{"body":"hi"}');
    expect(res.statusCode, 502);
    expect(calls, 1);
  });

  test('PATCH is never retried', () async {
    await clientReturning(500).patch(url, body: '{}');
    expect(calls, 1);
  });

  test('4xx is not retried', () async {
    await clientReturning(404).get(url);
    expect(calls, 1);
  });

  test('retries stop as soon as the server recovers', () async {
    calls = 0;
    final client = IdempotentRetryClient(
      MockClient((_) async => http.Response('', ++calls < 3 ? 503 : 200)),
      delay: (_) => Duration.zero,
    );
    final res = await client.get(url);
    expect(res.statusCode, 200);
    expect(calls, 3);
  });

  test('retry state is per request, not shared across the client', () async {
    final client = clientReturning(503);
    await client.get(url);
    await client.get(url);
    expect(calls, 8); // both requests got their full 3 retries
  });
}
