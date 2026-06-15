import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/demo_app.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';

void main() {
  testWidgets('DemoApp 使用 MaterialApp.router 承载声明式路由', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [initialSessionProvider.overrideWithValue(AppSession.loggedOut)],
      child: const DemoApp(),
    ));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.routerConfig, isNotNull);
    expect(app.home, isNull);
  });

  testWidgets('DemoApp 需要 ProviderScope 祖先节点', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [initialSessionProvider.overrideWithValue(AppSession.loggedOut)],
      child: const DemoApp(),
    ));

    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
