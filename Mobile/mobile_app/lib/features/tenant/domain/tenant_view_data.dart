import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';

class TenantListViewData {
  const TenantListViewData({
    required this.viewState,
    required this.query,
    required this.tenants,
    required this.total,
    this.message,
  });

  final ViewState viewState;
  final TenantListQuery query;
  final List<Tenant> tenants;
  final int total;
  final String? message;

  int get pageCount =>
      total == 0 ? 1 : ((total + query.pageSize - 1) ~/ query.pageSize);
}

class TenantDetailViewData {
  const TenantDetailViewData({
    required this.viewState,
    this.tenant,
    this.message,
  });

  final ViewState viewState;
  final Tenant? tenant;
  final String? message;
}

class TenantDevicesViewData {
  const TenantDevicesViewData({
    required this.viewState,
    required this.devices,
    required this.total,
    this.message,
  });

  final ViewState viewState;
  final List<DeviceItem> devices;
  final int total;
  final String? message;
}

class TenantLogEntry {
  const TenantLogEntry({
    required this.id,
    required this.action,
    required this.detail,
    required this.operator,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String detail;
  final String operator;
  final String createdAt;
}

class TenantLogsViewData {
  const TenantLogsViewData({
    required this.viewState,
    required this.logs,
    required this.total,
    this.message,
  });

  final ViewState viewState;
  final List<TenantLogEntry> logs;
  final int total;
  final String? message;
}

class TenantStatsViewData {
  const TenantStatsViewData({
    required this.viewState,
    this.livestockTotal = 0,
    this.deviceTotal = 0,
    this.deviceOnline = 0,
    this.deviceOnlineRate = 0,
    this.healthRate = 0,
    this.alertCount = 0,
    this.lastSync,
    this.message,
  });

  final ViewState viewState;
  final int livestockTotal;
  final int deviceTotal;
  final int deviceOnline;
  final int deviceOnlineRate;
  final int healthRate;
  final int alertCount;
  final String? lastSync;
  final String? message;
}
