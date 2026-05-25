import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

class LiveTenantRepository implements TenantRepository {
  LiveTenantRepository();

  @override
  TenantListViewData loadList(TenantListQuery query) {
    return TenantListViewData(
      viewState: ViewState.empty,
      query: query,
      tenants: const [],
      total: 0,
      message: '暂无租户',
    );
  }

  @override
  TenantDevicesViewData loadDevices(String id) {
    return TenantDevicesViewData(
      viewState: ViewState.empty,
      devices: const [],
      total: 0,
      message: '暂无设备',
    );
  }

  @override
  TenantLogsViewData loadLogs(String id) {
    return TenantLogsViewData(
      viewState: ViewState.empty,
      logs: const [],
      total: 0,
      message: '暂无操作日志',
    );
  }

  @override
  TenantStatsViewData loadStats(String id) {
    return TenantStatsViewData(
      viewState: ViewState.empty,
      message: '暂无统计数据',
    );
  }

  @override
  TenantDetailViewData loadDetail(String id) {
    return const TenantDetailViewData(
      viewState: ViewState.empty,
      message: '租户不存在',
    );
  }

  @override
  TenantTrendsViewData loadTrends(String id) {
    return const TenantTrendsViewData(
      viewState: ViewState.empty,
      dailyStats: [],
    );
  }
}
