// Widget tests for the estrus detail explanation section (NIX-390 Task 3).
//
// Three data shapes are covered:
//  1. NORMALIZED-V2 with all channels participating,
//  2. capsule fixture without distance (57%/43% activity/temperature),
//  3. no explainable data at all (only the help card remains).
//
// Chinese text assertions require the explicit zh locale (known project
// pitfall), matching the tenant/livestock detail page test precedents.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/anomaly_models.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/ai_anomaly/domain/anomaly_repository.dart';
import 'package:hkt_livestock_agentic/features/ai_anomaly/presentation/anomaly_controller.dart';
import 'package:hkt_livestock_agentic/features/estrus/domain/estrus_repository.dart';
import 'package:hkt_livestock_agentic/features/estrus/presentation/estrus_controller.dart';
import 'package:hkt_livestock_agentic/features/pages/estrus_detail_page.dart';
import 'package:hkt_livestock_agentic/features/subscription/domain/subscription_repository.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakeEstrusRepository implements EstrusRepository {
  _FakeEstrusRepository(this.detail);

  final EstrusDetailData detail;

  @override
  Future<EstrusDetailData> fetchEstrusDetail(String livestockId) async =>
      detail;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  const _FakeSubscriptionRepository();

  @override
  Future<SubscriptionStatus> loadCurrent() async => const SubscriptionStatus(
        id: '1',
        tenantId: '1',
        tier: SubscriptionTier.premium,
        status: 'active',
        livestockCount: 1,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAnomalyRepository implements AnomalyRepository {
  const _FakeAnomalyRepository();

  @override
  Future<AnomalyScoreData> fetchLatest(String livestockId) async =>
      const AnomalyScoreData(anomalyScore: 0, anomalyType: 'normal');

  @override
  Future<List<AnomalyScoreHistoryItem>> fetchHistory(String livestockId,
          {int limit = 20}) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// NORMALIZED-V2 row with all three channels participating.
EstrusDetailData _normalizedFull() => EstrusDetailData(
      livestockId: '10',
      livestockCode: 'ST-10',
      score: 82,
      stepIncreasePercent: 200,
      tempDelta: 0.6,
      timestamp: DateTime.utc(2026, 11, 9, 7, 30),
      featureVersion: 'NORMALIZED-V2',
      baselineUsed: 38.5,
      baselineSource: 'LEARNED',
      baselineComputedAt: DateTime.utc(2026, 11, 6, 18, 0),
      activityRatio: 3.0,
      distanceRatio: 1.4,
      activityScore: 90.0,
      temperatureScore: 72.0,
      distanceScore: 65.0,
      weightActivity: 0.5,
      weightTemperature: 0.3,
      weightDistance: 0.2,
      distanceParticipated: true,
      temperatureParticipated: true,
    );

/// Capsule fixture: distance channel absent, activity/temperature carry
/// 57%/43% of the score.
EstrusDetailData _capsuleNoDistance() => EstrusDetailData(
      livestockId: '10',
      livestockCode: 'ST-10',
      score: 61,
      stepIncreasePercent: 160,
      tempDelta: 0.4,
      timestamp: DateTime.utc(2026, 11, 9, 6, 0),
      featureVersion: 'NORMALIZED-V2',
      baselineUsed: 38.5,
      baselineSource: 'DEFAULT',
      activityRatio: 2.6,
      activityScore: 70.0,
      temperatureScore: 48.0,
      distanceScore: null,
      weightActivity: 0.57,
      weightTemperature: 0.43,
      weightDistance: 0.0,
      distanceParticipated: false,
      temperatureParticipated: true,
    );

Future<void> _pumpPage(WidgetTester tester, EstrusDetailData detail) async {
  tester.view.physicalSize = const Size(1000, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        estrusRepositoryProvider.overrideWithValue(
          _FakeEstrusRepository(detail),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          const _FakeSubscriptionRepository(),
        ),
        anomalyRepositoryProvider.overrideWithValue(
          const _FakeAnomalyRepository(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EstrusDetailPage(livestockId: '10'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('NORMALIZED-V2 全通道:分量+权重渲染、倍数句、LEARNED 基线、标尺指针',
      (tester) async {
    await _pumpPage(tester, _normalizedFull());

    // Breakdown rows: channel names, component scores, weights.
    expect(find.text('评分构成'), findsOneWidget);
    expect(find.text('活动'), findsOneWidget);
    expect(find.text('体温'), findsOneWidget);
    expect(find.text('距离'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('65'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('未参与'), findsNothing);

    // Activity ratio sentence (ratio with one decimal).
    expect(find.text('过去 6 小时活动约为自身平常水平的 3.0 倍'), findsOneWidget);

    // LEARNED baseline with value and compute date.
    expect(find.textContaining('个体学习基线 38.5℃'), findsOneWidget);
    expect(find.textContaining('2026-11-06 18:00 计算'), findsOneWidget);

    // Last assessed timestamp.
    expect(find.text('最后评估：2026-11-09 07:30'), findsOneWidget);

    // Band scale labels and ticks.
    expect(find.text('评分分档'), findsOneWidget);
    expect(find.text('无发情迹象'), findsOneWidget);
    expect(find.text('继续观察'), findsOneWidget);
    expect(find.text('建议 12 小时内配种'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);

    // Pointer sits at the current score fraction (82/100) of the track.
    final trackRect =
        tester.getRect(find.byKey(const Key('estrus-scale-track')));
    final pointerRect =
        tester.getRect(find.byKey(const Key('estrus-scale-pointer')));
    final fraction = (pointerRect.center.dx - trackRect.left) / trackRect.width;
    expect(fraction, closeTo(0.82, 0.03));

    // Score badge carries the numeric score itself (2026-11-10 feedback fix:
    // the pointer is a score-value chip, not a bare triangle).
    expect(
      find.descendant(
          of: find.byKey(const Key('estrus-scale-pointer')),
          matching: find.text('82')),
      findsOneWidget,
    );

    // The band the score falls in is highlighted: act band (>=70) carries the
    // active pill; the other two bands stay plain.
    expect(find.byKey(const Key('estrus-scale-band-active')), findsOneWidget);
    expect(
      find.descendant(
          of: find.byKey(const Key('estrus-scale-band-act')),
          matching: find.byKey(const Key('estrus-scale-band-active'))),
      findsOneWidget,
    );

    // Calibration footnote (data-driven row exists).
    expect(find.text('评分参数：仿真默认'), findsOneWidget);

    // Help card is present and expandable.
    expect(find.text('如何解读'), findsOneWidget);
    await tester.tap(find.text('如何解读'));
    await tester.pumpAndSettle();
    expect(find.textContaining('对比基准是这头牛自身前 3 天'), findsOneWidget);
  });

  testWidgets('胶囊缺距离:距离行未参与态、权重 57%/43%、无 0% 残留', (tester) async {
    await _pumpPage(tester, _capsuleNoDistance());

    // Distance row: "not participating" badge instead of numbers.
    expect(find.text('未参与'), findsOneWidget);
    expect(find.text('57%'), findsOneWidget);
    expect(find.text('43%'), findsOneWidget);
    expect(find.text('0%'), findsNothing);

    // The distance row is grayed out (muted opacity).
    final opacity = tester.widget<Opacity>(
      find.byKey(const Key('estrus-breakdown-distance')),
    );
    expect(opacity.opacity, 0.45);
    final activityOpacity = tester.widget<Opacity>(
      find.byKey(const Key('estrus-breakdown-activity')),
    );
    expect(activityOpacity.opacity, 1.0);

    // Activity ratio sentence still shows (NORMALIZED row).
    expect(find.text('过去 6 小时活动约为自身平常水平的 2.6 倍'), findsOneWidget);

    // DEFAULT baseline without a compute date.
    expect(find.textContaining('默认基线 38.5℃'), findsOneWidget);
    expect(find.textContaining('计算）'), findsNothing);

    // Score 61 lands in the watch band: its label carries the active pill.
    expect(
      find.descendant(
          of: find.byKey(const Key('estrus-scale-band-watch')),
          matching: find.byKey(const Key('estrus-scale-band-active'))),
      findsOneWidget,
    );
  });

  testWidgets('explanation 全 null:构成/基线/倍数句/标尺隐藏,帮助仍在', (tester) async {
    await _pumpPage(
      tester,
      const EstrusDetailData(
        livestockId: '10',
        livestockCode: 'ST-10',
        score: 0,
      ),
    );

    // Data-driven blocks are all hidden.
    expect(find.text('评分构成'), findsNothing);
    expect(find.text('评分分档'), findsNothing);
    expect(find.textContaining('个体学习基线'), findsNothing);
    expect(find.textContaining('默认基线'), findsNothing);
    expect(find.textContaining('倍'), findsNothing);
    expect(find.text('未参与'), findsNothing);
    expect(find.textContaining('最后评估'), findsNothing);
    expect(find.textContaining('评分参数'), findsNothing);

    // The always-on help card remains and expands.
    expect(find.text('如何解读'), findsOneWidget);
    await tester.tap(find.text('如何解读'));
    await tester.pumpAndSettle();
    expect(find.textContaining('对比基准是这头牛自身前 3 天'), findsOneWidget);
    expect(find.textContaining('低分表示当前无发情迹象'), findsOneWidget);
  });
}
