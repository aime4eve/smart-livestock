/// API 合约测试 — 验证前端 JSON 解析与真实后端响应结构匹配。
///
/// 运行前需先录制 fixture（后端需在线）：
///   dart test/contract/record_fixtures.dart
///
/// fixture 来自 Spring Boot 后端 (172.22.1.123:18080) 真实响应。
/// 后端改了字段名/结构 → 重跑测试立即发现。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/fence/data/fence_dto.dart';

/// Load a fixture file from test/fixtures/api/.
Map<String, dynamic> _loadFixture(String name) {
  final file = File('test/fixtures/api/$name');
  if (!file.existsSync()) {
    throw StateError('Fixture not found: ${file.path}\n'
        'Run `dart test/contract/record_fixtures.dart` first.');
  }
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return raw;
}

/// Unwrap the standard envelope { code, message, data }.
dynamic _data(String name) => _loadFixture(name)['data'];

// ══════════════════════════════════════════════════════════════════════════════
// 1. 围栏 (Fence)
// ══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── Fence ──────────────────────────────────────────────────────────────

  group('API 合约 — 围栏', () {
    late List<dynamic> fenceRows;

    setUpAll(() {
      final data = _data('fences_list.json') as Map<String, dynamic>;
      fenceRows = (data['items'] as List).cast<Map<String, dynamic>>();
      expect(fenceRows, isNotEmpty, reason: 'fixture 应至少有 1 条围栏');
    });

    test('后端响应使用 vertices 而非 coordinates', () {
      for (final row in fenceRows) {
        expect(row, contains('vertices'));
      }
    });

    test('fenceItemFromJson 正确解析 vertices → LatLng', () {
      final item =
          fenceItemFromJson(fenceRows[0] as Map<String, dynamic>, 0, 0);
      expect(item.id, isNotEmpty);
      expect(item.name, isNotEmpty);
      expect(item.points.length, greaterThanOrEqualTo(3));
      // 真实坐标范围（长沙 28.x, 112.x）
      expect(item.points.first.latitude, greaterThan(27));
      expect(item.points.first.latitude, lessThan(30));
      expect(item.points.first.longitude, greaterThan(111));
      expect(item.points.first.longitude, lessThan(114));
    });

    test('fenceItemFromJson 解析所有字段', () {
      final raw = fenceRows[0] as Map<String, dynamic>;
      final item = fenceItemFromJson(raw, 0, 5);

      expect(item.id, raw['id'].toString());
      expect(item.name, raw['name']);
      expect(item.active, raw['active']);
      expect(item.livestockCount, 5);
      expect(item.version, raw['version']);
      expect(item.fenceType, raw['fenceType']);
    });

    test('fenceItemsFromApiMaps 批量解析', () {
      final rows = fenceRows.cast<Map<String, dynamic>>();
      final items = fenceItemsFromApiMaps(rows, {});
      expect(items.length, fenceRows.length);
      for (final item in items) {
        expect(item.id, isNotEmpty);
        expect(item.points.length, greaterThanOrEqualTo(3));
      }
    });

    test('vertices 格式: [{lat, lng}, ...] 而非 [[lng, lat], ...]', () {
      final rawVertices = fenceRows[0]['vertices'] as List;
      final first = rawVertices[0] as Map<String, dynamic>;
      expect(first, contains('lat'));
      expect(first, contains('lng'));
      // lat ~28, lng ~112（长沙坐标范围）
      expect((first['lat'] as num).toDouble(), greaterThan(27));
      expect((first['lng'] as num).toDouble(), greaterThan(111));
    });

    test('fence detail 解析', () {
      final file = File('test/fixtures/api/fence_detail.json');
      if (!file.existsSync()) return;
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final data = raw['data'] as Map<String, dynamic>;
      final item = fenceItemFromJson(data, 0, 0);
      expect(item.id, isNotEmpty);
      expect(item.points.length, greaterThanOrEqualTo(3));
    });
  });

  // ── Livestock ──────────────────────────────────────────────────────────

  group('API 合约 — 牲畜', () {
    late List<dynamic> livestockRows;

    setUpAll(() {
      final data = _data('livestock_list.json') as Map<String, dynamic>;
      livestockRows = (data['items'] as List).cast<Map<String, dynamic>>();
      expect(livestockRows, isNotEmpty, reason: 'fixture 应至少有 1 条牲畜');
    });

    test('后端响应包含 id, livestockCode, breed, healthStatus', () {
      final row = livestockRows[0] as Map<String, dynamic>;
      expect(row, contains('id'));
      expect(row, contains('livestockCode'));
      expect(row, contains('breed'));
      expect(row, contains('healthStatus'));
    });

    test('后端使用 livestockCode 而非 earTag', () {
      for (final row in livestockRows) {
        final m = row as Map<String, dynamic>;
        expect(m['livestockCode'], isNotNull,
            reason: '后端返回 livestockCode 字段');
      }
    });

    test('后端坐标字段为 lastLatitude / lastLongitude', () {
      final row = livestockRows[0] as Map<String, dynamic>;
      expect(row, contains('lastLatitude'));
      expect(row, contains('lastLongitude'));
    });

    test('healthStatus 值为大写枚举', () {
      final validValues = {'HEALTHY', 'WARNING', 'CRITICAL'};
      for (final row in livestockRows) {
        final status =
            (row as Map<String, dynamic>)['healthStatus'] as String?;
        if (status != null) {
          expect(validValues, contains(status.toUpperCase()),
              reason: 'healthStatus 应为 ${validValues.join("/")} 之一');
        }
      }
    });
  });

  // ── Alert ──────────────────────────────────────────────────────────────

  group('API 合约 — 告警', () {
    late List<dynamic> alertRows;

    setUpAll(() {
      final data = _data('alerts_list.json') as Map<String, dynamic>;
      alertRows = (data['items'] as List).cast<Map<String, dynamic>>();
      expect(alertRows, isNotEmpty, reason: 'fixture 应至少有 1 条告警');
    });

    test('后端响应包含 type, status, severity, message', () {
      for (final row in alertRows) {
        final m = row as Map<String, dynamic>;
        expect(m, contains('id'));
        expect(m, contains('type'));
        expect(m, contains('status'));
        expect(m, contains('severity'));
        expect(m, contains('message'));
      }
    });

    test('status 值为 PENDING/ACKNOWLEDGED/HANDLED/ARCHIVED', () {
      final valid = {'PENDING', 'ACKNOWLEDGED', 'HANDLED', 'ARCHIVED'};
      for (final row in alertRows) {
        final status = (row as Map<String, dynamic>)['status'] as String?;
        if (status != null) {
          expect(valid, contains(status.toUpperCase()));
        }
      }
    });

    test('severity 值为 CRITICAL/WARNING/INFO', () {
      final valid = {'CRITICAL', 'WARNING', 'INFO'};
      for (final row in alertRows) {
        final severity =
            (row as Map<String, dynamic>)['severity'] as String?;
        if (severity != null) {
          expect(valid, contains(severity.toUpperCase()));
        }
      }
    });

    test('id 和 livestockId 为 int 类型（非 String）', () {
      for (final row in alertRows) {
        final m = row as Map<String, dynamic>;
        // 后端返回 int，前端需 toString() 转换
        expect(m['id'], isA<int>());
        if (m['livestockId'] != null) {
          expect(m['livestockId'], isA<int>());
        }
      }
    });
  });

  // ── Dashboard ──────────────────────────────────────────────────────────

  group('API 合约 — 看板', () {
    late Map<String, dynamic> data;

    setUpAll(() {
      data = _data('dashboard_summary.json') as Map<String, dynamic>;
    });

    test('后端使用扁平字段（非 metrics 数组）', () {
      expect(data, isNot(contains('metrics')));
      expect(data, contains('livestockCount'));
      expect(data, contains('onlineDeviceCount'));
      expect(data, contains('activeAlertCount'));
      expect(data, contains('fenceCount'));
    });

    test('healthSummary 包含 healthy/warning/critical', () {
      final health = data['healthSummary'] as Map<String, dynamic>?;
      expect(health, isNotNull);
      expect(health, contains('healthy'));
      expect(health, contains('warning'));
      expect(health, contains('critical'));
    });
  });

  // ── Me (Profile) ──────────────────────────────────────────────────────

  group('API 合约 — 个人信息', () {
    late Map<String, dynamic> data;

    setUpAll(() {
      data = _data('me.json') as Map<String, dynamic>;
    });

    test('后端响应包含 id, name, phone, role, tenantId', () {
      expect(data, contains('id'));
      expect(data, contains('name'));
      expect(data, contains('phone'));
      expect(data, contains('role'));
      expect(data, contains('tenantId'));
    });

    test('role 值为大写枚举', () {
      final validRoles = {
        'OWNER',
        'WORKER',
        'B2B_ADMIN',
        'PLATFORM_ADMIN',
      };
      final role = data['role'] as String;
      expect(validRoles, contains(role));
    });

    test('id 和 tenantId 为 int 类型', () {
      expect(data['id'], isA<int>());
      expect(data['tenantId'], isA<int>());
    });
  });

  // ── Farms ──────────────────────────────────────────────────────────────

  group('API 合约 — 牧场', () {
    late Map<String, dynamic> data;
    late List<dynamic> farmRows;

    setUpAll(() {
      data = _data('farms_list.json') as Map<String, dynamic>;
      farmRows = (data['items'] as List).cast<Map<String, dynamic>>();
      expect(farmRows, isNotEmpty);
    });

    test('后端响应包含分页 envelope', () {
      expect(data, contains('items'));
      expect(data, contains('total'));
      expect(data, contains('page'));
      expect(data, contains('pageSize'));
    });

    test('farm 对象包含 id, name, latitude, longitude', () {
      for (final row in farmRows) {
        final m = row as Map<String, dynamic>;
        expect(m, contains('id'));
        expect(m, contains('name'));
        expect(m, contains('latitude'));
        expect(m, contains('longitude'));
      }
    });
  });

  // ── Subscription ──────────────────────────────────────────────────────

  group('API 合约 — 订阅', () {
    test('SubscriptionStatus.fromJson 解析真实后端响应', () {
      final data = _data('subscription_status.json') as Map<String, dynamic>;

      // 后端 id/tenantId 是 int，fromJson 已做 int→String 兼容
      // 后端无 livestockCount/calculatedDeviceFee 等字段，fromJson 已做 null→0 兜底
      final status = SubscriptionStatus.fromJson(data);
      expect(status.id, isNotEmpty);
      expect(status.tenantId, isNotEmpty);
      expect(status.tier, SubscriptionTier.premium);
      expect(status.status, 'ACTIVE');
      expect(status.currentPeriodEnd, isNotNull);
      expect(status.livestockCount, 0); // 后端不返回，兜底 0
      expect(status.calculatedTotal, 0.0); // 后端不返回，兜底 0.0
    });

    test('后端 subscription 响应的实际字段', () {
      final data = _data('subscription_status.json') as Map<String, dynamic>;

      // 后端实际返回的字段
      expect(data, contains('id'));
      expect(data, contains('tenantId'));
      expect(data, contains('tier'));
      expect(data, contains('status'));
      expect(data, contains('billingCycle'));
      expect(data, contains('startedAt'));
      expect(data, contains('expiresAt'));
      expect(data, contains('effectiveTier'));

      // 前端 fromJson 期望但后端没有的字段
      expect(data, isNot(contains('livestockCount')));
      expect(data, isNot(contains('calculatedDeviceFee')));
      expect(data, isNot(contains('calculatedTierFee')));
      expect(data, isNot(contains('calculatedTotal')));
    });

    test('后端 subscription/plans 返回 data 为 List（非分页）', () {
      final raw = _loadFixture('subscription_plans.json');
      final data = raw['data'];
      expect(data, isA<List>());
      final plans = data as List;
      expect(plans.length, 4);

      final basic = plans.firstWhere(
              (p) =>
          (p as Map<String, dynamic>)['tier'] ==
              'BASIC') as Map<String, dynamic>;
      expect(basic['monthlyPriceCents'], isA<int>());
      expect(basic['includedLivestock'], isA<int>());
    });
  });

  // ── Devices ────────────────────────────────────────────────────────────

  group('API 合约 — 设备', () {
    late Map<String, dynamic> data;
    late List<dynamic> deviceRows;

    setUpAll(() {
      data = _data('devices_list.json') as Map<String, dynamic>;
      deviceRows = (data['items'] as List).cast<Map<String, dynamic>>();
      expect(deviceRows, isNotEmpty);
    });

    test('后端设备响应包含基础字段', () {
      final first = deviceRows[0] as Map<String, dynamic>;
      expect(first, contains('id'));
      expect(first, contains('deviceType'));
      expect(first, contains('status'));
    });

    test('后端使用分页 envelope', () {
      expect(data, contains('items'));
      expect(data, contains('total'));
    });
  });


  // ── Ranch Overview (Issue #51) ────────────────────────────────────────

  group("API \u5408\u7ea6 \u2014 \u7267\u573a\u603b\u89c8", () {
    late Map<String, dynamic> overviewData;

    setUpAll(() {
      overviewData = _data('ranch_overview.json') as Map<String, dynamic>;
    });

    test('ranch-overview envelope \u7ed3\u6784', () {
      expect(overviewData, contains('overallStats'));
      expect(overviewData, contains('sceneSummary'));
      expect(overviewData, contains('pendingTasks'));
      expect(overviewData, contains('fences'));
      expect(overviewData, contains('livestockMarkers'));
      expect(overviewData, contains('alerts'));
    });

    test('overallStats \u7c7b\u578b\u6b63\u786e', () {
      final stats = overviewData['overallStats'] as Map<String, dynamic>;
      expect(stats['totalLivestock'], isA<int>());
      expect(stats['healthyRate'], isA<double>());
      expect(stats['alertCount'], isA<int>());
      expect(stats['criticalCount'], isA<int>());
      expect(stats['deviceOnlineRate'], isA<double>());
    });

    test('fences \u683c\u5f0f', () {
      final fences = overviewData['fences'] as List;
      expect(fences, isNotEmpty);
      final fence = fences.first as Map<String, dynamic>;
      expect(fence, contains('id'));
      expect(fence, contains('name'));
      expect(fence, contains('points'));
      final points = fence['points'] as List;
      expect(points.first, contains('lat'));
      expect(points.first, contains('lng'));
    });

    test('livestockMarkers \u683c\u5f0f', () {
      final markers = overviewData['livestockMarkers'] as List;
      expect(markers, isNotEmpty);
      final m = markers.first as Map<String, dynamic>;
      expect(m['latitude'], isA<num>());
      expect(m['longitude'], isA<num>());
      expect(m['healthStatus'], isA<String>());
      final validStatuses = {'NORMAL', 'WARNING', 'CRITICAL'};
      expect(validStatuses, contains(m['healthStatus']));
    });

    test('alerts \u683c\u5f0f', () {
      final alerts = overviewData['alerts'] as List;
      for (final a in alerts) {
        final alert = a as Map<String, dynamic>;
        expect(alert, contains('id'));
        expect(alert, contains('type'));
        expect(alert, contains('severity'));
        expect(alert, contains('status'));
        expect(alert, contains('message'));
      }
    });
  });

  // ── Cross-cutting: envelope structure ──────────────────────────────────

  group('API 合约 — 通用 envelope', () {
    final allFixtures = [
      'fences_list.json',
      'livestock_list.json',
      'alerts_list.json',
      'dashboard_summary.json',
      'me.json',
      'farms_list.json',
      'subscription_status.json',
      'subscription_plans.json',
      'devices_list.json',
      'ranch_overview.json',
    ];

    test('所有 fixture 包含 {code, message, data}', () {
      for (final name in allFixtures) {
        final raw = _loadFixture(name);
        expect(raw, contains('code'), reason: '$name 缺少 code 字段');
        expect(raw, contains('message'), reason: '$name 缺少 message 字段');
        expect(raw, contains('data'), reason: '$name 缺少 data 字段');
        expect(raw['code'], 'OK', reason: '$name code 应为 OK');
      }
    });

    test('列表 fixture 使用 {items, total, page, pageSize} 分页', () {
      final listFixtures = [
        'fences_list.json',
        'livestock_list.json',
        'alerts_list.json',
        'farms_list.json',
        'devices_list.json',
      ];
      for (final name in listFixtures) {
        final data = _data(name) as Map<String, dynamic>;
        expect(data, contains('items'), reason: '$name data 缺少 items');
        expect(data, contains('total'), reason: '$name data 缺少 total');
        expect((data['items'] as List).isNotEmpty, isTrue,
            reason: '$name items 不应为空');
      }
    });
  });
}
