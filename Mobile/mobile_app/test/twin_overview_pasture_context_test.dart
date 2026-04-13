import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('孪生概览展示当前演示牧区与 50 头上下文', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('twin-pasture-context')), findsOneWidget);
    expect(find.textContaining('50'), findsWidgets);
    expect(find.textContaining('集团孪生'), findsOneWidget);
  });
}
