import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/data/live_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';

void main() {
  tearDown(() {
    ApiCache.instance.debugReset();
  });

  test('LiveRepository 未初始化时回退 Mock', () {
    final repo = LiveTenantRepository();
    final data = repo.loadList(const TenantListQuery());
    expect(data.viewState, anyOf(ViewState.normal, ViewState.empty));
  });

  test('LiveRepository 解析缓存返回正确状态', () {
    ApiCache.instance.debugSetInitialized(true);
    ApiCache.instance.debugSetTenants([
      {'id': 't1', 'name': '缓存A', 'status': 'active', 'licenseUsed': 10, 'licenseTotal': 100},
      {'id': 't2', 'name': '缓存B', 'status': 'disabled', 'licenseUsed': 5, 'licenseTotal': 50},
    ]);
    final repo = LiveTenantRepository();
    final data = repo.loadList(const TenantListQuery(status: TenantStatus.disabled));
    expect(data.tenants.length, 1);
    expect(data.tenants.first.name, '缓存B');
  });
}
