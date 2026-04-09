import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('流程3：告警 确认→处理→归档（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alert-confirm')));
    await tester.pump();
    expect(find.byKey(const Key('alert-status-confirmed')), findsOneWidget);

    await tester.tap(find.byKey(const Key('alert-handle')));
    await tester.pump();
    expect(find.byKey(const Key('alert-status-handled')), findsOneWidget);

    await tester.tap(find.byKey(const Key('alert-archive')));
    await tester.pump();
    expect(find.byKey(const Key('alert-status-archived')), findsOneWidget);
  });

  testWidgets('流程3b：告警批量处理给出演示反馈（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alert-batch')));
    await tester.pumpAndSettle();

    expect(find.text('演示：批量处理待接入'), findsOneWidget);
  });

  testWidgets('流程2：地图 筛选牲畜与切换回放区间', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('map-animal-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SL-2024-002').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('7d'));
    await tester.pumpAndSettle();

    final summary =
        tester.widget<Text>(find.byKey(const Key('map-flow-summary')));
    expect(summary.data, contains('SL-2024-002'));
    expect(summary.data, contains('7d'));
  });

  testWidgets('流程4a：围栏编辑演示反馈（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('围栏'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fence-edit-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-flow-edit-saved')), findsOneWidget);
  });

  testWidgets('流程4c：围栏新增与删除给出演示反馈（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('围栏'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fence-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-fence-create')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fence-create-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fence-delete')));
    await tester.pumpAndSettle();
    expect(find.text('演示：删除围栏待接入'), findsOneWidget);
  });

  testWidgets('流程4d：围栏分组、模板与图层可演示（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-layer-fence-toggle')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();
    expect(find.text('矩形'), findsOneWidget);
    expect(find.byKey(const Key('fence-group-chip')), findsOneWidget);
  });

  testWidgets('流程4b：租户 license 调整演示反馈（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-admin')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tenant-license-adjust')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('tenant-license-demo-applied')), findsOneWidget);
  });

  testWidgets('流程1：登录后角色分流（worker 无后台 tab）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-worker')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav-admin')), findsNothing);
  });

  testWidgets('流程1：ops 直达租户后台', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-ops')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('租户后台占位'), findsOneWidget);
    expect(find.byKey(const Key('nav-alerts')), findsNothing);
  });
}
