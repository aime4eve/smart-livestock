import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/features/drinking/data/drinking_api_repository.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_repository.dart';

final drinkingRepositoryProvider = Provider<DrinkingRepository>((ref) {
  return const DrinkingApiRepository();
});

/// Device-local calendar day as `yyyy-MM-dd`. The backend interprets the
/// value as an Asia/Shanghai cow-day (physiology B3 timezone convention);
/// deployed devices run in the Shanghai timezone, so device-local == farm
/// local.
String drinkingWireDay(DateTime local) {
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Merged days=7 + days=30 summary for the drinking card (NIX-256):
/// today's count / last drink / 7-day bars come from days=7, the rolling
/// baseline + sample-day count from days=30 (independent computations, F4).
///
/// Farm-scoped API + family(livestockId) → must extend FarmScopedAsyncNotifier
/// and watch the active farm first (AGENTS §5).
class DrinkingSummaryController
    extends FarmScopedAsyncNotifier<DrinkingSummaryBundle> {
  DrinkingSummaryController(this.livestockId);

  final String livestockId;

  @override
  Future<DrinkingSummaryBundle> build() async {
    watchActiveFarmId();
    final repo = ref.read(drinkingRepositoryProvider);
    final today = drinkingWireDay(DateTime.now());
    final results = await Future.wait([
      repo.summary(livestockId, date: today, days: 7),
      repo.summary(livestockId, date: today, days: 30),
    ]);
    return DrinkingSummaryBundle(summary7: results[0], summary30: results[1]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final drinkingSummaryControllerProvider = AsyncNotifierProvider.family<
    DrinkingSummaryController, DrinkingSummaryBundle, String>(
  DrinkingSummaryController.new,
);

/// Drinking event rows for the `[D-2, D-1, today]` cow-days (inclusive) —
/// today's rows feed the timeline chart + marking list, while the 48h
/// overlay chart's valley window starts at now−48h, which reaches into
/// D-2 for the first 12h of the day (e.g. at 08:00 the window covers
/// [D-2 08:00, now]); fetching only yesterday would miss those valleys.
/// The chart consumer filters to now−48h itself, so the extra tail rows
/// are inert elsewhere. Newest first from the backend.
class DrinkingEventsController extends FarmScopedAsyncNotifier<List<DrinkingEvent>> {
  DrinkingEventsController(this.livestockId);

  final String livestockId;

  @override
  Future<List<DrinkingEvent>> build() async {
    watchActiveFarmId();
    final today = DateTime.now();
    return ref.read(drinkingRepositoryProvider).listEvents(
          livestockId,
          from: drinkingWireDay(today.subtract(const Duration(days: 2))),
          to: drinkingWireDay(today),
        );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Confirms / rejects one row (spec §15.2 marking loop), then refreshes
  /// both the row list and the summaries so counts re-aggregate (§15.3).
  /// Throws (ForbiddenException / ValidationException with the server-side
  /// i18n message) so the caller can surface it in a SnackBar.
  Future<void> markLabel({
    required int eventId,
    required DrinkingLabel label,
  }) async {
    await ref.read(drinkingRepositoryProvider).updateLabel(
          livestockId: livestockId,
          eventId: eventId,
          label: label,
        );
    await _refreshAll();
  }

  /// Back-fills a missed event (`eventStartAt` = `yyyy-MM-dd HH:mm`
  /// Asia/Shanghai wall clock), then refreshes rows + summaries.
  Future<void> addManual({
    required String eventStartAt,
    String? note,
  }) async {
    await ref.read(drinkingRepositoryProvider).createManual(
          livestockId: livestockId,
          eventStartAt: eventStartAt,
          note: note,
        );
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(drinkingSummaryControllerProvider(livestockId));
    await refresh();
  }
}

final drinkingEventsControllerProvider = AsyncNotifierProvider.family<
    DrinkingEventsController, List<DrinkingEvent>, String>(
  DrinkingEventsController.new,
);

/// Premium peer comparison. On non-premium subscriptions the call fails
/// with 403 error.drinking.premiumRequired (ForbiddenException) — that
/// lands in AsyncError and the UI maps it to the locked overlay
/// (spec-cards drinking-states-and-extras.md §三), never an error card.
class DrinkingPeerController extends FarmScopedAsyncNotifier<DrinkingPeerComparison> {
  DrinkingPeerController(this.livestockId);

  final String livestockId;

  @override
  Future<DrinkingPeerComparison> build() async {
    watchActiveFarmId();
    return ref.read(drinkingRepositoryProvider).peerComparison(livestockId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final drinkingPeerControllerProvider = AsyncNotifierProvider.family<
    DrinkingPeerController, DrinkingPeerComparison, String>(
  DrinkingPeerController.new,
);
