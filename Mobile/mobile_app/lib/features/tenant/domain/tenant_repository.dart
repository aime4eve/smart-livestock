import 'package:hkt_livestock_agentic/features/tenant/domain/tenant_query.dart';
import 'package:hkt_livestock_agentic/features/tenant/domain/tenant_view_data.dart';

abstract class TenantRepository {
  TenantListViewData loadList(TenantListQuery query);
  TenantDetailViewData loadDetail(String id);
  TenantDevicesViewData loadDevices(String id);
  TenantLogsViewData loadLogs(String id);
  TenantStatsViewData loadStats(String id);
  TenantTrendsViewData loadTrends(String id);
}
