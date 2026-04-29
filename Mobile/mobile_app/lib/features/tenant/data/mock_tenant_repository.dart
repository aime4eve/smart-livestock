import 'dart:math';

import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

class MockTenantRepository implements TenantRepository {
  MockTenantRepository();

  static const List<Tenant> _seed = [
    Tenant(id: 'tenant_001', name: '华东示范牧场', status: TenantStatus.active, licenseUsed: 50, licenseTotal: 200, contactName: '张国庆', contactPhone: '13900010001', contactEmail: 'zhang@eastdairy.cn', region: '华东', remarks: '总部示范牧场，最先部署 IoT 设备。', createdAt: '2025-08-12T09:00:00+08:00', updatedAt: '2026-04-20T14:30:00+08:00', lastUpdatedBy: '平台管理员'),
    Tenant(id: 'tenant_002', name: '西部高原牧场', status: TenantStatus.active, licenseUsed: 120, licenseTotal: 200, contactName: '索南扎西', contactPhone: '13900020002', contactEmail: 'szz@westplateau.cn', region: '西北', remarks: '高原牦牛试点，海拔 3500m。', createdAt: '2025-10-05T11:00:00+08:00', updatedAt: '2026-04-18T09:15:00+08:00', lastUpdatedBy: '平台管理员'),
    Tenant(id: 'tenant_003', name: '东北黑土地牧场', status: TenantStatus.active, licenseUsed: 180, licenseTotal: 250, contactName: '王大壮', contactPhone: '13900030003', contactEmail: 'wangdz@northeast.cn', region: '东北', remarks: '大型肉牛育肥场，年出栏 5000+。', createdAt: '2025-09-20T08:30:00+08:00', updatedAt: '2026-04-15T16:45:00+08:00', lastUpdatedBy: '平台管理员'),
    Tenant(id: 'tenant_004', name: '华南热带牧场', status: TenantStatus.disabled, licenseUsed: 30, licenseTotal: 100, contactName: '林伟雄', contactPhone: '13900040004', contactEmail: 'linwx@southtropic.cn', region: '华南', remarks: '热带环境试点，夏季高温预警测试。', createdAt: '2025-11-01T10:00:00+08:00', updatedAt: '2026-03-30T11:20:00+08:00', lastUpdatedBy: '平台管理员'),
    Tenant(id: 'tenant_005', name: '西南高山牧场', status: TenantStatus.active, licenseUsed: 95, licenseTotal: 150, contactName: '杨志勇', contactPhone: '13900050005', contactEmail: 'yangzy@swhigh.cn', region: '西南', remarks: '山地放牧模式，GPS 信号挑战场景。', createdAt: '2025-12-15T14:00:00+08:00', updatedAt: '2026-04-22T08:00:00+08:00', lastUpdatedBy: '平台管理员'),
    Tenant(id: 'tenant_006', name: '华北草原牧场', status: TenantStatus.active, licenseUsed: 75, licenseTotal: 180, contactName: '赵牧仁', contactPhone: '13900060006', contactEmail: 'zhaomr@northgrass.cn', region: '华北', remarks: '草原散养奶牛，乳制品供应链上游。', createdAt: '2026-01-10T09:30:00+08:00', updatedAt: '2026-04-25T13:10:00+08:00', lastUpdatedBy: '平台管理员'),
  ];

