import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('DemoApp 使用 MaterialApp.router 承载声明式路由', (tester) async {
    await tester.pumpWidget(const DemoApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.routerConfig, isNotNull);
    expect(app.home, isNull);
  });

  testWidgets('DemoApp 根节点提供统一 ProviderScope', (tester) async {
    await tester.pumpWidget(const DemoApp());

    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
