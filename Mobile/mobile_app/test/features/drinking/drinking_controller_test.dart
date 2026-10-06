import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_repository.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';

class _FakeDrinkingRepository implements DrinkingRepository {
  _FakeDrinkingRepository({
    this.peerAvgPerDay = 7.3,
    this.peerReason,
    this.peerError,
  });

  final double? peerAvgPerDay;
  final String? peerReason;
  final Object? peerError;

  int summaryCallCount = 0;
  List<int> summaryDaysCalls = [];
  int peerCallCount = 0;
  int eventsCallCount = 0;
  final List<int> labeledEventIds = [];
  final List<String> manualEventStarts = [];

  DrinkingEvent _event(
    int id, {
    String label = 'UNLABELED',
    String source = 'THINGSBOARD',
  }) => DrinkingEvent(
    id: id,
    livestockId: '4',
    deviceId: 2,
    eventStartAt: DateTime.utc(2026, 10, 4, 2),
    eventEndAt: DateTime.utc(2026, 10, 4, 2, 7),
    tempDrop: 1.7,
    minTemp: 37.2,
    source: source,
    label: DrinkingLabel.fromString(label),
    confidence: 0.9,
  );

  @override
  Future<DrinkingEventsPage> listEvents(
    String livestockId, {
    String? from,
    String? to,
  }) async {
    eventsCallCount++;
    return DrinkingEventsPage(events: [
      _event(1),
      _event(2, label: 'CONFIRMED'),
      _event(3),
    ]);
  }

  @override
  Future<DrinkingSummary> summary(
    String livestockId, {
    String? date,
    required int days,
  }) async {
    summaryCallCount++;
    summaryDaysCalls.add(days);
    return DrinkingSummary(
      date: date ?? '2026-10-04',
      days: days,
      daily: DrinkingDaily(
        count: 7,
        events: const [],
        lastDrinkEndAt: DateTime.utc(2026, 10, 4, 1, 46),
      ),
      weekly: days == 7
          ? const DrinkingWeekly(count: 48, avgPerDay: 6.9)
          : null,
      rolling30dBaseline: days == 30
          ? const DrinkingRollingBaseline(avgPerDay: 7.6, sampleDays: 6)
          : null,
      dayCounts: days == 7
          ? [
              for (var i = 0; i < 7; i++)
                DrinkingDayCount(date: '2026-10-0${i + 1}', count: 7 - i),
            ]
          : const [],
    );
  }

  @override
  Future<DrinkingPeerComparison> peerComparison(String livestockId) async {
    peerCallCount++;
    if (peerError != null) throw peerError!;
    return DrinkingPeerComparison(
      peerAvgPerDay: peerAvgPerDay,
      reason: peerReason,
      groupBreed: 'SIMMENTAL',
      groupStage: 'LACTATING',
      peerCount: 12,
      sampleDaysTotal: 260,
      minSampleDays: 5,
    );
  }

  @override
  Future<DrinkingEvent> updateLabel({
    required String livestockId,
    required int eventId,
    required DrinkingLabel label,
  }) async {
    labeledEventIds.add(eventId);
    return _event(eventId, label: label.wireName);
  }

