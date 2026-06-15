import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('worker 登录后不显示 nav-admin', (tester) async {
    await pumpAppWithRole(tester, UserRole.worker);

    expect(find.byKey(const Key('nav-admin')), findsNothing);
  });

  testWidgets('导航栏不含旧地图项', (tester) async {
    await pumpAppWithRole(tester, UserRole.owner);

    expect(find.byKey(const Key('nav-map')), findsNothing);
  });

  testWidgets('owner 导航栏包含牧场和我的两个 Tab', (tester) async {
    await pumpAppWithRole(tester, UserRole.owner);

    expect(find.byKey(const Key('nav-ranch')), findsOneWidget);
    expect(find.byKey(const Key('nav-mine')), findsOneWidget);
    // 旧 Tab 已合并
    expect(find.byKey(const Key('nav-twin')), findsNothing);
    expect(find.byKey(const Key('nav-fence')), findsNothing);
    expect(find.byKey(const Key('nav-alerts')), findsNothing);
  });
}
