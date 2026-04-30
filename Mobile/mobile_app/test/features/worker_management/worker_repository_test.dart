import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_auth.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/api/api_http_client.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/worker_management/data/live_worker_repository.dart';
import 'package:smart_livestock_demo/features/worker_management/data/mock_worker_repository.dart';

class WorkerApiHttpClient implements ApiHttpClient {
  WorkerApiHttpClient({
    this.activeFarmId = 'tenant_001',
    List<Map<String, dynamic>>? workerItems,
  }) : workerItems = workerItems ??
            [
              {
                'id': 'wfa_live_001',
                'userId': 'u_live_001',
                'userName': '缓存牧工',
                'role': 'worker',
                'assignedAt': '2026-04-30T10:00:00+08:00',
              },
            ];

  final String activeFarmId;
  final List<Map<String, dynamic>> workerItems;

  @override
  Future<ApiHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    return ApiHttpResponse(
      200,
      jsonEncode({
        'code': 'OK',
        'message': 'success',
        'requestId': 'req_worker_test',
        'data': _dataFor(uri.path),
      }),
      const {},
    );
  }

  @override
  Future<ApiHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return ApiHttpResponse(
      200,
      jsonEncode({
        'code': 'OK',
        'message': 'success',
        'requestId': 'req_auth',
        'data': {
          'accessToken': 'jwt-token',
          'refreshToken': 'refresh-token',
          'expiresAt': '2999-01-01T00:00:00.000Z',
        },
      }),
      const {},
    );
  }

  Map<String, dynamic> _dataFor(String path) {
    if (path.endsWith('/farm/my-farms')) {
      return {
        'activeFarmId': activeFarmId,
        'farms': [
          {'id': 'tenant_001', 'name': '华东示范牧场'},
          {'id': 'tenant_007', 'name': '张三的第二牧场'},
        ],
      };
    }
    if (path.endsWith('/workers')) {
      return {
        'items': workerItems,
      };
    }
    if (path.endsWith('/dashboard/summary')) return {'metrics': []};
    if (path.endsWith('/map/trajectories')) {
      return {'animals': [], 'points': []};
    }
    if (path.endsWith('/alerts') ||
        path.endsWith('/fences') ||
        path.endsWith('/tenants') ||
        path.endsWith('/devices') ||
        path.contains('/twin/')) {
      return {'items': []};
    }
    return {};
  }
}

