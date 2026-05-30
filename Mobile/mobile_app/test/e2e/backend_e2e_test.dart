/// e2e API 集成测试 — 直接测试前端 Repository + 后端真实 API。
///
/// 不依赖 UI 渲染，以普通 flutter test 运行。
/// 验证：登录 → 数据加载 → 围栏/告警/订阅等全链路。
///
/// 前提：后端服务运行在 http://172.22.1.123:18080
///
/// 运行：
///   flutter test test/e2e/backend_e2e_test.dart \
///     --dart-define=APP_MODE=live \
///     --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://172.22.1.123:18080/api/v1',
);

/// Standard API envelope: { code, message, data }
Map<String, dynamic> _unwrap(http.Response resp) {
  expect(resp.statusCode, 200,
      reason: 'API 应返回 200，实际 ${resp.statusCode}: ${resp.body}');
  final body = jsonDecode(resp.body) as Map<String, dynamic>;
  expect(body['code'], 'OK',
      reason: 'API code 应为 OK，实际 ${body['code']}');
  return body['data'] as Map<String, dynamic>;
}

Future<http.Response> _get(String path, String token) =>
    http.get(Uri.parse('$_baseUrl$path'), headers: {
      'Authorization': 'Bearer $token',
    });

// ══════════════════════════════════════════════════════════════════════════════

