import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_auth.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/api/api_http_client.dart';

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
    expect(client.uris, hasLength(13));
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
  });

  test('ApiCache can authenticate role before live init', () async {
    final client = RecordingApiHttpClient();
    ApiCache.instance.debugReset();
    ApiCache.instance.debugSetHttpClient(client);

    await ApiCache.instance.initWithRoleAuth('owner');

    expect(client.postUris, hasLength(1));
    expect(client.postUris.single.path, '/api/v1/auth/login');
    expect(client.uris, hasLength(13));
    expect(
      client.authHeaders.every((value) => value == 'Bearer jwt-token'),
      isTrue,
    );
    expect(ApiCache.instance.initialized, isTrue);
    expect(ApiCache.instance.lastLiveSource, 'api');
  });
}
