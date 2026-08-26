// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/digestive/domain/digestive_repository.dart';
import 'package:hkt_livestock_agentic/features/digestive/presentation/digestive_controller.dart';
import 'package:hkt_livestock_agentic/features/estrus/domain/estrus_repository.dart';
import 'package:hkt_livestock_agentic/features/estrus/presentation/estrus_controller.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/domain/fever_repository.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/presentation/fever_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/features/pages/livestock_detail_page.dart';
import 'package:hkt_livestock_agentic/features/subscription/domain/subscription_repository.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakeLivestockRepository implements LivestockRepository {
  @override
  Future<LivestockDetail> loadDetail(String id) async => _detail();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<SubscriptionStatus> loadCurrent() async => const SubscriptionStatus(
        id: '1',
        tenantId: '1',
        tier: SubscriptionTier.premium,
        status: 'active',
        livestockCount: 1,
        calculatedDeviceFee: 0,
        calculatedTierFee: 0,
        calculatedTotal: 0,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeFeverRepository implements FeverRepository {
  @override
  Future<FeverDetailData> fetchFeverDetail(String livestockId) async =>
      FeverDetailData(
        livestockId: livestockId,
        livestockCode: 'ST-10',
        baselineTemp: 38.5,
        threshold: 39.5,
        status: 'NORMAL',
        recent72h: [
          TemperatureRecord(
            livestockId: livestockId,
            temperature: 38.00,
            timestamp: DateTime.utc(2026, 8, 26, 7),
          ),
          TemperatureRecord(
            livestockId: livestockId,
            temperature: 38.01,
            timestamp: DateTime.utc(2026, 8, 26, 8),
          ),
          TemperatureRecord(
            livestockId: livestockId,
            temperature: 38.02,
            timestamp: DateTime.utc(2026, 8, 26, 9),
          ),
        ],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeDigestiveRepository implements DigestiveRepository {
  @override
  Future<DigestiveDetailData> fetchDigestiveDetail(String livestockId) async =>
      DigestiveDetailData(
        livestockId: livestockId,
        livestockCode: 'ST-10',
        motilityBaseline: 3,
        status: 'NORMAL',
        recent24h: [
          MotilityRecord(
            livestockId: livestockId,
            frequency: 3,
            intensity: 50,
            timestamp: DateTime.utc(2026, 8, 26, 8),
          ),
          MotilityRecord(
            livestockId: livestockId,
            frequency: 2.7,
            intensity: 45,
            timestamp: DateTime.utc(2026, 8, 26, 9),
          ),
        ],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeEstrusRepository implements EstrusRepository {
  @override
  Future<EstrusDetailData> fetchEstrusDetail(String livestockId) async =>
      EstrusDetailData(
        livestockId: livestockId,
        livestockCode: 'ST-10',
        score: 0,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

LivestockDetail _detail() => LivestockDetail(
      livestockCode: 'ST-10',
      livestockId: '10',
      breed: Breed.simmental,
      ageMonths: 30,
      weightKg: 500,
      health: LivestockHealth.healthy,
      fenceId: '1',
      devices: const [],
      bodyTemp: 38.5,
      activityLevel: 'NORMAL',
      ruminationFreq: '3',
      lastLocation: '28.0, 112.0',
    );

void main() {
  testWidgets('livestock detail shows rumen motility trend', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        livestockRepositoryProvider.overrideWithValue(_FakeLivestockRepository()),
        subscriptionRepositoryProvider.overrideWithValue(_FakeSubscriptionRepository()),
        feverRepositoryProvider.overrideWithValue(_FakeFeverRepository()),
        digestiveRepositoryProvider.overrideWithValue(_FakeDigestiveRepository()),
        estrusRepositoryProvider.overrideWithValue(_FakeEstrusRepository()),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LivestockDetailPage(livestockId: '10'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('24小时蠕动曲线'), findsOneWidget);
    expect(find.text('实测蠕动'), findsOneWidget);
    expect(find.text('基线参考'), findsWidgets);

    final axisLabels = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .where((text) => text.endsWith('°'))
        .toList();
    expect(axisLabels, isNotEmpty);
    expect(axisLabels.toSet().length, axisLabels.length,
        reason: 'temperature axis labels must not duplicate after formatting');

    final temperatureChart = tester
        .widgetList<LineChart>(find.byType(LineChart))
        .firstWhere((chart) => chart.data.lineBarsData.any(
              (bar) => bar.spots.any((spot) => spot.y > 35 && spot.y < 42),
            ));
    final sideTitles = temperatureChart
        .data.titlesData.leftTitles.sideTitles;
    expect(sideTitles.interval, greaterThanOrEqualTo(0.1));
    expect(sideTitles.minIncluded, isFalse);
    expect(sideTitles.maxIncluded, isFalse);
  });
}