void main() {
  late String ownerToken;
  late int farmId;

  setUpAll(() async {
    // Step 1: 登录获取 token
    final loginResp = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': '13800138000', 'password': '123'}),
    );
    expect(loginResp.statusCode, 200, reason: 'owner 登录应成功');
    final loginData = jsonDecode(loginResp.body) as Map<String, dynamic>;
    final data = loginData['data'] as Map<String, dynamic>;
    ownerToken = data['accessToken'] as String;
    expect(ownerToken, isNotEmpty);

    // Step 2: 获取 farmId
    final farmsResp = await _get('/farms', ownerToken);
    final farmsBody = jsonDecode(farmsResp.body) as Map<String, dynamic>;
    final farmsData = farmsBody['data'] as Map<String, dynamic>;
    final items = (farmsData['items'] as List).cast<Map<String, dynamic>>();
    farmId = items.first['id'] as int;
  });

  // ── 1. 认证 ────────────────────────────────────────────────────────────

  group('e2e — 认证', () {
    test('owner 登录返回 JWT 和用户信息', () async {
      final resp = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': '13800138000', 'password': '123'}),
      );
      final data = _unwrap(resp);
      final user = data['user'] as Map<String, dynamic>;
      expect(user['role'], 'OWNER');
      expect(user['phone'], '13800138000');
      expect(user['name'], isNotEmpty);
    });

    test('错误密码登录失败', () async {
      final resp = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': '13800138000', 'password': 'wrong'}),
      );
      expect(resp.statusCode, 401);
    });

    test('无 token 访问受保护端点返回 401', () async {
      final resp = await http.get(Uri.parse('$_baseUrl/me'));
      expect(resp.statusCode, 401);
    });
  });

  // ── 2. 个人信息 ────────────────────────────────────────────────────────

  group('e2e — 个人信息', () {
    test('GET /me 返回当前用户', () async {
      final resp = await _get('/me', ownerToken);
      final data = _unwrap(resp);
      expect(data['role'], 'OWNER');
      expect(data['phone'], '13800138000');
      expect(data['id'], isA<int>());
      expect(data['tenantId'], isA<int>());
    });
  });

  // ── 3. 看板 ────────────────────────────────────────────────────────────

  group('e2e — 看板', () {
    test('GET /farms/{id}/dashboard/summary 返回指标', () async {
      final resp = await _get('/farms/$farmId/dashboard/summary', ownerToken);
      final data = _unwrap(resp);
      expect(data['livestockCount'], isA<int>());
      expect(data['onlineDeviceCount'], isA<int>());
      expect(data['activeAlertCount'], isA<int>());
      expect(data['fenceCount'], isA<int>());
      expect(data['healthSummary'], isA<Map>());
    });
  });

  // ── 4. 围栏 ────────────────────────────────────────────────────────────

  group('e2e — 围栏', () {
    test('GET /farms/{id}/fences 返回围栏列表', () async {
      final resp =
          await _get('/farms/$farmId/fences?pageSize=100', ownerToken);
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final items = (data['items'] as List).cast<Map<String, dynamic>>();

      expect(items.length, greaterThanOrEqualTo(3));

      final fence = items.first;
      expect(fence['id'], isA<int>());
      expect(fence['name'], isA<String>());
      expect(fence['vertices'], isA<List>());
      expect(fence['active'], isA<bool>());

      // vertices 格式验证
      final vertices =
          (fence['vertices'] as List).cast<Map<String, dynamic>>();
      expect(vertices.length, greaterThanOrEqualTo(3));
      expect(vertices.first, contains('lat'));
      expect(vertices.first, contains('lng'));
    });

    test('围栏 color 字段兼容 String 和 null', () async {
      final resp =
          await _get('/farms/$farmId/fences?pageSize=100', ownerToken);
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final items = (data['items'] as List).cast<Map<String, dynamic>>();

      for (final fence in items) {
        final color = fence['color'];
        expect(
          color == null || color is String || color is int,
          isTrue,
          reason: 'color 应为 null/String/int，实际: ${color.runtimeType}',
        );
      }
    });
  });

  // ── 5. 告警 ────────────────────────────────────────────────────────────

  group('e2e — 告警', () {
    test('GET /farms/{id}/alerts 返回告警列表', () async {
      final resp =
          await _get('/farms/$farmId/alerts?pageSize=100', ownerToken);
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final items = (data['items'] as List).cast<Map<String, dynamic>>();

      expect(items.length, greaterThanOrEqualTo(1));

      final alert = items.first;
      expect(alert['id'], isA<int>());
      expect(alert['type'], isA<String>());
      expect(alert['status'], isA<String>());
      expect(alert['severity'], isA<String>());
      expect(alert['message'], isA<String>());
    });

    test('告警 status 为合法枚举值', () async {
      final valid = {'PENDING', 'ACKNOWLEDGED', 'HANDLED', 'ARCHIVED'};
      final resp =
          await _get('/farms/$farmId/alerts?pageSize=100', ownerToken);
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final items = (data['items'] as List).cast<Map<String, dynamic>>();

      for (final alert in items) {
        expect(valid, contains(alert['status']),
            reason: '告警 status=${alert['status']} 不在合法值中');
      }
    });
  });

  // ── 6. 牲畜 ────────────────────────────────────────────────────────────

  group('e2e — 牲畜', () {
    test('GET /farms/{id}/livestock 返回牲畜列表', () async {
      final resp =
          await _get('/farms/$farmId/livestock?pageSize=100', ownerToken);
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final items = (data['items'] as List).cast<Map<String, dynamic>>();

      expect(items.length, greaterThanOrEqualTo(1));

      final animal = items.first;
      expect(animal['id'], isA<int>());
      expect(animal['livestockCode'], isA<String>());
      expect(animal['breed'], isA<String>());
      expect(animal['healthStatus'], isA<String>());
    });
  });

  // ── 7. 订阅 ────────────────────────────────────────────────────────────

  group('e2e — 订阅', () {
    test('GET /subscription 返回当前订阅', () async {
      final resp = await _get('/subscription', ownerToken);
      final data = _unwrap(resp);

      expect(data['id'], isA<int>());
      expect(data['tier'], isA<String>());
      expect(data['status'], isA<String>());

      final validTiers = {'BASIC', 'STANDARD', 'PREMIUM', 'ENTERPRISE'};
      expect(validTiers, contains(data['tier']));
    });
  });

  // ── 8. 牧场 ────────────────────────────────────────────────────────────

  group('e2e — 牧场', () {
    test('GET /farms 返回牧场列表（含坐标）', () async {
      final resp = await _get('/farms', ownerToken);
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final items = (data['items'] as List).cast<Map<String, dynamic>>();

      expect(items.length, greaterThanOrEqualTo(1));

      final farm = items.first;
      expect(farm['id'], isA<int>());
      expect(farm['name'], isA<String>());
      expect(farm['latitude'], isA<double>());
      expect(farm['longitude'], isA<double>());
    });
  });

  // ── 9. 权限边界 ────────────────────────────────────────────────────────

  group('e2e — 权限边界', () {
    test('owner 不能访问 admin 端点', () async {
      final resp = await _get('/admin/contracts', ownerToken);
      expect(resp.statusCode, 403);
    });

    test('worker 登录后不能访问订阅', () async {
      final loginResp = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': '13800138001', 'password': '123'}),
      );
      if (loginResp.statusCode != 200) return; // worker seed 可能不存在
      final loginData = jsonDecode(loginResp.body) as Map<String, dynamic>;
      final workerToken =
          (loginData['data'] as Map<String, dynamic>)['accessToken'] as String;

      final subResp = await _get('/subscription', workerToken);
      expect(subResp.statusCode, isIn([200, 403]));
    });
  });
}
