import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/ranch_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/health_bottom_sheet.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Regression test for NIX-8: clicking the peek handle must cycle all three
/// snap states (peek → half → full → half → peek) instead of skipping half,
/// and dragging must move the panel one step in the drag direction.
void main() {
  final overview = RanchOverview.fromJson({
    'overallStats': {
      'totalLivestock': 10,
      'healthyRate': 0.9,
      'alertCount': 0,
      'criticalCount': 0,
      'deviceOnlineRate': 1.0,
      'inFenceRate': 0.9,
    },
    'sceneSummary': {
      'fever': {'abnormalCount': 0, 'criticalCount': 0},
      'digestive': {'abnormalCount': 0, 'watchCount': 0},
      'estrus': {'highScoreCount': 0},
      'epidemic': {'abnormalRate': 0},
    },
  });

  // parentHeight in the default 800x600 test viewport:
  //   600 - padding.top(0) - kToolbarHeight(56) = 544
  const parentHeight = 544.0;
  const peekH = 56.0;
  const halfH = parentHeight * 0.45; // 244.8
  const fullH = parentHeight * 0.92; // 500.48

  Finder panelFinder() => find.byKey(const ValueKey('health_sheet_panel'));
  double panelHeight(WidgetTester tester) =>
      tester.getSize(panelFinder()).height;

  /// Centre of the 56px drag handle at the top of the panel.
  Offset handleCenter(WidgetTester tester) {
    final topLeft = tester.getTopLeft(panelFinder());
    final width = tester.getSize(panelFinder()).width;
    return topLeft + Offset(width / 2, peekH / 2);
  }

  /// Drags the handle by [delta] in several small steps so the gesture arena
  /// recognises the drag early (matching real pointer behaviour; a single
  /// jump would be recognised at the end position, yielding zero displacement).
  Future<void> dragPanel(WidgetTester tester, Offset delta) async {
    final gesture = await tester.startGesture(handleCenter(tester));
    const steps = 10;
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(delta / steps.toDouble());
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  Future<void> tapHandle(WidgetTester tester) async {
    await tester.tapAt(handleCenter(tester));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider
              .overrideWith(() => _FakeSessionController()),
          ranchControllerProvider.overrideWith(() => _FakeRanchController()),
        ],
        child: MaterialApp(
          home: Scaffold(body: HealthBottomSheet(overview: overview)),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('tap cycles peek → half → full → half → peek', (tester) async {
    await pumpSheet(tester);
    expect(panelHeight(tester), closeTo(peekH, 0.5));

    await tapHandle(tester);
    expect(panelHeight(tester), closeTo(halfH, 0.5), reason: 'peek→half');

    await tapHandle(tester);
    expect(panelHeight(tester), closeTo(fullH, 0.5), reason: 'half→full');

    // Previously broken: full jumped straight back to peek, skipping half.
    await tapHandle(tester);
    expect(panelHeight(tester), closeTo(halfH, 0.5), reason: 'full→half');

    await tapHandle(tester);
    expect(panelHeight(tester), closeTo(peekH, 0.5), reason: 'half→peek');
  });

  testWidgets('drag down from full → half → peek', (tester) async {
    await pumpSheet(tester);
    // Expand to full first via taps.
    await tapHandle(tester);
    await tapHandle(tester);
    expect(panelHeight(tester), closeTo(fullH, 0.5));

    await dragPanel(tester, const Offset(0, 120));
    expect(panelHeight(tester), closeTo(halfH, 0.5), reason: 'drag down full→half');

    await dragPanel(tester, const Offset(0, 120));
    expect(panelHeight(tester), closeTo(peekH, 0.5), reason: 'drag down half→peek');
  });

  testWidgets('drag up from peek → half → full', (tester) async {
    await pumpSheet(tester);
    expect(panelHeight(tester), closeTo(peekH, 0.5));

    await dragPanel(tester, const Offset(0, -120));
    expect(panelHeight(tester), closeTo(halfH, 0.5), reason: 'drag up peek→half');

    await dragPanel(tester, const Offset(0, -120));
    expect(panelHeight(tester), closeTo(fullH, 0.5), reason: 'drag up half→full');
  });

  testWidgets('drag direction syncs with subsequent taps', (tester) async {
    await pumpSheet(tester);
    // Expand to full via taps.
    await tapHandle(tester);
    await tapHandle(tester);
    expect(panelHeight(tester), closeTo(fullH, 0.5));

    // Drag down once (full → half): direction is now "collapsing".
    await dragPanel(tester, const Offset(0, 120));
    expect(panelHeight(tester), closeTo(halfH, 0.5));

    // Next tap should continue collapsing (half → peek), not jump back to full.
    await tapHandle(tester);
    expect(panelHeight(tester), closeTo(peekH, 0.5), reason: 'tap after drag continues collapsing');
  });
}

class _FakeSessionController extends SessionController {
  @override
  AppSession build() => const AppSession.authenticated(
        role: UserRole.owner,
        accessToken: 'test-token',
        userId: 1,
        userName: 'Test User',
        phone: '13800138000',
        tenantId: 1,
        username: 'testuser',
        activeFarmId: '1',
      );
}

class _FakeRanchController extends RanchController {
  // drillLevel already defaults to dashboard; the widget receives the overview
  // via its constructor and only reads `drillLevel` from the notifier.
  @override
  Future<RanchOverview> build() async => RanchOverview.fromJson({
        'overallStats': {
          'totalLivestock': 10,
          'healthyRate': 0.9,
          'alertCount': 0,
          'criticalCount': 0,
          'deviceOnlineRate': 1.0,
          'inFenceRate': 0.9,
        },
        'sceneSummary': {
          'fever': {'abnormalCount': 0, 'criticalCount': 0},
          'digestive': {'abnormalCount': 0, 'watchCount': 0},
          'estrus': {'highScoreCount': 0},
          'epidemic': {'abnormalRate': 0},
        },
      });
}
