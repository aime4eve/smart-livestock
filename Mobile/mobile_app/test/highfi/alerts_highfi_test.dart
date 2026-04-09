import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('alerts page shows p0 categories and flow', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('alert-type-fence-breach')), findsOneWidget);
    expect(find.byKey(const Key('alert-type-battery-low')), findsOneWidget);
    expect(find.byKey(const Key('alert-type-signal-lost')), findsOneWidget);
  });
}
