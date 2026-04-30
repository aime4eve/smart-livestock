import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  tearDown(() {
    ApiCache.instance.updateFenceRemoteOverride = null;
    ApiCache.instance.lastFenceSaveStatusCode = null;
    ApiCache.instance.debugReset();
  });

  testWidgets('未选中围栏时点击编辑边界显示提示且不进入编辑态', (tester) async {
    await _openFencePage(tester);

    final fab = tester.widget<FloatingActionButton>(
      find.byKey(const Key('fence-start-edit')),
    );
    expect(fab.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    expect(find.text('请先选择一个牧场'), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-mini-title')), findsNothing);
  });

  testWidgets('侧栏编辑按钮直接进入边界编辑', (tester) async {
    await _openFencePage(tester);
    await tester.tap(find.byKey(const Key('fence-panel-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-edit-fence_pasture_a')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-edit-mini-title')), findsOneWidget);
  });

  testWidgets('进入编辑全屏后可直接退出并恢复浏览列表', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-edit-mini-title')), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('智慧牧场示范场'), findsNothing);

    await tester.tap(find.byKey(const Key('fence-edit-exit')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('fence-edit-mini-title')), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byKey(const Key('fence-drawer-title')), findsOneWidget);
  });

  testWidgets('有未保存改动时退出弹出三选确认且遮罩不能关闭并可继续编辑', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();
    await _insertEdgePoint(tester);

    await tester.tap(find.byKey(const Key('fence-edit-exit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-unsaved-dialog')), findsOneWidget);
    expect(find.byKey(const Key('fence-unsaved-save')), findsOneWidget);
    expect(find.byKey(const Key('fence-unsaved-discard')), findsOneWidget);
    expect(find.byKey(const Key('fence-unsaved-continue')), findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-unsaved-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fence-unsaved-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-unsaved-dialog')), findsNothing);
    expect(find.byKey(const Key('fence-edit-mini-title')), findsOneWidget);
  });

  testWidgets('编辑态保存按钮仅在有未保存改动时可用', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    var saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('fence-edit-save')),
    );
    expect(saveButton.onPressed, isNull);

    await _insertEdgePoint(tester);

    saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('fence-edit-save')),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('有未保存改动时可放弃更改并退出编辑态且点位保持原值', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    final originalPoint =
        container.read(fenceControllerProvider).fences.first.points.first;

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    await _insertEdgePoint(tester);

    await tester.tap(find.byKey(const Key('fence-edit-exit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-unsaved-discard')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('fence-edit-mini-title')), findsNothing);
    expect(find.byKey(const Key('fence-drawer-title')), findsOneWidget);
    expect(
      container.read(fenceControllerProvider).fences.first.points.first,
      originalPoint,
    );
  });

  testWidgets('有未保存改动时可保存并退出编辑态且点位写回围栏', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    final originalLength =
        container.read(fenceControllerProvider).fences.first.points.length;

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    await _insertEdgePoint(tester);

    await tester.tap(find.byKey(const Key('fence-edit-exit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-unsaved-save')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('fence-edit-mini-title')), findsNothing);
    expect(find.byKey(const Key('fence-drawer-title')), findsOneWidget);
    expect(
      container.read(fenceControllerProvider).fences.first.points.length,
      originalLength + 1,
    );
  });

  testWidgets('保存中退出按钮禁用且不会退出编辑态', (tester) async {
    final completer = Completer<FenceSaveResult>();
    ApiCache.instance.updateFenceRemoteOverride = (_, __, ___) => completer.future;
    _seedLiveFenceCache();

    await _openFencePage(tester, appMode: AppMode.live);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();
    await _insertEdgePoint(tester);

    await tester.tap(find.byKey(const Key('fence-edit-save')));
    await tester.pump();

    final IconButton exitButton = tester.widget<IconButton>(
      find.byKey(const Key('fence-edit-exit')),
    );
    expect(exitButton.onPressed, isNull);
    expect(find.byKey(const Key('fence-edit-mini-title')), findsOneWidget);

    completer.complete(const FenceSaveResult(ok: false, statusCode: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('系统返回会触发与退出一致的未保存三选确认', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();
    await _insertEdgePoint(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-unsaved-dialog')), findsOneWidget);
    expect(find.byKey(const Key('fence-unsaved-save')), findsOneWidget);
    expect(find.byKey(const Key('fence-unsaved-discard')), findsOneWidget);
    expect(find.byKey(const Key('fence-unsaved-continue')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-mini-title')), findsOneWidget);
  });

  testWidgets('非法几何时保存按钮禁用且通过退出保存会被拦截并提示', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    final points = container.read(fenceControllerProvider).editSession!.points;
    container.read(fenceControllerProvider.notifier).moveDraftVertex(1, points.first);
    await tester.pumpAndSettle();

    final FilledButton saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('fence-edit-save')),
    );
    expect(saveButton.onPressed, isNull);

    await tester.tap(find.byKey(const Key('fence-edit-exit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-unsaved-save')));
    await tester.pumpAndSettle();

    expect(find.text('边界不能有连续重复点'), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-mini-title')), findsOneWidget);
  });

  testWidgets('删点到最少三点后继续删除会提示失败原因', (tester) async {
    await _openFencePage(tester);
    await _selectFenceA(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );

    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();

    final controller = container.read(fenceControllerProvider.notifier);
    while (container.read(fenceControllerProvider).editSession!.points.length > 3) {
      controller.removeDraftVertex(0);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const Key('fence-edit-tool-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-edit-vertex-0')));
    await tester.pumpAndSettle();

    expect(find.text('边界至少保留 3 个点'), findsOneWidget);
    expect(
      container.read(fenceControllerProvider).editSession!.points.length,
      3,
    );
  });
}

Future<void> _openFencePage(
  WidgetTester tester, {
  AppMode appMode = AppMode.mock,
}) async {
  await tester.pumpWidget(DemoApp(appMode: appMode));
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

void _seedLiveFenceCache() {
  ApiCache.instance
    ..debugReset()
    ..debugSetInitialized(true)
    ..debugSetMyFarms({
      'activeFarmId': 'tenant_001',
      'farms': [
        {'id': 'tenant_001', 'name': '青山牧场', 'status': 'active'},
      ],
    })
    ..debugSetFences([
      {
        'id': 'fence_pasture_a',
        'name': '放牧A区',
        'type': 'polygon',
        'status': 'active',
        'alarmEnabled': true,
        'coordinates': [
          [112.9400, 28.2340],
          [112.9440, 28.2340],
          [112.9440, 28.2305],
          [112.9400, 28.2305],
        ],
      },
    ]);
}

Future<void> _insertEdgePoint(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('fence-edit-tool-insert')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('fence-edit-edge-0')));
  await tester.pumpAndSettle();
}
