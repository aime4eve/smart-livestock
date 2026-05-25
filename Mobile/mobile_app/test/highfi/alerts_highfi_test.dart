import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('alerts page shows p0 categories and flow', (tester) async {
    await pumpAppWithRole(tester, UserRole.owner);

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('alert-type-fence-breach')), findsOneWidget);
    expect(find.byKey(const Key('alert-type-battery-low')), findsOneWidget);
    expect(find.byKey(const Key('alert-type-signal-lost')), findsOneWidget);
  });
}
