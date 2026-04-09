import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('owner 登录后业务导航可到达六页面（优先使用导航 Key）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('page-twin')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-map')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-alerts')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-mine')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-mine')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-fence')), findsOneWidget);

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

  testWidgets('核心操作入口按 Key 可见（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('twin-metric-alert-pending')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-range-toggle')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-admin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tenant-license-adjust')), findsOneWidget);
  });

  testWidgets('高保真标杆页关键块完整（owner）', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('twin-farm-header')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-toolbar-draw-fence')), findsOneWidget);
    expect(find.byKey(const Key('map-layer-fence-toggle')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('alert-type-fence-breach')), findsOneWidget);
    expect(find.byKey(const Key('alert-type-battery-low')), findsOneWidget);
    expect(find.byKey(const Key('alert-type-signal-lost')), findsOneWidget);
  });
}
