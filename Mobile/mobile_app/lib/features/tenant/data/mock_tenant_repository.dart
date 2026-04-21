import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_view_data.dart';

class MockTenantRepository implements TenantRepository {
  MockTenantRepository();

  static const List<Tenant> _seed = [
    Tenant(id: 'tenant_001', name: '华东示范牧场', status: TenantStatus.active, licenseUsed: 50, licenseTotal: 200),
    Tenant(id: 'tenant_002', name: '西部高原牧场', status: TenantStatus.active, licenseUsed: 120, licenseTotal: 200),
    Tenant(id: 'tenant_003', name: '东北黑土地牧场', status: TenantStatus.active, licenseUsed: 180, licenseTotal: 250),
    Tenant(id: 'tenant_004', name: '华南热带牧场', status: TenantStatus.disabled, licenseUsed: 30, licenseTotal: 100),
    Tenant(id: 'tenant_005', name: '西南高山牧场', status: TenantStatus.active, licenseUsed: 95, licenseTotal: 150),
    Tenant(id: 'tenant_006', name: '华北草原牧场', status: TenantStatus.active, licenseUsed: 75, licenseTotal: 180),
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
}