  @override
  TenantListViewData loadList(TenantListQuery query) {
    var filtered = List<Tenant>.from(_seed);
    if (query.status != null) {
      filtered = filtered.where((t) => t.status == query.status).toList();
    }
    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      final kw = search.toLowerCase();
      filtered = filtered.where((t) => t.name.toLowerCase().contains(kw)).toList();
    }
    final dir = query.order == SortOrder.desc ? -1 : 1;
    filtered.sort((a, b) {
      switch (query.sort) {
        case TenantSort.licenseUsage:
          return a.licenseUsage.compareTo(b.licenseUsage) * dir;
        case TenantSort.name:
          return a.name.compareTo(b.name) * dir;
      }
    });
    final total = filtered.length;
    final start = (query.page - 1) * query.pageSize;
    final items = start >= total
        ? <Tenant>[]
        : filtered.sublist(start, (start + query.pageSize).clamp(0, total));
    return TenantListViewData(
      viewState: items.isEmpty ? ViewState.empty : ViewState.normal,
      query: query,
      tenants: items,
      total: total,
      message: items.isEmpty ? '暂无租户' : null,
    );
  }

  @override
  TenantDetailViewData loadDetail(String id) {
    for (final t in _seed) {
      if (t.id == id) {
        return TenantDetailViewData(
          viewState: ViewState.normal,
          tenant: t,
        );
      }
    }
    return const TenantDetailViewData(
      viewState: ViewState.empty,
      message: '租户不存在',
    );
  }

  @override
  TenantDevicesViewData loadDevices(String id) {
    final tenantIdx = int.tryParse(id.split('_').last) ?? 1;
    final allDevices = DemoSeed.devices;
    final subset = tenantIdx == 1
        ? allDevices
        : allDevices.indexed.where((e) => (e.$1 % (tenantIdx + 2)) == 0).map((e) => e.$2).toList();
    return TenantDevicesViewData(
      viewState: subset.isEmpty ? ViewState.empty : ViewState.normal,
      devices: subset,
      total: subset.length,
      message: subset.isEmpty ? '暂无设备' : null,
    );
  }

  @override
  TenantLogsViewData loadLogs(String id) {
    final tenant = _seed.where((t) => t.id == id).firstOrNull;
    if (tenant == null) {
      return const TenantLogsViewData(
        viewState: ViewState.empty,
        logs: [],
        total: 0,
        message: '租户不存在',
      );
    }
    final logs = [
      TenantLogEntry(id: 'log-001', action: '租户创建', detail: '创建租户「${tenant.name}」', operator: '平台管理员', createdAt: tenant.createdAt ?? '2025-08-12T09:00:00+08:00'),
      TenantLogEntry(id: 'log-002', action: 'License 调整', detail: '配额调整为 ${tenant.licenseTotal}', operator: '平台管理员', createdAt: tenant.updatedAt ?? '2026-04-20T14:30:00+08:00'),
      TenantLogEntry(id: 'log-003', action: '状态变更', detail: '状态变更为「${tenant.status == TenantStatus.active ? '启用中' : '已禁用'}」', operator: '平台管理员', createdAt: tenant.updatedAt ?? '2026-04-20T14:30:00+08:00'),
      TenantLogEntry(id: 'log-004', action: '信息更新', detail: '更新租户基本信息', operator: '平台管理员', createdAt: tenant.updatedAt ?? '2026-04-19T10:00:00+08:00'),
    ];
    return TenantLogsViewData(
      viewState: ViewState.normal,
      logs: logs,
      total: logs.length,
    );
  }

  @override
  TenantStatsViewData loadStats(String id) {
    final tenant = _seed.where((t) => t.id == id).firstOrNull;
    if (tenant == null) {
      return const TenantStatsViewData(
        viewState: ViewState.empty,
        message: '租户不存在',
      );
    }
    final tenantIdx = int.tryParse(id.split('_').last) ?? 1;
    final deviceCount = tenantIdx == 1 ? 100 : (10 + tenantIdx * 15).clamp(10, 100);
    final onlineCount = (deviceCount * 0.85).round();
    final livestockCount = tenant.licenseUsed;
    final healthRate = 88 + (tenantIdx % 10);
    final alertCount = 3 + (tenantIdx % 6);
    return TenantStatsViewData(
      viewState: ViewState.normal,
      livestockTotal: livestockCount,
      deviceTotal: deviceCount,
      deviceOnline: onlineCount,
      deviceOnlineRate: deviceCount > 0 ? ((onlineCount / deviceCount) * 100).round() : 0,
      healthRate: healthRate,
      alertCount: alertCount,
      lastSync: '2 分钟前',
    );
  }

  @override
  TenantTrendsViewData loadTrends(String id) {
    final tenant = _seed.where((t) => t.id == id).toList();
    if (tenant.isEmpty) {
      return const TenantTrendsViewData(
        viewState: ViewState.empty,
        dailyStats: [],
        message: '租户不存在',
      );
    }
    final now = DateTime.now();
    final stats = <DailyStatPoint>[];
    final baseHash = id.hashCode.abs();
    for (var i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      final date =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final sinVal = sin(d.month * d.day * 0.3);
      stats.add(DailyStatPoint(
        date: date,
        alerts: ((baseHash + i * 7) % 8 + (sinVal * 3).round()).abs(),
        deviceOnlineRate: (80 + (baseHash + i * 3) % 20).toDouble(),
        healthRate: (75 + (baseHash + i * 5) % 25).toDouble(),
      ));
    }
    return TenantTrendsViewData(
      viewState: ViewState.normal,
      dailyStats: stats,
    );
  }
}
