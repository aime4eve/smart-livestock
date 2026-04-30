import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';

void main() {
  tearDown(() {
    ApiCache.instance.debugReset();
  });

  test('mock owner can switch between seeded farms and updates session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(sessionControllerProvider.notifier).login(DemoRole.owner);

    final initial = container.read(farmSwitcherControllerProvider);
    expect(initial.hasFarms, isTrue);
    expect(initial.hasMultipleFarms, isTrue);
    expect(initial.activeFarmId, 'tenant_001');
    expect(initial.farms.map((farm) => farm.id), ['tenant_001', 'tenant_007']);

    container
        .read(farmSwitcherControllerProvider.notifier)
        .switchFarm('tenant_007');

    expect(
      container.read(farmSwitcherControllerProvider).activeFarmId,
      'tenant_007',
    );
    expect(
      container.read(sessionControllerProvider).activeFarmTenantId,
      'tenant_007',
    );
  });

  test('switchFarm ignores farm ids outside the available list', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(sessionControllerProvider.notifier).login(DemoRole.worker);
    container
        .read(farmSwitcherControllerProvider.notifier)
        .switchFarm('tenant_404');

    expect(
      container.read(farmSwitcherControllerProvider).activeFarmId,
      'tenant_001',
    );
    expect(container.read(sessionControllerProvider).activeFarmTenantId, isNull);
  });

  test('live mode reads farm switcher state from ApiCache', () {
    ApiCache.instance.debugSetMyFarms({
      'activeFarmId': 'tenant_007',
      'farms': [
        {'id': 'tenant_001', 'name': '青山牧场', 'status': 'active'},
        {'id': 'tenant_007', 'name': '河谷牧场', 'status': 'active'},
      ],
    });
    final container = ProviderContainer(
      overrides: [appModeProvider.overrideWithValue(AppMode.live)],
    );
    addTearDown(container.dispose);

    final state = container.read(farmSwitcherControllerProvider);

    expect(state.activeFarmId, 'tenant_007');
    expect(state.farms.map((farm) => farm.name), ['青山牧场', '河谷牧场']);
    expect(state.farms.map((farm) => farm.status), ['active', 'active']);
  });

  test('live mode returns empty state when farm cache is missing', () {
    final container = ProviderContainer(
      overrides: [appModeProvider.overrideWithValue(AppMode.live)],
    );
    addTearDown(container.dispose);

    final state = container.read(farmSwitcherControllerProvider);

    expect(state.hasFarms, isFalse);
    expect(state.hasMultipleFarms, isFalse);
    expect(state.activeFarmId, isNull);
  });
}
