import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_repository.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/drinking_card.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// L2-pre boundary samples (NIX-256 Task 6): the drinking card must render
/// English long copy and textScale 1.3 without layout overflow. The fever
/// day-note is the longest localized string on the card. Goldens (Ahem
/// font) prove geometry; typography evidence is the browser capture in
/// output/drinking-l2/drill/ui-en-detail-1.png.
class _BoundaryRepo implements DrinkingRepository {
  @override
  Future<List<DrinkingEvent>> listEvents(String livestockId,
      {String? from, String? to}) async {
    return const [];
  }

  @override
  Future<DrinkingSummary> summary(String livestockId,
      {String? date, required int days}) async {
    return DrinkingSummary(
      date: '2026-10-05',
      days: days,
      daily: const DrinkingDaily(count: 0, events: []),
      weekly: days == 7 ? const DrinkingWeekly(count: 25, avgPerDay: 3.6) : null,
      rolling30dBaseline:
          days == 30 ? const DrinkingRollingBaseline(avgPerDay: 7.2, sampleDays: 24) : null,
      dayCounts: days == 7
          ? const [
              DrinkingDayCount(date: '2026-09-29', count: 11),
              DrinkingDayCount(date: '2026-09-30', count: 4),
              DrinkingDayCount(date: '2026-10-01', count: 3),
              DrinkingDayCount(date: '2026-10-02', count: 6),
              DrinkingDayCount(date: '2026-10-03', count: 5),
              DrinkingDayCount(date: '2026-10-04', count: 7),
              DrinkingDayCount(date: '2026-10-05', count: 0, feverCoveredPercent: 54.2),
            ]
          : const [],
    );
  }

  @override
  Future<DrinkingPeerComparison> peerComparison(String livestockId) async {
    return const DrinkingPeerComparison(
      peerAvgPerDay: 6.5,
      groupBreed: 'SIMMENTAL',
      groupStage: 'LACTATING',
      peerCount: 29,
      sampleDaysTotal: 610,
      minSampleDays: 5,
    );
  }

  @override
  Future<DrinkingEvent> updateLabel(
      {required String livestockId, required int eventId, required DrinkingLabel label}) {
    throw UnimplementedError();
  }

  @override
  Future<DrinkingEvent> createManual(
      {required String livestockId, required String eventStartAt, String? note}) {
    throw UnimplementedError();
  }
}

Widget _harness({required Locale locale, TextScaler? textScaler}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: textScaler ?? TextScaler.noScaling,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: SizedBox(
        width: 390,
        child: ListView(
          children: const [
            Padding(
              padding: EdgeInsets.all(12),
              child: DrinkingCard(livestockId: 'SL-2024-004', hasCapsule: true),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('boundary: en long copy renders without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drinkingRepositoryProvider.overrideWithValue(_BoundaryRepo()),
          initialSessionProvider.overrideWithValue(
            const AppSession.authenticated(
              role: UserRole.owner,
              accessToken: 'token',
              activeFarmId: 'farm-1',
            ),
          ),
        ],
        child: _harness(locale: const Locale('en')),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DrinkingCard),
      matchesGoldenFile('goldens/drinking-card-en-long.png'),
    );
  });

  testWidgets('boundary: textScale 1.3 renders without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drinkingRepositoryProvider.overrideWithValue(_BoundaryRepo()),
          initialSessionProvider.overrideWithValue(
            const AppSession.authenticated(
              role: UserRole.owner,
              accessToken: 'token',
              activeFarmId: 'farm-1',
            ),
          ),
        ],
        child: _harness(locale: const Locale('zh'), textScaler: const TextScaler.linear(1.3)),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DrinkingCard),
      matchesGoldenFile('goldens/drinking-card-zh-textscale-1.3.png'),
    );
  });
}
