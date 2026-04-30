import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_auth.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/api/api_http_client.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';

void main() {
  tearDown(() {
    ApiCache.instance.debugReset();
  });

  test('owner loads farm data and does not request b2b endpoints', () async {
    final client = _RecordingApiHttpClient();
    ApiCache.instance.debugSetHttpClient(client);

    await ApiCache.instance.init(
      DemoRole.owner.wireName,
      allowMockTokenFallback: true,
    );

    expect(client.paths, contains('/farm/my-farms'));
    expect(client.paths, contains('/farms/tenant_007/workers'));
    expect(client.paths, isNot(contains('/b2b/dashboard')));
    expect(client.paths, isNot(contains('/b2b/contract/current')));
    expect(ApiCache.instance.myFarms?['activeFarmId'], 'tenant_007');
    expect(ApiCache.instance.workers?['items'], isA<List>());
  });

  test('worker loads farms without workers or b2b endpoints', () async {
    final client = _RecordingApiHttpClient();
    ApiCache.instance.debugSetHttpClient(client);

    await ApiCache.instance.init(
      DemoRole.worker.wireName,
      allowMockTokenFallback: true,
    );

    expect(client.paths, contains('/farm/my-farms'));
    expect(client.paths, isNot(contains('/farms/tenant_007/workers')));
    expect(client.paths, isNot(contains('/b2b/dashboard')));
    expect(client.paths, isNot(contains('/b2b/contract/current')));
  });

  test('b2b admin loads b2b data without farm endpoints', () async {
    final client = _RecordingApiHttpClient();
    ApiCache.instance.debugSetHttpClient(client);

    await ApiCache.instance.init(
      DemoRole.b2bAdmin.wireName,
      allowMockTokenFallback: true,
    );

    expect(client.paths, isNot(contains('/farm/my-farms')));
    expect(client.paths, isNot(contains('/farms/tenant_007/workers')));
    expect(client.paths, contains('/b2b/dashboard'));
    expect(client.paths, contains('/b2b/contract/current'));
    expect(ApiCache.instance.b2bDashboard?['activeContracts'], 2);
    expect(ApiCache.instance.b2bContract?['id'], 'contract_001');
  });

  test('debugReset clears tenant detail caches', () async {
    final client = _RecordingApiHttpClient();
    ApiCache.instance.debugSetHttpClient(client);

    await ApiCache.instance.fetchTenantDevices(
      DemoRole.platformAdmin.wireName,
      'tenant_001',
      allowMockTokenFallback: true,
    );
    await ApiCache.instance.fetchTenantLogs(
      DemoRole.platformAdmin.wireName,
      'tenant_001',
      allowMockTokenFallback: true,
    );
    await ApiCache.instance.fetchTenantStats(
      DemoRole.platformAdmin.wireName,
      'tenant_001',
      allowMockTokenFallback: true,
    );

    expect(ApiCache.instance.tenantDevices('tenant_001'), isNotNull);
    expect(ApiCache.instance.tenantLogs('tenant_001'), isNotNull);
    expect(ApiCache.instance.tenantStats('tenant_001'), isNotNull);

    ApiCache.instance.debugReset();

    expect(ApiCache.instance.tenantDevices('tenant_001'), isNull);
    expect(ApiCache.instance.tenantLogs('tenant_001'), isNull);
    expect(ApiCache.instance.tenantStats('tenant_001'), isNull);
  });

  test('older failed init does not clear newer successful role cache', () async {
    final client = _RacingApiHttpClient();
    ApiCache.instance.debugSetHttpClient(client);

    final oldInit = ApiCache.instance.init(
      DemoRole.owner.wireName,
      tokens: const ApiAuthTokens(accessToken: 'owner-token'),
    );
    await client.waitForOwnerRequest();

    await ApiCache.instance.init(
      DemoRole.b2bAdmin.wireName,
      tokens: const ApiAuthTokens(accessToken: 'b2b-token'),
    );
    client.failOwnerRequests();
    await oldInit;

    expect(ApiCache.instance.b2bDashboard?['activeContracts'], 2);
    expect(ApiCache.instance.b2bContract?['id'], 'contract_001');
    expect(ApiCache.instance.myFarms, isNull);
  });
}

