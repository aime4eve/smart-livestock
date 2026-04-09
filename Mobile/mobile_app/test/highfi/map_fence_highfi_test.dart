import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';

void main() {
  testWidgets('map and fence highfi actions are available', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map-toolbar-draw-fence')), findsOneWidget);
    expect(find.byKey(const Key('map-layer-fence-toggle')), findsOneWidget);
    expect(find.byKey(const Key('map-livestock-filter')), findsOneWidget);
  });
}
