import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_widget.dart';

void main() {
  testWidgets('owner 登录后显示 farm switcher', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('farm-switcher')), findsOneWidget);
  });

  testWidgets('worker 登录后显示 farm switcher', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-worker')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('farm-switcher')), findsOneWidget);
  });

  testWidgets('owner 切到围栏页后仍显示 farm switcher', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('farm-switcher')), findsOneWidget);
  });

  testWidgets('非 farm 角色不显示 farm switcher', (tester) async {
    for (final roleKey in [
      const Key('role-platform-admin'),
      const Key('role-b2b-admin'),
      const Key('role-api-consumer'),
    ]) {
      await tester.pumpWidget(DemoApp(key: UniqueKey()));

      await tester.tap(find.byKey(roleKey));
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('farm-switcher')), findsNothing);
    }
  });

  testWidgets('owner 无 farm 时显示引导并隐藏 switcher', (tester) async {
    await tester.pumpWidget(const DemoApp(appMode: AppMode.live));

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('farm-switcher')), findsNothing);
    expect(find.byKey(const Key('farm-empty-guidance')), findsOneWidget);
    expect(find.text('请创建您的第一个牧场'), findsOneWidget);
  });

  testWidgets('FarmSwitcher 切换 farm 时调用 controller', (tester) async {
    final switchedFarmIds = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmSwitcherControllerProvider.overrideWith(
            () => _TestFarmSwitcherController(
              switchedFarmIds: switchedFarmIds,
              initialState: const FarmSwitcherState(
                farms: [
                  FarmInfo(id: 'tenant_001', name: '青山牧场', status: 'active'),
                  FarmInfo(id: 'tenant_007', name: '河谷牧场', status: 'active'),
                ],
                activeFarmId: 'tenant_001',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [FarmSwitcher()]),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('farm-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('河谷牧场').last);
    await tester.pumpAndSettle();

    expect(switchedFarmIds, ['tenant_007']);
  });

  testWidgets('FarmSwitcher 在单 farm 时隐藏', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmSwitcherControllerProvider.overrideWith(
            () => _TestFarmSwitcherController(
              switchedFarmIds: <String>[],
              initialState: const FarmSwitcherState(
                farms: [
                  FarmInfo(id: 'tenant_001', name: '青山牧场', status: 'active'),
                ],
                activeFarmId: 'tenant_001',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [FarmSwitcher()]),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('farm-switcher')), findsNothing);
  });
}

class _TestFarmSwitcherController extends FarmSwitcherController {
  _TestFarmSwitcherController({
    required this.switchedFarmIds,
    required this.initialState,
  });

  final List<String> switchedFarmIds;
  final FarmSwitcherState initialState;

  @override
  FarmSwitcherState build() => initialState;

  @override
  void switchFarm(String farmId) {
    switchedFarmIds.add(farmId);
    state = FarmSwitcherState(farms: state.farms, activeFarmId: farmId);
  }
}
