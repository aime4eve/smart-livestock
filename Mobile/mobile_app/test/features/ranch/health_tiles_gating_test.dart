import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/health_scene_tile.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

// NIX-389 widget tests for the server-driven three-state health tiles:
// OPEN renders the data card, LOCKED the lock pill + upgrade foot with the
// name kept, HIDDEN drops the tile entirely (no empty slot). Calving-tile
// navigation and locked-tile navigation are covered too.

TwinSceneSummary _scene({
  int feverAbnormal = 0,
  int feverElevated = 0,
  int feverCritical = 0,
  int digestiveAbnormal = 0,
  int estrusHigh = 0,
  double epiRate = 0.0,
}) {
  return TwinSceneSummary(
    fever: SceneSummaryFever(
      abnormalCount: feverAbnormal,
      criticalCount: feverCritical,
      elevatedCount: feverElevated,
    ),
    digestive: SceneSummaryDigestive(
      abnormalCount: digestiveAbnormal,
      watchCount: 0,
    ),
    estrus: SceneSummaryEstrus(
      highScoreCount: estrusHigh,
      breedingAdvice: false,
    ),
    epidemic: SceneSummaryEpidemic(status: 'Normal', abnormalRate: epiRate),
  );
}

const _allOpen = RanchSceneGating.allOpen();

GoRouter _router(List<Widget> Function(BuildContext) buildTiles) {
  return GoRouter(
    initialLocation: '/ranch',
    routes: [
      GoRoute(
        path: '/ranch',
        builder: (context, _) => Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: buildTiles(context),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/twin/calving-predictions',
        builder: (_, _) =>
            const Scaffold(body: Text('CALVING_PREDICTIONS_PAGE')),
      ),
      GoRoute(
        path: '/twin/scene-locked',
        builder: (_, state) => Scaffold(
          body: Text('SCENE_LOCKED:${state.uri.queryParameters['scene']}'),
        ),
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  List<Widget> Function(BuildContext) buildTiles,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router(buildTiles),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('OPEN tiles render the data cards (fever pill + calving foot)',
      (tester) async {
    await _pump(
      tester,
      (context) => buildHealthSceneTiles(
        context,
        scene: _scene(feverAbnormal: 2),
        gating: _allOpen,
        calving: const RanchSceneSummaryCalving(highRiskCount: 1, watchCount: 2),
        feverOver6h: 0,
      ),
    );
    // Data cards: the fever pill shows the abnormal head count, the calving
    // tile shows its high-risk pill and count foot.
    expect(find.text('2 只异常'), findsOneWidget);
    expect(find.text('分娩预警'), findsOneWidget);
    expect(find.text('1 只临产'), findsOneWidget);
    expect(find.text('1 只临产风险，留意助产准备'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets(
      'LOCKED tiles render the lock pill + upgrade foot with the name kept',
      (tester) async {
    await _pump(
      tester,
      (context) => buildHealthSceneTiles(
        context,
        scene: _scene(estrusHigh: 3),
        gating: const RanchSceneGating(
          fever: SceneGatingState.open,
          digestive: SceneGatingState.open,
          estrus: SceneGatingState.locked,
          epidemic: SceneGatingState.open,
          ai: SceneGatingState.open,
          calving: SceneGatingState.open,
        ),
        calving: RanchSceneSummaryCalving.zero,
        feverOver6h: 0,
      ),
    );
    // Same geometry, name kept; pill swapped for the lock style.
    expect(find.text('发情管理'), findsOneWidget);
    expect(find.text('锁定'), findsOneWidget);
    expect(find.text('升级订阅后解锁'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    // The data pill must NOT be rendered for a locked scene.
    expect(find.text('3 只高分'), findsNothing);
  });

  testWidgets('HIDDEN tiles are dropped entirely (no empty slot)',
      (tester) async {
    await _pump(
      tester,
      (context) => buildHealthSceneTiles(
        context,
        scene: _scene(feverAbnormal: 2),
        gating: const RanchSceneGating(
          fever: SceneGatingState.open,
          digestive: SceneGatingState.open,
          estrus: SceneGatingState.hidden,
          epidemic: SceneGatingState.hidden,
          ai: SceneGatingState.open,
          calving: SceneGatingState.hidden,
        ),
        calving: const RanchSceneSummaryCalving(highRiskCount: 1, watchCount: 0),
        feverOver6h: 0,
      ),
    );
    // 5 grid tiles - 3 hidden = 2 tiles (the AI card is a separate row).
    expect(find.byType(HealthSceneTile), findsNWidgets(2));
    expect(find.text('发情管理'), findsNothing);
    expect(find.text('疫病防控'), findsNothing);
    expect(find.text('分娩预警'), findsNothing);
    expect(find.text('2 只异常'), findsOneWidget);
  });

  testWidgets('OPEN calving tile navigates to the calving predictions page',
      (tester) async {
    await _pump(
      tester,
      (context) => buildHealthSceneTiles(
        context,
        scene: _scene(),
        gating: _allOpen,
        calving: const RanchSceneSummaryCalving(highRiskCount: 1, watchCount: 0),
        feverOver6h: 0,
      ),
    );
    await tester.tap(find.text('分娩预警'));
    await tester.pumpAndSettle();
    expect(find.text('CALVING_PREDICTIONS_PAGE'), findsOneWidget);
  });

  testWidgets('LOCKED tile navigates to the scene-locked page with scene key',
      (tester) async {
    await _pump(
      tester,
      (context) => buildHealthSceneTiles(
        context,
        scene: _scene(),
        gating: const RanchSceneGating(
          fever: SceneGatingState.open,
          digestive: SceneGatingState.open,
          estrus: SceneGatingState.locked,
          epidemic: SceneGatingState.open,
          ai: SceneGatingState.open,
          calving: SceneGatingState.open,
        ),
        calving: RanchSceneSummaryCalving.zero,
        feverOver6h: 0,
      ),
    );
    await tester.tap(find.text('发情管理'));
    await tester.pumpAndSettle();
    expect(find.text('SCENE_LOCKED:estrus'), findsOneWidget);
  });
}
