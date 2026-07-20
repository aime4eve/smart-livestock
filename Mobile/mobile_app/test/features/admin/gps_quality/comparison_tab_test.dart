import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/comparison_tab.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakeRepo extends GpsQualityApiRepository {
  int? lastRouteId;

  @override
  Future<DynamicComparisonResult> fetchDynamicComparison(int routeId) async {
    lastRouteId = routeId;
    return DynamicComparisonResult(
      routeId: routeId,
      routeName: '线路1',
      devices: [
        DynamicComparisonRow(
          deviceId: 12,
          deviceCode: 'DEV-GPS-001',
          eui: '847A000000000F03',
          checkId: 64,
          coverage: 83.3,
          matchedCount: 5,
          missedCount: 1,
          ambiguousCount: 0,
          inOrder: true,
          meanError: 7.8,
          p50: 6.2,
          p95: 12.1,
          startedAt: DateTime.utc(2026, 7, 18, 9),
          endedAt: DateTime.utc(2026, 7, 18, 10),
        ),
        DynamicComparisonRow(
          deviceId: 13,
          deviceCode: 'DEV-GPS-002',
          eui: 'A2B4000000000C19',
          checkId: 65,
          coverage: 100.0,
          matchedCount: 6,
          missedCount: 0,
          ambiguousCount: 0,
          inOrder: true,
          meanError: 5.0,
          p50: 4.0,
          p95: 8.0,
          startedAt: DateTime.utc(2026, 7, 18, 9),
          endedAt: DateTime.utc(2026, 7, 18, 9, 50),
        ),
      ],
    );
  }
}

class _FakeRtkPoints extends RtkPointsController {
  @override
  Future<List<RtkPoint>> build() async => [];
}

class _FakeRoutes extends DynamicRoutesController {
  @override
  Future<List<DynamicRoute>> build() async => [
        DynamicRoute(
          id: 5,
          name: '线路1',
          createdAt: DateTime.utc(2026, 7, 1),
          updatedAt: DateTime.utc(2026, 7, 1),
        ),
      ];
}

void main() {
  testWidgets('选择动态路线后展示多设备动态对比表', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        rtkPointsProvider.overrideWith(() => _FakeRtkPoints()),
        dynamicRoutesProvider.overrideWith(() => _FakeRoutes()),
        gpsQualityApiRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ComparisonTab()),
      ),
    ));
    await tester.pumpAndSettle();

    // 切换到动态对比
    await tester.tap(find.text('动态'));
    await tester.pumpAndSettle();
    expect(find.text('请选择一条路线查看动态对比'), findsOneWidget);

    // 选择路线
    await tester.tap(find.byKey(const Key('dynamic-route-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DropdownMenuItem<int>, '线路1').last);
    await tester.pumpAndSettle();

    expect(repo.lastRouteId, 5);
    expect(find.byKey(const Key('dynamic-comparison-table')), findsOneWidget);
    expect(find.text('DEV-GPS-001'), findsOneWidget);
    expect(find.text('DEV-GPS-002'), findsOneWidget);
    expect(find.text('83.3%'), findsOneWidget);
    expect(find.text('100.0%'), findsOneWidget);
    expect(find.text('7.8m'), findsOneWidget);
  });
}
