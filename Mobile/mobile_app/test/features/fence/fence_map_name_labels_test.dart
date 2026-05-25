import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('浏览态地图展示各围栏名称标签', (tester) async {
    await pumpAppWithRole(tester, UserRole.owner);
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('fence-map-name-fence_pasture_a')),
      findsOneWidget,
    );
    expect(find.text('放牧A区'), findsWidgets);

    expect(
      find.byKey(const Key('fence-map-name-fence_pasture_b')),
      findsOneWidget,
    );
    expect(find.text('放牧B区'), findsWidgets);
  });
}
