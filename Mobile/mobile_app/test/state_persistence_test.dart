import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('地图筛选条件在路由切换后保持不丢失', (tester) async {
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

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pumpAndSettle();

    final summary = tester.widget<Text>(find.byKey(const Key('map-flow-summary')));
    expect(summary.data, contains('SL-2024-002'));
    expect(summary.data, contains('7d'));
  });
}
