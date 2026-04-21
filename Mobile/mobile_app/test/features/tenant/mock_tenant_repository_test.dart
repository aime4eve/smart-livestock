import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/data/mock_tenant_repository.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';

void main() {
  test('Mock 默认列表返回全部且 viewState=normal', () {
    final repo = MockTenantRepository();
    final data = repo.loadList(const TenantListQuery());
    expect(data.viewState, ViewState.normal);
    expect(data.tenants.length, greaterThan(0));
    expect(data.total, data.tenants.length);
  });

  test('Mock status 过滤只返回匹配项', () {
    final repo = MockTenantRepository();
    final data = repo.loadList(const TenantListQuery(status: TenantStatus.disabled));
    expect(data.tenants.every((t) => t.status == TenantStatus.disabled), isTrue);
  });

  test('Mock search 支持名称包含', () {
    final repo = MockTenantRepository();
    final data = repo.loadList(const TenantListQuery(search: '草原'));
    expect(data.tenants.every((t) => t.name.contains('草原')), isTrue);
  });

  test('Mock loadDetail 未命中返回 empty viewState', () {
    final repo = MockTenantRepository();
    final data = repo.loadDetail('tenant_unknown');
    expect(data.viewState, ViewState.empty);
    expect(data.tenant, isNull);
  });
}
