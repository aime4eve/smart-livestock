import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';

void main() {
  test('resolveApiBaseUrl defaults to versioned API', () {
    expect(resolveApiBaseUrl(), contains('/api/v1'));
  });

  test('ApiCache starts without mock fallback source marker', () {
    ApiCache.instance.debugReset();
    expect(ApiCache.instance.lastLiveSource, isNull);
  });
}
