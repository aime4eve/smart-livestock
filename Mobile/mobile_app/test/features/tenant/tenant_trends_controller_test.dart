import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_trends_controller.dart';

void main() {
  test('Trends Controller 为已知租户返回 ViewState.normal', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantTrendsControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.dailyStats.length, 30);
  });

  test('Trends Controller 日期降序排列', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantTrendsControllerProvider('tenant_001'));
    final dates = data.dailyStats.map((s) => s.date).toList();
    for (var i = 0; i < dates.length - 1; i++) {
      expect(dates[i].compareTo(dates[i + 1]), greaterThanOrEqualTo(0));
    }
  });

  test('Trends Controller 刷新保持相同租户', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tenantTrendsControllerProvider('tenant_001').notifier).refresh();
    final data = container.read(tenantTrendsControllerProvider('tenant_001'));
    expect(data.dailyStats.length, 30);
  });

  test('Trends Controller 对不存在的租户返回 ViewState.empty', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantTrendsControllerProvider('tenant_unknown'));
    expect(data.viewState, ViewState.empty);
    expect(data.dailyStats, isEmpty);
  });
}
