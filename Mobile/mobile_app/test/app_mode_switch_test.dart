import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  test('AppMode.live 下仓储 provider 切换到 live 实现', () {
    final container = ProviderContainer(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.live),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(dashboardRepositoryProvider).runtimeType.toString(),
      contains('Live'),
    );
    expect(
      container.read(fenceRepositoryProvider).runtimeType.toString(),
      contains('Live'),
    );
  });
}