class _RecordingApiHttpClient implements ApiHttpClient {
  final List<String> paths = [];

  @override
  Future<ApiHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    paths.add(uri.path.replaceFirst('/api/v1', ''));
    return ApiHttpResponse(200, jsonEncode({'code': 'OK', 'data': _data(uri)}), {
      'content-type': 'application/json',
    });
  }

  @override
  Future<ApiHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw UnimplementedError();
  }

  Map<String, dynamic> _data(Uri uri) {
    final path = uri.path.replaceFirst('/api/v1', '');
    return switch (path) {
      '/dashboard/summary' => {
          'metrics': [],
        },
      '/map/trajectories' => {
          'animals': [],
          'points': [],
        },
      '/alerts' || '/fences' || '/tenants' => {
          'items': [],
        },
      '/profile' => {
          'name': '测试用户',
        },
      '/twin/overview' ||
      '/twin/epidemic/summary' ||
      '/subscription/current' ||
      '/subscription/features' ||
      '/subscription/usage' =>
        {},
      '/twin/fever/list' ||
      '/twin/digestive/list' ||
      '/twin/estrus/list' ||
      '/twin/epidemic/contacts' ||
      '/devices' ||
      '/subscription/plans' ||
      '/tenants/tenant_001/devices' ||
      '/tenants/tenant_001/logs' ||
      '/farms/tenant_007/workers' =>
        {
          'items': [],
        },
      '/tenants/tenant_001/stats' => {
          'animalTotal': 10,
        },
      '/farm/my-farms' => {
          'activeFarmId': 'tenant_007',
          'farms': [
            {'id': 'tenant_001', 'name': '青山牧场', 'status': 'active'},
            {'id': 'tenant_007', 'name': '河谷牧场', 'status': 'active'},
          ],
        },
      '/b2b/dashboard' => {
          'activeContracts': 2,
        },
      '/b2b/contract/current' => {
          'id': 'contract_001',
        },
      _ => {},
    };
  }
}

class _RacingApiHttpClient implements ApiHttpClient {
  final _ownerStarted = Completer<void>();
  final _releaseOwner = Completer<void>();

  Future<void> waitForOwnerRequest() => _ownerStarted.future;

  void failOwnerRequests() {
    if (!_releaseOwner.isCompleted) {
      _releaseOwner.complete();
    }
  }

  @override
  Future<ApiHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    final token = headers?['Authorization'] ?? '';
    if (token.contains('owner-token')) {
      if (!_ownerStarted.isCompleted) {
        _ownerStarted.complete();
      }
      await _releaseOwner.future;
      throw Exception('stale owner request failed');
    }
    return ApiHttpResponse(200, jsonEncode({'code': 'OK', 'data': _data(uri)}), {
      'content-type': 'application/json',
    });
  }

  @override
  Future<ApiHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw UnimplementedError();
  }

  Map<String, dynamic> _data(Uri uri) {
    final path = uri.path.replaceFirst('/api/v1', '');
    return switch (path) {
      '/dashboard/summary' => {
          'metrics': [],
        },
      '/map/trajectories' => {
          'animals': [],
          'points': [],
        },
      '/alerts' ||
      '/fences' ||
      '/tenants' ||
      '/twin/fever/list' ||
      '/twin/digestive/list' ||
      '/twin/estrus/list' ||
      '/twin/epidemic/contacts' ||
      '/devices' ||
      '/subscription/plans' =>
        {
          'items': [],
        },
      '/profile' => {
          'name': 'B端管理员',
        },
      '/twin/overview' ||
      '/twin/epidemic/summary' ||
      '/subscription/current' ||
      '/subscription/features' ||
      '/subscription/usage' =>
        {},
      '/b2b/dashboard' => {
          'activeContracts': 2,
        },
      '/b2b/contract/current' => {
          'id': 'contract_001',
        },
      _ => {},
    };
  }
}
