import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/worker_management/data/mock_worker_repository.dart';
import 'package:smart_livestock_demo/features/worker_management/presentation/worker_controller.dart';

void main() {
  setUp(() {
    MockWorkerRepository.resetForTesting();
  });

  tearDown(() {
    MockWorkerRepository.resetForTesting();
  });

  test('WorkerController 初始为空，load/remove 后刷新列表', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(workerControllerProvider);
    expect(initial.viewState, ViewState.normal);
    expect(initial.items, isEmpty);

    final notifier = container.read(workerControllerProvider.notifier);
    notifier.loadWorkers('tenant_001');
    expect(
      container.read(workerControllerProvider).items.map((item) => item.id),
      ['wfa_001'],
    );

    notifier.removeWorker('wfa_001', 'tenant_001');
    final afterRemove = container.read(workerControllerProvider);
    expect(afterRemove.viewState, ViewState.normal);
    expect(afterRemove.items, isEmpty);
  });

  testWidgets('owner 我的页显示牧工管理入口并可进入列表页', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-mine')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mine-worker-management')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('mine-worker-management')));
    await tester.tap(find.byKey(const Key('mine-worker-management')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-worker-management')), findsOneWidget);
    expect(find.byKey(const Key('worker-wfa_001')), findsOneWidget);
  });

  testWidgets('worker 我的页不显示牧工管理入口', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-worker')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-mine')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mine-worker-management')), findsNothing);
  });

  testWidgets('牧工列表删除后重新加载并移除列表项', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-mine')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('mine-worker-management')));
    await tester.tap(find.byKey(const Key('mine-worker-management')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('worker-wfa_001')), findsOneWidget);

    await tester.tap(find.byKey(const Key('worker-remove-wfa_001')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('worker-wfa_001')), findsNothing);
    expect(find.byKey(const Key('worker-empty-state')), findsOneWidget);
  });

  testWidgets('牧工列表按当前 farm 切换重新加载', (tester) async {
    await tester.pumpWidget(
      DemoApp(
        overrides: [
          workerRepositoryProvider.overrideWithValue(const MockWorkerRepository()),
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-mine')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('mine-worker-management')));
    await tester.tap(find.byKey(const Key('mine-worker-management')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('worker-wfa_001')), findsOneWidget);

    await tester.tap(find.byKey(const Key('farm-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('河谷牧场').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('worker-wfa_001')), findsNothing);
    expect(find.byKey(const Key('worker-wfa_002')), findsOneWidget);
  });
}
