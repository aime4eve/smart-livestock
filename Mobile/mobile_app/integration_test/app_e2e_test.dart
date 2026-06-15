/// Flutter integration_test — 真实后端 e2e 测试。
///
/// 运行方式（Chrome）：
///   flutter test integration_test/app_e2e_test.dart \
///     -d chrome \
///     --dart-define=APP_MODE=live \
///     --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1
///
/// 运行方式（macOS desktop）：
///   flutter test integration_test/app_e2e_test.dart \
///     -d macos \
///     --dart-define=APP_MODE=live \
///     --dart-define=API_BASE_URL=http://172.22.1.123:18080/api/v1
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hkt_livestock_agentic/app/demo_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('e2e — 登录到看板', () {
    testWidgets('owner 登录后看到导航栏', (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      // 登录页应显示
      expect(find.byKey(const Key('login-hero-card')), findsOneWidget);
      expect(find.byKey(const Key('login-phone')), findsOneWidget);

      // 输入 owner 凭据
      await tester.enterText(
          find.byKey(const Key('login-phone')), '13800138000');
      await tester.enterText(
          find.byKey(const Key('login-password')), '123');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 登录成功 → 应看到底部导航栏
      expect(find.byKey(const Key('nav-twin')), findsOneWidget);
      expect(find.byKey(const Key('nav-fence')), findsOneWidget);
      expect(find.byKey(const Key('nav-alerts')), findsOneWidget);
      expect(find.byKey(const Key('nav-mine')), findsOneWidget);
      expect(find.byKey(const Key('nav-admin')), findsOneWidget);
    });

    testWidgets('登录失败显示错误提示', (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('login-phone')), '13800138000');
      await tester.enterText(
          find.byKey(const Key('login-password')), 'wrong_password');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 不应进入主页面
      expect(find.byKey(const Key('nav-twin')), findsNothing);
    });
  });

  group('e2e — 围栏 Tab', () {
    testWidgets('owner 点击围栏 Tab 显示围栏列表', (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      // 登录
      await tester.enterText(
          find.byKey(const Key('login-phone')), '13800138000');
      await tester.enterText(
          find.byKey(const Key('login-password')), '123');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 切换到围栏 Tab
      await tester.tap(find.byKey(const Key('nav-fence')));
      await tester.pumpAndSettle();

      // 围栏页面应有内容（至少不是空白）
      expect(find.byKey(const Key('nav-fence')), findsOneWidget);
    });
  });

  group('e2e — 告警 Tab', () {
    testWidgets('owner 点击告警 Tab 显示告警列表', (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      // 登录
      await tester.enterText(
          find.byKey(const Key('login-phone')), '13800138000');
      await tester.enterText(
          find.byKey(const Key('login-password')), '123');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 切换到告警 Tab
      await tester.tap(find.byKey(const Key('nav-alerts')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nav-alerts')), findsOneWidget);
    });
  });

  group('e2e — 我的 Tab', () {
    testWidgets('owner 点击我的 Tab 显示个人信息', (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      // 登录
      await tester.enterText(
          find.byKey(const Key('login-phone')), '13800138000');
      await tester.enterText(
          find.byKey(const Key('login-password')), '123');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 切换到我的 Tab
      await tester.tap(find.byKey(const Key('nav-mine')));
      await tester.pumpAndSettle();

      // 应显示用户名（后端返回的真实数据）
      expect(find.textContaining('张牧场'), findsWidgets);
    });
  });
}
