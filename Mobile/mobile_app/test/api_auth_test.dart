import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_auth.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';

void main() {
  test('apiHeaders prefers access token', () {
    final headers = apiHeaders(
      role: DemoRole.owner,
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
    );
    expect(headers['Authorization'], 'Bearer jwt-token');
  });

  test('apiHeaders can use mock token fallback', () {
    final headers = apiHeaders(role: DemoRole.worker);
    expect(headers['Authorization'], isNull);
  });

  test('apiHeaders uses mock token only when fallback is enabled', () {
    final headers = apiHeaders(
      role: DemoRole.worker,
      allowMockTokenFallback: true,
    );
    expect(headers['Authorization'], 'Bearer mock-token-worker');
  });

  test('ApiCache headers use token helper semantics', () {
    final headers = ApiCache.headersForTesting(
      role: DemoRole.owner,
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
    );
    expect(headers['Authorization'], 'Bearer jwt-token');
  });

  test('ApiCache headers do not send mock-token when fallback is disabled', () {
    final headers = ApiCache.headersForTesting(role: DemoRole.owner);
    expect(headers['Authorization'], isNull);
  });
}
