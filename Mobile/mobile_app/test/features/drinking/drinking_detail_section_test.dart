import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_repository.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/widgets/drinking_detail_section.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/domain/fever_repository.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/presentation/fever_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// NIX-259 m-q regression pin: the 48h temperature × drinking chart must
/// render the server-delivered fever windows (6h defervescence buffer
/// included) as time-span shadow bands via fl_chart vertical range
/// annotations, plus the "fever period +6h buffer" legend item.
class _FeverBandRepo implements DrinkingRepository {
  _FeverBandRepo(this.feverWindows);

  final List<FeverWindow> feverWindows;

  @override
  Future<DrinkingEventsPage> listEvents(String livestockId,
      {String? from, String? to}) async {
    return DrinkingEventsPage(events: const [], feverWindows: feverWindows);
  }

  @override
  Future<DrinkingSummary> summary(String livestockId,
      {String? date, required int days}) async {
    return DrinkingSummary(
      date: date ?? '2026-10-04',
      days: days,
      daily: const DrinkingDaily(count: 5, events: []),
      weekly: days == 7 ? const DrinkingWeekly(count: 35, avgPerDay: 5.0) : null,
      // sampleDays 6 ≥ default baselineMinDays 3 → the section reaches the
      // ready state and mounts the 48h chart.
      rolling30dBaseline:
          days == 30 ? const DrinkingRollingBaseline(avgPerDay: 5.0, sampleDays: 6) : null,
      dayCounts: const [],
    );
  }

  @override
  Future<DrinkingPeerComparison> peerComparison(String livestockId) {
    throw UnimplementedError();
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

class _FakeFeverRepository implements FeverRepository {
  @override
  Future<FeverDetailData> fetchFeverDetail(String livestockId) async {
    final now = DateTime.now();
    // One reading per ~2h across the visible 48h window (ascending).
    final readings = [
      for (var i = 24; i >= 1; i--)
        TemperatureRecord(
          livestockId: livestockId,
          temperature: 38.0 + (i % 3) * 0.2,
          timestamp: now.subtract(Duration(hours: i * 2)),
        ),
    ];
    return FeverDetailData(
      livestockId: livestockId,
      livestockCode: 'SL-12',
      baselineTemp: 38.5,
      threshold: 39.5,
      status: 'NORMAL',
      recent72h: readings,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Widget _harness() {
  return const MaterialApp(
    locale: Locale('zh'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: DrinkingDetailSection(livestockId: '4'),
        ),
      ),
    ),
  );
}

Future<void> _pumpSection(WidgetTester tester, List<FeverWindow> windows) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        drinkingRepositoryProvider.overrideWithValue(_FeverBandRepo(windows)),
        feverRepositoryProvider.overrideWithValue(_FakeFeverRepository()),
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'token',
            activeFarmId: 'farm-1',
          ),
        ),
      ],
      child: _harness(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('48h chart draws one fever shadow band per server window',
      (tester) async {
    final now = DateTime.now();
    final firstStart = now.subtract(const Duration(hours: 40));
    final firstEnd = now.subtract(const Duration(hours: 34));
    final secondStart = now.subtract(const Duration(hours: 12));
    final secondEnd = now.subtract(const Duration(hours: 6));

    await _pumpSection(tester, [
      FeverWindow(start: firstStart, end: firstEnd),
      FeverWindow(start: secondStart, end: secondEnd),
    ]);

    // The 48h overlay is the only fl_chart LineChart on the section (the
    // time-of-day distribution chart is hand-drawn).
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final bands = chart.data.rangeAnnotations.verticalRangeAnnotations;

    expect(bands, hasLength(2));
    // Bands map 1:1 onto the server windows in epoch-ms chart units.
    expect(bands[0].x1, firstStart.millisecondsSinceEpoch.toDouble());
    expect(bands[0].x2, firstEnd.millisecondsSinceEpoch.toDouble());
    expect(bands[1].x1, secondStart.millisecondsSinceEpoch.toDouble());
    expect(bands[1].x2, secondEnd.millisecondsSinceEpoch.toDouble());
    // Prototype screen 2: --fever #D97B29 at 12% alpha.
    expect(bands[0].color, const Color(0xFFD97B29).withValues(alpha: 0.12));

    // The "发热期·已排除" caption rides the fever legend item.
    expect(find.textContaining('发热期+6h'), findsOneWidget);
  });

  testWidgets('a window before the visible 48h span is not drawn',
      (tester) async {
    final now = DateTime.now();
    await _pumpSection(tester, [
      // Server windows are clipped to the queried cow-day range, which can
      // start earlier than the chart's now−48h sub-window.
      FeverWindow(
        start: now.subtract(const Duration(hours: 72)),
        end: now.subtract(const Duration(hours: 50)),
      ),
    ]);

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.rangeAnnotations.verticalRangeAnnotations, isEmpty);
  });
}
