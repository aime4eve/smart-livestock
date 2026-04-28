import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_auth.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/api/api_http_client.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/data/live_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/data/live_dashboard_repository.dart';
import 'package:smart_livestock_demo/features/fence/data/live_fence_repository.dart';
import 'package:smart_livestock_demo/features/tenant/data/live_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';

class RecordingApiHttpClient implements ApiHttpClient {
  final uris = <Uri>[];
  final postUris = <Uri>[];
  final authHeaders = <String?>[];

  @override
  Future<ApiHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    uris.add(uri);
    authHeaders.add(headers?['Authorization']);
    return ApiHttpResponse(
      200,
      jsonEncode({
        'code': 'OK',
        'message': 'success',
        'requestId': 'req_test',
        'data': _dataFor(uri.path),
      }),
      {'x-api-version': 'v1'},
    );
  }

  @override
  Future<ApiHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    postUris.add(uri);
    return ApiHttpResponse(
      200,
      jsonEncode({
        'code': 'OK',
        'message': 'success',
        'requestId': 'req_auth',
        'data': {
          'token': 'mock-token-owner',
          'role': 'owner',
          'accessToken': 'jwt-token',
          'refreshToken': 'refresh-token',
          'expiresAt': '2999-01-01T00:00:00.000Z',
          'user': {'role': 'owner'},
        },
      }),
      {'x-api-version': 'v1'},
    );
  }

  Map<String, dynamic> _dataFor(String path) {
    if (path.endsWith('/dashboard/summary')) {
      return {
        'metrics': [
          {'id': 'metric_001'},
        ],
      };
    }
    if (path.endsWith('/map/trajectories')) {
      return {
        'animals': [
          {'id': 'animal_001'},
        ],
        'points': [
          {'id': 'point_001'},
        ],
      };
    }
    if (path.endsWith('/alerts') ||
        path.endsWith('/fences') ||
        path.endsWith('/tenants') ||
        path.endsWith('/devices')) {
      return {
        'items': [
          {'id': 'item_001'},
        ],
        'page': 1,
        'pageSize': 20,
        'total': 1,
      };
    }
    if (path.contains('/twin/') &&
        !path.endsWith('/overview') &&
        !path.endsWith('/summary')) {
      return {
        'items': [
          {'id': 'twin_item_001'},
        ],
      };
    }
    return {'id': 'object_001'};
  }
}

class FailingApiHttpClient implements ApiHttpClient {
  @override
  Future<ApiHttpResponse> get(Uri uri, {Map<String, String>? headers}) {
    throw Exception('network down');
  }

  @override
  Future<ApiHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw Exception('network down');
  }
}

class FailingAuthApiHttpClient extends RecordingApiHttpClient {
  @override
  Future<ApiHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw Exception('auth down');
  }
}

