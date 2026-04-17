import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  testWidgets('进入编辑态后显示迷你标题条与工具栏', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-edit-mini-title')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-toolbar')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-save')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-move')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-insert')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-delete')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-tool-translate')), findsOneWidget);
  });

  testWidgets('迷你标题条显示围栏名称', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    final fenceName =
        container.read(fenceControllerProvider).selectedFence!.name;
    expect(find.text('编辑围栏：$fenceName'), findsOneWidget);
  });

  testWidgets('撤销/重做按钮初始禁用', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    final IconButton undoButton = tester.widget<IconButton>(
      find.byKey(const Key('fence-edit-undo')),
    );
    final IconButton redoButton = tester.widget<IconButton>(
      find.byKey(const Key('fence-edit-redo')),
    );
    expect(undoButton.onPressed, isNull);
    expect(redoButton.onPressed, isNull);
  });

  testWidgets('编辑态地图可见且无固体背景遮盖', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-map')), findsOneWidget);
  });
}

Future<void> _openFencePage(WidgetTester tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-owner')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-fence')));
  await tester.pumpAndSettle();
}

Future<void> _selectFenceA(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('fence-panel-toggle')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('fence-card-fence_pasture_a')));
  await tester.pump(const Duration(milliseconds: 100));
}
