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

  final MockTenantRepository _fallback = MockTenantRepository();

  @override
  TenantListViewData loadList(TenantListQuery query) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.tenants.isEmpty) {
      return _fallback.loadList(query);
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
  TenantDetailViewData loadDetail(String id) {
    final cache = ApiCache.instance;
    if (!cache.initialized) return _fallback.loadDetail(id);
    Map<String, dynamic>? map;
    for (final t in cache.tenants) {
      if (t['id'] == id) {
        map = t;
        break;
      }
    }
    if (map == null) {
      return _fallback.loadDetail(id);
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
}
