import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_stats_controller.dart';

void main() {
  test('Stats Controller 为已知租户返回 normal 状态', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantStatsControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.livestockTotal, greaterThan(0));
    expect(data.deviceTotal, greaterThan(0));
    expect(data.healthRate, greaterThanOrEqualTo(0));
    expect(data.alertCount, greaterThanOrEqualTo(0));
  });

  test('Stats Controller 在线率在有效范围内', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantStatsControllerProvider('tenant_001'));
    expect(data.deviceOnlineRate, inInclusiveRange(0, 100));
    expect(data.healthRate, inInclusiveRange(0, 100));
  });

  test('Stats Controller 刷新保持数据', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tenantStatsControllerProvider('tenant_001').notifier).refresh();
    final data = container.read(tenantStatsControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.livestockTotal, greaterThan(0));
  });
}