void main() {
  test('ApiCache live init requests v1 endpoints with access token', () async {
    final client = RecordingApiHttpClient();
    ApiCache.instance.debugReset();
    ApiCache.instance.debugSetHttpClient(client);

    await ApiCache.instance.init(
      'owner',
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
      allowMockTokenFallback: false,
    );

    final requestedPaths = client.uris.map((uri) {
      return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    });

    expect(client.uris, isNotEmpty);
    expect(client.uris, hasLength(17));
    expect(
      requestedPaths,
      containsAll([
        '/api/v1/dashboard/summary',
        '/api/v1/map/trajectories?animalId=animal_001&range=24h',
        '/api/v1/alerts?pageSize=100',
        '/api/v1/fences?pageSize=100',
        '/api/v1/tenants?pageSize=100',
        '/api/v1/profile',
        '/api/v1/twin/overview',
        '/api/v1/twin/fever/list',
        '/api/v1/twin/digestive/list',
        '/api/v1/twin/estrus/list',
        '/api/v1/twin/epidemic/summary',
        '/api/v1/twin/epidemic/contacts',
        '/api/v1/devices?pageSize=200',
        '/api/v1/subscription/current',
        '/api/v1/subscription/features',
        '/api/v1/subscription/plans',
        '/api/v1/subscription/usage',
      ]),
    );
    expect(client.uris.every((uri) => uri.path.startsWith('/api/v1/')), isTrue);
    expect(
      client.authHeaders.every((value) => value == 'Bearer jwt-token'),
      isTrue,
    );
    expect(ApiCache.instance.initialized, isTrue);
    expect(ApiCache.instance.lastLiveSource, 'api');

    ApiCache.instance.debugReset();
    expect(ApiCache.instance.initialized, isFalse);
    expect(ApiCache.instance.lastLiveSource, isNull);
    expect(ApiCache.instance.dashboardMetrics, isEmpty);
    expect(ApiCache.instance.animals, isEmpty);
    expect(ApiCache.instance.mapTrajectoryPoints, isEmpty);
    expect(ApiCache.instance.alerts, isEmpty);
    expect(ApiCache.instance.fences, isEmpty);
    expect(ApiCache.instance.tenants, isEmpty);
    expect(ApiCache.instance.profile, isNull);
    expect(ApiCache.instance.twinOverview, isNull);
    expect(ApiCache.instance.feverList, isEmpty);
    expect(ApiCache.instance.digestiveList, isEmpty);
    expect(ApiCache.instance.estrusList, isEmpty);
    expect(ApiCache.instance.epidemicSummary, isNull);
    expect(ApiCache.instance.epidemicContacts, isEmpty);
    expect(ApiCache.instance.devices, isEmpty);
    expect(ApiCache.instance.subscriptionCurrent, isNull);
    expect(ApiCache.instance.subscriptionPlans, isNull);
    expect(ApiCache.instance.subscriptionFeatures, isNull);
    expect(ApiCache.instance.subscriptionUsage, isNull);
  });

  test('ApiCache can authenticate role before live init', () async {
    final client = RecordingApiHttpClient();
    ApiCache.instance.debugReset();
    ApiCache.instance.debugSetHttpClient(client);

    await ApiCache.instance.initWithRoleAuth('owner');

    expect(client.postUris, hasLength(1));
    expect(client.postUris.single.path, '/api/v1/auth/login');
    expect(client.uris, hasLength(17));
    expect(
      client.authHeaders.every((value) => value == 'Bearer jwt-token'),
      isTrue,
    );
    expect(ApiCache.instance.initialized, isTrue);
    expect(ApiCache.instance.lastLiveSource, 'api');
  });

  test('ApiCache clears live source when role auth fails', () async {
    final okClient = RecordingApiHttpClient();
    ApiCache.instance.debugReset();
    ApiCache.instance.debugSetHttpClient(okClient);
    await ApiCache.instance.initWithRoleAuth('owner');
    expect(ApiCache.instance.initialized, isTrue);
    expect(ApiCache.instance.lastLiveSource, 'api');

    ApiCache.instance.debugSetHttpClient(FailingAuthApiHttpClient());
    await ApiCache.instance.initWithRoleAuth('owner');

    expect(ApiCache.instance.initialized, isFalse);
    expect(ApiCache.instance.lastLiveSource, isNull);
  });

  test('ApiCache clears live source when init fails', () async {
    final okClient = RecordingApiHttpClient();
    ApiCache.instance.debugReset();
    ApiCache.instance.debugSetHttpClient(okClient);
    await ApiCache.instance.init(
      'owner',
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
    );
    expect(ApiCache.instance.initialized, isTrue);
    expect(ApiCache.instance.lastLiveSource, 'api');

    ApiCache.instance.debugSetHttpClient(FailingApiHttpClient());
    await ApiCache.instance.init(
      'owner',
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
    );

    expect(ApiCache.instance.initialized, isFalse);
    expect(ApiCache.instance.lastLiveSource, isNull);
  });

  test('core live repositories do not silently fallback to mock data', () {
    ApiCache.instance.debugReset();

    final dashboard = const LiveDashboardRepository().load(ViewState.normal);
    expect(dashboard.viewState, ViewState.error);
    expect(dashboard.metrics, isEmpty);

    final tenants = LiveTenantRepository().loadList(const TenantListQuery());
    expect(tenants.viewState, ViewState.error);
    expect(tenants.tenants, isEmpty);

    final tenantDetail = LiveTenantRepository().loadDetail('tenant_001');
    expect(tenantDetail.viewState, ViewState.error);
    expect(tenantDetail.tenant, isNull);

    final fences = const LiveFenceRepository().loadAll();
    expect(fences, isEmpty);

    final alerts = const LiveAlertsRepository().load(
      viewState: ViewState.normal,
      role: DemoRole.owner,
      stage: AlertStage.pending,
    );
    expect(alerts.viewState, ViewState.error);
    expect(alerts.items, isEmpty);
  });
}