void main() {
  setUp(() {
    MockWorkerRepository.resetForTesting();
  });

  tearDown(() {
    ApiCache.instance.debugReset();
    MockWorkerRepository.resetForTesting();
  });

  test('MockRepository 按 farmId 返回对应牧工分配', () {
    const repo = MockWorkerRepository();
    final farmOne = repo.load(viewState: ViewState.normal, farmId: 'tenant_001');
    final farmTwo = repo.load(viewState: ViewState.normal, farmId: 'tenant_007');

    expect(farmOne.viewState, ViewState.normal);
    expect(farmOne.message, isNull);
    expect(farmOne.items.map((item) => item.id), ['wfa_001']);
    expect(farmTwo.items.map((item) => item.id), ['wfa_002']);
    expect([...farmOne.items, ...farmTwo.items].every((item) => item.userName.contains('李四')), isTrue);
    expect([...farmOne.items, ...farmTwo.items].every((item) => item.role == 'worker'), isTrue);
  });

  test('MockRepository 非 normal 状态返回空列表和对应文案', () {
    const repo = MockWorkerRepository();
    final data = repo.load(viewState: ViewState.empty, farmId: 'tenant_001');

    expect(data.items, isEmpty);
    expect(data.message, '暂无牧工');
  });

  test('MockRepository assign 和 unassign 后 load 可见变化', () {
    const repo = MockWorkerRepository();

    expect(repo.assign('tenant_001', 'u_009'), isTrue);
    expect(repo.assign('tenant_001', 'u_009'), isFalse);

    final afterAssign = repo.load(viewState: ViewState.normal, farmId: 'tenant_001');
    final added = afterAssign.items.singleWhere((item) => item.userId == 'u_009');
    expect(added.role, 'worker');

    expect(repo.unassign(added.id), isTrue);
    expect(repo.unassign(added.id), isFalse);
    final afterUnassign = repo.load(viewState: ViewState.normal, farmId: 'tenant_001');
    expect(afterUnassign.items.any((item) => item.userId == 'u_009'), isFalse);
  });

  test('LiveRepository 未初始化时 fallback 到 MockRepository', () {
    const repo = LiveWorkerRepository();
    final data = repo.load(viewState: ViewState.normal, farmId: 'tenant_001');

    expect(data.items.map((item) => item.id), contains('wfa_001'));
  });

  test('LiveRepository 从 ApiCache.workers 解析牧工分配', () async {
    ApiCache.instance.debugSetHttpClient(WorkerApiHttpClient());
    await ApiCache.instance.init(
      'owner',
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
    );

    const repo = LiveWorkerRepository();
    final data = repo.load(viewState: ViewState.normal, farmId: 'tenant_001');

    expect(data.items, hasLength(1));
    expect(data.items.single.id, 'wfa_live_001');
    expect(data.items.single.userName, '缓存牧工');
  });

  test('LiveRepository 请求 farmId 与 workersFarmId 不一致时 fallback', () async {
    ApiCache.instance.debugSetHttpClient(WorkerApiHttpClient(activeFarmId: 'tenant_001'));
    await ApiCache.instance.init(
      'owner',
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
    );

    const repo = LiveWorkerRepository();
    final data = repo.load(viewState: ViewState.normal, farmId: 'tenant_007');

    expect(data.items.map((item) => item.id), ['wfa_002']);
    expect(data.items.any((item) => item.id == 'wfa_live_001'), isFalse);
  });

  test('LiveRepository malformed item 不抛异常并跳过无效 id/userId', () async {
    ApiCache.instance.debugSetHttpClient(WorkerApiHttpClient(workerItems: [
      {
        'id': 42,
        'userId': 'u_bad',
        'userName': '无效牧工',
        'role': 'worker',
        'assignedAt': '2026-04-30T10:00:00+08:00',
      },
      {
        'id': 'wfa_live_002',
        'userId': 'u_live_002',
        'userName': 99,
        'role': false,
        'assignedAt': null,
      },
    ]));
    await ApiCache.instance.init(
      'owner',
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
    );

    const repo = LiveWorkerRepository();
    final data = repo.load(viewState: ViewState.normal, farmId: 'tenant_001');

    expect(data.items, hasLength(1));
    expect(data.items.single.id, 'wfa_live_002');
    expect(data.items.single.userName, 'u_live_002');
    expect(data.items.single.role, 'worker');
    expect(data.items.single.assignedAt, '');
  });

  test('LiveRepository assign 和 unassign 更新当前 workers cache', () async {
    ApiCache.instance.debugSetHttpClient(WorkerApiHttpClient());
    await ApiCache.instance.init(
      'owner',
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
    );

    const repo = LiveWorkerRepository();

    expect(repo.assign('tenant_001', 'u_live_added', role: 'worker'), isTrue);
    expect(repo.assign('tenant_001', 'u_live_added', role: 'worker'), isFalse);

    final afterAssign = repo.load(viewState: ViewState.normal, farmId: 'tenant_001');
    final added = afterAssign.items.singleWhere((item) => item.userId == 'u_live_added');
    expect(added.role, 'worker');

    expect(repo.unassign(added.id), isTrue);
    expect(repo.unassign(added.id), isFalse);

    final afterUnassign = repo.load(viewState: ViewState.normal, farmId: 'tenant_001');
    expect(afterUnassign.items.any((item) => item.userId == 'u_live_added'), isFalse);
  });

  test('LiveRepository cache 缺失或 farm 不匹配时写操作返回 false', () async {
    const repo = LiveWorkerRepository();

    expect(repo.assign('tenant_001', 'u_no_cache'), isFalse);
    expect(repo.unassign('wfa_no_cache'), isFalse);

    ApiCache.instance.debugSetHttpClient(WorkerApiHttpClient(activeFarmId: 'tenant_001'));
    await ApiCache.instance.init(
      'owner',
      tokens: const ApiAuthTokens(accessToken: 'jwt-token'),
    );

    expect(repo.assign('tenant_007', 'u_wrong_farm'), isFalse);
  });
}
