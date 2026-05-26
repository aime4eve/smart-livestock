import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('围栏选中状态在路由切换后保持', (tester) async {
    await pumpAppWithRole(tester, UserRole.owner);

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    final fenceCtx = tester.element(find.byKey(const Key('page-fence')));
    ProviderScope.containerOf(fenceCtx)
        .read(fenceControllerProvider.notifier)
        .select('fence_pasture_a');
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    ).read(fenceControllerProvider);
    expect(state.selectedFenceId, 'fence_pasture_a');
  });
}
