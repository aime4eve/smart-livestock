/// integration_test — 租户生命周期(停用/软删/恢复)白屏回归。
///
/// 运行(Chrome,连 dev 后端,平台管理员):
///   flutter test integration_test/tenant_lifecycle_test.dart \
///     -d web-server \
///     --dart-define=APP_MODE=live \
///     --dart-define=API_BASE_URL=http://172.22.1.123:19080/api/v1
///
/// 重点:删除确认后的 `tester.takeException()` 必须为 null——
/// 历史白屏 = 刷新列表时使用已卸载卡片的 WidgetRef 抛 Error(ae0a8716)。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/demo_app.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/app/app_router.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final tenantName = 'SMOKE-UI-DEL-$suffix';

  testWidgets('租户删除:输入名称确认 → 列表刷新无异常 → 租户消失',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DemoApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── 登录(平台管理员) ───────────────────────────────────────────
    await tester.enterText(
        find.byKey(const Key('login-identifier')), '13800000000');
    await tester.enterText(
        find.byKey(const Key('login-password')), '123');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // ── 导航到租户管理 ─────────────────────────────────────────────
    final element = tester.element(find.byType(DemoApp));
    final container =
        ProviderScope.containerOf(element, listen: false);
    container.read(appRouterProvider).go('/ops/admin');
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // ── 前置:通过后端建一个干净租户(不经 UI,保证幂等) ────────────
    // (列表上先能看到它,再走 UI 删除)
    expect(find.text(tenantName), findsNothing);

    // ── 打开卡片菜单 → 删除租户 ────────────────────────────────────
    // 通过列表卡片的三点菜单;先找目标卡片所在行
    // (该租户由下方 API 创建?否——本测试直接走 UI 创建路径之外的
    //  API 前置在建租户一步;这里退化为验证既有 SMOKE 租户存在性,
    //  因此改为:UI 建租户)
    await tester.tap(find.byKey(const Key('tenant-list-create')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.enterText(
        find.byKey(const Key('create-tenant-name')), tenantName);
    await tester.tap(find.byKey(const Key('tenant-create-submit')));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // 列表应出现新租户
    expect(find.text(tenantName), findsOneWidget);

    // ── 卡片菜单 → 删除租户 ────────────────────────────────────────
    // 找到目标卡片的菜单按钮(卡片 key = tenant-<id>,菜单 key =
    // tenant-menu-<id>;id 未知,通过卡片的 menu 图标在目标卡片内定位)
    final cardFinder = find.ancestor(
      of: find.text(tenantName),
      matching: find.byType(HighfiCard),
    );
    // 新租户排在列表尾部,先滚动进视口
    await tester.scrollUntilVisible(
      cardFinder,
      200,
      scrollable: find.byType(Scrollable).first,
      duration: const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(cardFinder, findsOneWidget);
    final iconInCard = find.descendant(
      of: cardFinder,
      matching: find.byIcon(Icons.more_vert),
    );
    expect(iconInCard, findsOneWidget);
    await tester.tap(iconInCard);
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除租户'));
    await tester.pumpAndSettle();

    // ── 输入租户名称确认 → 永久删除 ────────────────────────────────
    await tester.enterText(
        find.byKey(const Key('tenant-delete-confirm-name')), tenantName);
    await tester.tap(find.byKey(const Key('tenant-delete-confirm')));
    await tester.pump(const Duration(milliseconds: 800));

    // ── 白屏回归断言:删除刷新不得抛任何异常 ───────────────────────
    final exception = tester.takeException();
    expect(exception, isNull,
        reason: '删除后列表刷新抛异常(历史白屏根因): $exception');

    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 被删租户从默认列表消失
    expect(find.text(tenantName), findsNothing);
  });
}
