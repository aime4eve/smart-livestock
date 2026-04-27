import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/tenant/presentation/tenant_devices_controller.dart';

void main() {
  test('Devices Controller 为已知租户返回 normal 状态', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = container.read(tenantDevicesControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.devices.isNotEmpty, isTrue);
    expect(data.total, greaterThanOrEqualTo(data.devices.length));
  });

  test('Devices Controller 刷新保持数据', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(tenantDevicesControllerProvider('tenant_001').notifier).refresh();
    final data = container.read(tenantDevicesControllerProvider('tenant_001'));
    expect(data.viewState, ViewState.normal);
    expect(data.devices.isNotEmpty, isTrue);
  });
}
