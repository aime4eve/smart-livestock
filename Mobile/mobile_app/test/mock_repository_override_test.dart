import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  testWidgets('Dashboard 可通过仓储 override 注入自定义指标', (tester) async {
    await tester.pumpWidget(
      DemoApp(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            const _FakeDashboardRepository(),
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byKey(const Key('page-twin')));
    GoRouter.of(ctx).go('/dashboard');
    await tester.pumpAndSettle();

    expect(find.text('自定义指标'), findsOneWidget);
    expect(find.text('999'), findsOneWidget);
  });

  testWidgets('Fence 可通过仓储 override 注入自定义围栏列表', (tester) async {
    await tester.pumpWidget(
      DemoApp(
        overrides: [
          fenceRepositoryProvider.overrideWithValue(
            const _FakeFenceRepository(),
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-fence')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-panel-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('测试围栏'), findsOneWidget);
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  const _FakeDashboardRepository();

  @override
  DashboardViewData load(ViewState viewState) {
    return const DashboardViewData(
      viewState: ViewState.normal,
      metrics: [
        DashboardMetric(
          widgetKey: 'dashboard-metric-custom',
          title: '自定义指标',
          value: '999',
        ),
      ],
    );
  }
}

class _FakeFenceRepository implements FenceRepository {
  const _FakeFenceRepository();

  @override
  List<FenceItem> loadAll() {
    return const [
      FenceItem(
        id: 'fake-fence-1',
        name: '测试围栏',
        type: FenceType.rectangle,
        alarmEnabled: true,
        active: true,
        areaHectares: 5.0,
        livestockCount: 10,
        colorValue: 0xFF4C9A5F,
        points: [
          LatLng(28.230, 112.940),
          LatLng(28.230, 112.944),
          LatLng(28.234, 112.944),
          LatLng(28.234, 112.940),
        ],
      ),
    ];
  }
}