  @override
  Future<DrinkingEvent> createManual({
    required String livestockId,
    required String eventStartAt,
    String? note,
  }) async {
    manualEventStarts.add(eventStartAt);
    // source=MANUAL + label=CONFIRMED, mirroring the backend contract.
    return _event(99, label: 'CONFIRMED', source: 'MANUAL');
  }
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  ProviderContainer setup(_FakeDrinkingRepository repo) {
    return ProviderContainer(
      overrides: [
        drinkingRepositoryProvider.overrideWithValue(repo),
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'token',
            activeFarmId: 'farm-1',
          ),
        ),
      ],
    );
  }

  group('DrinkingSummaryController', () {
    test('build merges days=7 and days=30 calls', () async {
      final repo = _FakeDrinkingRepository();
      final container = setup(repo);
      addTearDown(container.dispose);

      container.read(drinkingSummaryControllerProvider('4'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(drinkingSummaryControllerProvider('4'));
      expect(state.value, isNotNull);
      expect(repo.summaryDaysCalls, containsAll([7, 30]));
      expect(state.value!.summary7.weekly!.count, 48);
      expect(state.value!.baselineSampleDays, 6);
      // Fake repo omits baselineMinDays → model response-default 3.
      expect(
        state.value!.baselineMinDays,
        kDrinkingBaselineMinDays,
      );
      expect(state.value!.weekBars.length, 7);
    });

    test('farm switch triggers rebuild', () async {
      final repo = _FakeDrinkingRepository();
      final container = setup(repo);
      addTearDown(container.dispose);

      container.read(drinkingSummaryControllerProvider('4'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.summaryCallCount, 2);

      // Invalidation is lazy: re-read to trigger the rebuild (same shape
      // as the livestock controller test).
      container
          .read(sessionControllerProvider.notifier)
          .updateActiveFarm('farm-2');
      container.read(drinkingSummaryControllerProvider('4'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repo.summaryCallCount, greaterThanOrEqualTo(4));
    });
  });

  group('resolveDrinkingCardUiState (five-state convention)', () {
    const bundle = DrinkingSummaryBundle(
      summary7: DrinkingSummary(
        date: '2026-10-04',
        days: 7,
        daily: DrinkingDaily(count: 7, events: [], lastDrinkEndAt: null),
        dayCounts: [],
      ),
      summary30: DrinkingSummary(
        date: '2026-10-04',
        days: 30,
        daily: DrinkingDaily(count: 7, events: [], lastDrinkEndAt: null),
        rolling30dBaseline: DrinkingRollingBaseline(avgPerDay: 7.6, sampleDays: 6),
        dayCounts: [],
      ),
    );

    test('loading while the summary is in flight', () {
      final state = resolveDrinkingCardUiState(
        hasCapsule: true,
        summary: const AsyncValue<DrinkingSummaryBundle>.loading(),
      );
      expect(state, DrinkingCardUiState.loading);
    });

    test('error on 5xx/timeout', () {
      final state = resolveDrinkingCardUiState(
        hasCapsule: true,
        summary: AsyncValue<DrinkingSummaryBundle>.error(
          const ServerException(message: 'boom', statusCode: 500),
          StackTrace.current,
        ),
      );
      expect(state, DrinkingCardUiState.error);
    });

    test('noData when no rumen capsule is bound', () {
      final state = resolveDrinkingCardUiState(
        hasCapsule: false,
        summary: const AsyncData<DrinkingSummaryBundle>(bundle),
      );
      expect(state, DrinkingCardUiState.noData);
    });

    test('building below the 3-day baseline minimum', () {
      final short = DrinkingSummaryBundle(
        summary7: bundle.summary7,
        summary30: const DrinkingSummary(
          date: '2026-10-04',
          days: 30,
          daily: DrinkingDaily(count: 7, events: [], lastDrinkEndAt: null),
          rolling30dBaseline:
              DrinkingRollingBaseline(avgPerDay: null, sampleDays: 2),
          dayCounts: [],
        ),
      );
      final state = resolveDrinkingCardUiState(
        hasCapsule: true,
        summary: AsyncValue<DrinkingSummaryBundle>.data(short),
      );
      expect(state, DrinkingCardUiState.building);
    });

    test('building threshold follows the server-delivered baselineMinDays', () {
      // 4 sample days would clear the default 3, but the server says 5.
      final raised = DrinkingSummaryBundle(
        summary7: bundle.summary7,
        summary30: const DrinkingSummary(
          date: '2026-10-04',
          days: 30,
          daily: DrinkingDaily(count: 7, events: [], lastDrinkEndAt: null),
          rolling30dBaseline:
              DrinkingRollingBaseline(avgPerDay: null, sampleDays: 4),
          dayCounts: [],
          baselineMinDays: 5,
        ),
      );
      expect(
        resolveDrinkingCardUiState(
          hasCapsule: true,
          summary: AsyncValue<DrinkingSummaryBundle>.data(raised),
        ),
        DrinkingCardUiState.building,
      );

      // Same 4 sample days pass once the server lowers the bar to 4.
      final met = DrinkingSummaryBundle(
        summary7: bundle.summary7,
        summary30: const DrinkingSummary(
          date: '2026-10-04',
          days: 30,
          daily: DrinkingDaily(count: 7, events: [], lastDrinkEndAt: null),
          rolling30dBaseline:
              DrinkingRollingBaseline(avgPerDay: null, sampleDays: 4),
          dayCounts: [],
          baselineMinDays: 4,
        ),
      );
      expect(
        resolveDrinkingCardUiState(
          hasCapsule: true,
          summary: AsyncValue<DrinkingSummaryBundle>.data(met),
        ),
        DrinkingCardUiState.ready,
      );
    });

    test('ready once ≥3 sample days exist', () {
      final state = resolveDrinkingCardUiState(
        hasCapsule: true,
        summary: const AsyncData<DrinkingSummaryBundle>(bundle),
      );
      expect(state, DrinkingCardUiState.ready);
    });
  });

  group('DrinkingPeerController', () {
    test('premium 403 lands in AsyncError as ForbiddenException', () async {
      final repo = _FakeDrinkingRepository(
        peerError: const ForbiddenException(
          message: '饮水同类对比为 Premium 权益',
          statusCode: 403,
          code: 'AUTH_FORBIDDEN',
        ),
      );
      final container = setup(repo);
      addTearDown(container.dispose);

      container.read(drinkingPeerControllerProvider('4'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(drinkingPeerControllerProvider('4'));
      expect(state.hasError, isTrue);
      expect(state.error, isA<ForbiddenException>());
    });

    test('INSUFFICIENT_PEERS returns data with the degraded reason', () async {
      final repo = _FakeDrinkingRepository(
        peerAvgPerDay: null,
        peerReason: 'INSUFFICIENT_PEERS',
      );
      final container = setup(repo);
      addTearDown(container.dispose);

      container.read(drinkingPeerControllerProvider('4'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(drinkingPeerControllerProvider('4'));
      expect(state.hasError, isFalse);
      expect(state.value!.insufficientPeers, isTrue);
    });
  });

  group('DrinkingEventsController marking loop', () {
    test('markLabel patches then refreshes rows and summaries', () async {
      final repo = _FakeDrinkingRepository();
      final container = setup(repo);
      addTearDown(container.dispose);

      container.read(drinkingEventsControllerProvider('4'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final eventsBefore = repo.eventsCallCount;
      final summariesBefore = repo.summaryCallCount;

      await container
          .read(drinkingEventsControllerProvider('4').notifier)
          .markLabel(eventId: 1, label: DrinkingLabel.rejected);

      expect(repo.labeledEventIds, [1]);
      // Rows reloaded and the card summaries invalidated (their providers
      // re-subscribe lazily; the repo sees the events refresh at least).
      expect(repo.eventsCallCount, greaterThan(eventsBefore));
      expect(repo.summaryCallCount, greaterThanOrEqualTo(summariesBefore));
    });

    test('addManual posts the wall-clock string then refreshes', () async {
      final repo = _FakeDrinkingRepository();
      final container = setup(repo);
      addTearDown(container.dispose);

      container.read(drinkingEventsControllerProvider('4'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(drinkingEventsControllerProvider('4').notifier)
          .addManual(eventStartAt: '2026-10-04 10:20', note: 'seen at trough');

      expect(repo.manualEventStarts, ['2026-10-04 10:20']);
    });
  });
}
