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
