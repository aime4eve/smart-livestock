import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/data/mock_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/data/tenant_dto.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

class LiveTenantRepository implements TenantRepository {
  LiveTenantRepository();

  static final MockTenantRepository _fallback = MockTenantRepository();

  @override
  TenantListViewData loadList(TenantListQuery query) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return TenantListViewData(
        viewState: ViewState.error,
        query: query,
        tenants: const [],
        total: 0,
        message: 'Live API 未连接',
      );
    }
    var all = cache.tenants
        .map(TenantDto.fromJson)
        .whereType<Tenant>()
        .toList();
    if (query.status != null) {
      all = all.where((t) => t.status == query.status).toList();
    }
    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      final kw = search.toLowerCase();
      all = all.where((t) => t.name.toLowerCase().contains(kw)).toList();
    }
    final dir = query.order == SortOrder.desc ? -1 : 1;
    all.sort((a, b) {
      switch (query.sort) {
        case TenantSort.licenseUsage:
          return a.licenseUsage.compareTo(b.licenseUsage) * dir;
        case TenantSort.name:
          return a.name.compareTo(b.name) * dir;
      }
    });
    final total = all.length;
    final start = (query.page - 1) * query.pageSize;
    final items = start >= total
        ? <Tenant>[]
        : all.sublist(start, (start + query.pageSize).clamp(0, total));
    return TenantListViewData(
      viewState: items.isEmpty ? ViewState.empty : ViewState.normal,
      query: query,
      tenants: items,
      total: total,
      message: items.isEmpty ? '暂无租户' : null,
    );
  }

  @override
  TenantDevicesViewData loadDevices(String id) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.loadDevices(id);
    }
    final list = cache.tenantDevices(id);
    if (list == null) return _fallback.loadDevices(id);
    return TenantDevicesViewData(
      viewState: list.isEmpty ? ViewState.empty : ViewState.normal,
      devices: list,
      total: list.length,
      message: list.isEmpty ? '暂无设备' : null,
    );
  }

  @override
  TenantLogsViewData loadLogs(String id) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.loadLogs(id);
    }
    final list = cache.tenantLogs(id);
    if (list == null) return _fallback.loadLogs(id);
    return TenantLogsViewData(
      viewState: list.isEmpty ? ViewState.empty : ViewState.normal,
      logs: list,
      total: list.length,
      message: list.isEmpty ? '暂无操作日志' : null,
    );
  }

  @override
  TenantStatsViewData loadStats(String id) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.loadStats(id);
    }
    final data = cache.tenantStats(id);
    if (data == null) return _fallback.loadStats(id);
    return TenantStatsViewData(
      viewState: ViewState.normal,
      livestockTotal: data['livestockTotal'] as int? ?? 0,
      deviceTotal: data['deviceTotal'] as int? ?? 0,
      deviceOnline: data['deviceOnline'] as int? ?? 0,
      deviceOnlineRate: data['deviceOnlineRate'] as int? ?? 0,
      healthRate: data['healthRate'] as int? ?? 0,
      alertCount: data['alertCount'] as int? ?? 0,
      lastSync: data['lastSync'] as String?,
    );
  }

  @override
  TenantDetailViewData loadDetail(String id) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return const TenantDetailViewData(
        viewState: ViewState.error,
        message: 'Live API 未连接',
      );
    }
    Map<String, dynamic>? map;
    for (final t in cache.tenants) {
      if (t['id'] == id) {
        map = t;
        break;
      }
    }
    if (map == null) {
      return const TenantDetailViewData(
        viewState: ViewState.empty,
        message: '租户不存在',
      );
    }
    final tenant = TenantDto.fromJson(map);
    if (tenant == null) {
      return const TenantDetailViewData(
        viewState: ViewState.error,
        message: '租户数据解析失败',
      );
    }
    return TenantDetailViewData(
      viewState: ViewState.normal,
      tenant: tenant,
    );
  }

  @override
  TenantTrendsViewData loadTrends(String id) {
    final cache = ApiCache.instance;
    if (!cache.initialized) return _fallback.loadTrends(id);
    final trendsCache = cache.tenantTrends;
    if (trendsCache == null || trendsCache.isEmpty) return _fallback.loadTrends(id);
    final map = trendsCache[id];
    if (map == null) return _fallback.loadTrends(id);
    final dailyStats = (map['dailyStats'] as List<dynamic>?)
        ?.map((e) => DailyStatPoint(
              date: e['date'] as String,
              alerts: e['alerts'] as int,
              deviceOnlineRate: (e['deviceOnlineRate'] as num).toDouble(),
              healthRate: (e['healthRate'] as num).toDouble(),
            ))
        .toList();
    if (dailyStats == null || dailyStats.isEmpty) {
      return _fallback.loadTrends(id);
    }
    return TenantTrendsViewData(
      viewState: ViewState.normal,
      dailyStats: dailyStats,
    );
  }
}
