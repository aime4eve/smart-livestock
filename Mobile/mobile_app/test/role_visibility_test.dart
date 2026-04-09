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

  testWidgets('点击 role-worker -> 登录 -> 进入围栏页且不可见编辑按钮', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-worker')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('围栏'));
    await tester.pumpAndSettle();

    expect(find.text('围栏页'), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-action')), findsNothing);
  });

  testWidgets('owner 登录后 fence-edit-action 可见', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('围栏'));
    await tester.pumpAndSettle();

    expect(find.text('围栏页'), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-action')), findsOneWidget);
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

  testWidgets('ops 登录后进入租户后台占位且不显示业务端围栏元素', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-ops')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('租户后台占位'), findsOneWidget);
    expect(find.text('围栏'), findsNothing);
    expect(find.text('围栏页'), findsNothing);
    expect(find.byKey(const Key('fence-edit-action')), findsNothing);
  });

  test('ops 角色枚举存在', () {
    expect(DemoRole.values, contains(DemoRole.ops));
  });
}
