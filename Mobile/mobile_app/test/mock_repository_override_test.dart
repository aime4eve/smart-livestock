import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/presentation/dashboard_controller.dart';
import 'package:smart_livestock_demo/features/map/domain/map_repository.dart';
import 'package:smart_livestock_demo/features/map/presentation/map_controller.dart';

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

  testWidgets('Map 可通过仓储 override 注入自定义摘要与回退列表', (tester) async {
    await tester.pumpWidget(
      DemoApp(
        overrides: [
          mapRepositoryProvider.overrideWithValue(const _FakeMapRepository()),
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('role-owner')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pumpAndSettle();

    expect(find.text('自定义地图摘要'), findsOneWidget);

    final mapCtx = tester.element(find.byKey(const Key('page-map')));
    ProviderScope.containerOf(mapCtx)
        .read(mapControllerProvider.notifier)
        .setViewState(ViewState.error);
    await tester.pumpAndSettle();

    expect(find.text('自定义回退项'), findsOneWidget);
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

class _FakeMapRepository implements MapRepository {
  const _FakeMapRepository();

  @override
  MapViewData load({
    required ViewState viewState,
    required String selectedAnimal,
    required TrajectoryRange selectedRange,
  }) {
    return MapViewData(
      viewState: viewState,
      availableAnimals: const ['耳标-X'],
      selectedAnimal: '耳标-X',
      selectedRange: TrajectoryRange.d30,
      summaryText: '自定义地图摘要',
      fallbackItems: const ['自定义回退项'],
      mapCenter: const LatLng(30.25, 120.15),
      zoom: 13.0,
      livestockLocations: const [],
      trajectoryPoints: const [],
      fences: const [],
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '空态',
        ViewState.error => '错误态',
        ViewState.forbidden => '无权限',
        ViewState.offline => '离线',
        ViewState.normal => null,
      },
    );
  }
}
