import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('owner 登录后业务导航可到达五页面', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-twin')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-fence')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-alerts')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-mine')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-mine')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-admin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-admin')), findsOneWidget);
  });

  testWidgets('worker 登录后不显示 nav-admin', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-worker')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav-admin')), findsNothing);
  });

  testWidgets('导航栏不含旧地图项', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav-' 'map')), findsNothing);
  });

  testWidgets('围栏页左侧牧场列表打开后标题可见（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-panel-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fence-drawer-title')), findsOneWidget);
  });

  testWidgets('孪生页高保真组件可见（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('twin-farm-header')), findsOneWidget);
    expect(find.byKey(const Key('twin-metric-alert-pending')), findsOneWidget);
  });
}
