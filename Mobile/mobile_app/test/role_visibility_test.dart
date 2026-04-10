import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';

void main() {
  testWidgets('高保真登录与后台/我的页面仍保持正确角色边界', (tester) async {
    await tester.pumpWidget(const DemoApp());

    expect(find.byKey(const Key('login-hero-card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('role-ops')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-overview-card')), findsOneWidget);
    expect(find.byKey(const Key('nav-alerts')), findsNothing);
  });

  testWidgets('worker 进入围栏页后不可见编辑/删除按钮', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-worker')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-panel-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-fence')), findsOneWidget);
    expect(find.byKey(const Key('fence-drawer-title')), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-fence_pasture_a')), findsNothing);
    expect(find.byKey(const Key('fence-delete-fence_pasture_a')), findsNothing);
    expect(find.byKey(const Key('fence-add')), findsNothing);
  });

  testWidgets('owner 进入围栏页后可见编辑/删除/新增按钮', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-panel-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-fence')), findsOneWidget);
    await tester.ensureVisible(
        find.byKey(const Key('fence-edit-fence_pasture_a')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fence-edit-fence_pasture_a')), findsOneWidget);
    expect(find.byKey(const Key('fence-delete-fence_pasture_a')), findsOneWidget);
    expect(find.byKey(const Key('fence-add')), findsOneWidget);
  });

  testWidgets('owner 可进入我的页并看到高保真个人卡片', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-mine')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mine-profile-card')), findsOneWidget);
  });

  testWidgets('ops 登录后进入租户后台且不显示围栏元素', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-ops')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('租户后台占位'), findsOneWidget);
    expect(find.byKey(const Key('nav-fence')), findsNothing);
    expect(find.byKey(const Key('page-fence')), findsNothing);
  });

  test('ops 角色枚举存在', () {
    expect(DemoRole.values, contains(DemoRole.ops));
  });
}
