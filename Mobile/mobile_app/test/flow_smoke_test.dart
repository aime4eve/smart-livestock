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

  testWidgets('流程4a：围栏页显示抽屉标题和围栏卡片（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-drawer-title')), findsOneWidget);
    expect(find.byKey(const Key('fence-card-fence_pasture_a')), findsOneWidget);
    expect(find.byKey(const Key('fence-add')), findsOneWidget);
  });

  testWidgets('流程4b：围栏新增跳转表单页再返回（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fence-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-fence-form')), findsOneWidget);
    expect(find.text('新建围栏'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fence-form-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-fence')), findsOneWidget);
  });

  testWidgets('流程4c：围栏删除弹窗确认后移除（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-card-fence_pasture_a')), findsOneWidget);

    await tester.ensureVisible(
        find.byKey(const Key('fence-delete-fence_pasture_a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-delete-fence_pasture_a')));
    await tester.pumpAndSettle();

    expect(find.text('确认删除'), findsOneWidget);
    expect(find.text('确认删除「放牧A区」？删除后无法恢复。'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fence-delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-card-fence_pasture_a')), findsNothing);
    expect(find.text('已删除「放牧A区」'), findsOneWidget);
  });

  testWidgets('流程4d：租户 license 调整演示反馈（owner）', (tester) async {
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
