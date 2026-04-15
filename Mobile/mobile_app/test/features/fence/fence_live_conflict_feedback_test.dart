import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';

void main() {
  setUp(() {
    ApiCache.instance.createFenceRemoteOverride = null;
    ApiCache.instance.updateFenceRemoteOverride = null;
    ApiCache.instance.lastFenceSaveStatusCode = null;
  });

  tearDown(() {
    ApiCache.instance.createFenceRemoteOverride = null;
    ApiCache.instance.updateFenceRemoteOverride = null;
    ApiCache.instance.lastFenceSaveStatusCode = null;
  });

  test('状态码映射包含 409/422/default', () {
    expect(fenceSaveErrorMessageForStatusCode(409), '围栏已被其他人更新，请刷新后重试');
    expect(fenceSaveErrorMessageForStatusCode(422), '数据校验失败，请检查后重试');
    expect(fenceSaveErrorMessageForStatusCode(500), '保存失败，请稍后重试');
    expect(fenceSaveErrorMessageForStatusCode(null), '保存失败，请稍后重试');
  });

  testWidgets('live 编辑保存返回 409 时停留在编辑态并显示冲突提示', (tester) async {
    ApiCache.instance.updateFenceRemoteOverride = (role, id, body) async {
      return const FenceSaveResult(ok: false, statusCode: 409);
    };

    await tester.pumpWidget(const DemoApp(appMode: AppMode.live));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-panel-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-card-fence_pasture_a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-start-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-edit-tool-insert')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-edit-edge-0')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fence-edit-save')));
    await tester.pumpAndSettle();

    expect(find.text('围栏已被其他人更新，请刷新后重试'), findsOneWidget);
    expect(find.byKey(const Key('fence-edit-overlay')), findsOneWidget);
  });
}
