import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant.dart';
import 'package:smart_livestock_demo/features/tenant/domain/tenant_query.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_list_controller.dart';

void main() {
  test('Controller 初始化使用默认 Query', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantListControllerProvider);
    expect(data.query.page, 1);
    expect(data.query.status, isNull);
  });

  test('setStatus 更新 query.status 并重置 page=1', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(tenantListControllerProvider.notifier)
        .setStatus(TenantStatus.disabled);
    final data = container.read(tenantListControllerProvider);
    expect(data.query.status, TenantStatus.disabled);
    expect(data.query.page, 1);
  });

  test('setPage 翻到下一页', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tenantListControllerProvider.notifier).setPage(2);
    final data = container.read(tenantListControllerProvider);
    expect(data.query.page, 2);
  });

  test('setSort 切换排序字段', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(tenantListControllerProvider.notifier)
        .setSort(TenantSort.licenseUsage, SortOrder.desc);
    final data = container.read(tenantListControllerProvider);
    expect(data.query.sort, TenantSort.licenseUsage);
    expect(data.query.order, SortOrder.desc);
  });
}
