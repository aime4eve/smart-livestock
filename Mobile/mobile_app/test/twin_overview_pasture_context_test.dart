import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('孪生概览展示当前演示牧区与 50 头上下文', (tester) async {
    await pumpAppWithRole(tester, UserRole.owner);

    expect(find.byKey(const Key('twin-pasture-context')), findsOneWidget);
    expect(find.textContaining('50'), findsWidgets);
    expect(find.textContaining('集团孪生'), findsOneWidget);
  });
}
