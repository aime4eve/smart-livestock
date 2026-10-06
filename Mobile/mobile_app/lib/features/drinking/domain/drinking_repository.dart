import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';

/// Drinking behavior read + marking-loop write calls (NIX-256 Task 5b).
///
/// `from`/`to`/`date` parameters are `yyyy-MM-dd` calendar days: the
/// backend interprets them as a closed range in Asia/Shanghai cow-days
/// (DrinkingEventService ENTRY_ZONE), matching the physiology B3 timezone
/// convention. Deployed devices run in the Shanghai timezone, so the
/// device-local calendar day is used.
abstract class DrinkingRepository {
  /// Every row of the livestock inside the `[from, to]` cow-day range —
  /// including candidates and REJECTED rows, newest first — plus the
  /// buffered fever windows clipped to the same range (NIX-259 m-q) for
  /// the 48h chart's fever shadow bands.
  Future<DrinkingEventsPage> listEvents(
    String livestockId, {
    String? from,
    String? to,
  });

  /// Three-layer summary: days=1 daily only, days=7 daily + weekly + 7-day
  /// bars, days=30 daily + rolling baseline + 30-day bars.
  Future<DrinkingSummary> summary(
    String livestockId, {
    String? date,
    required int days,
  });

  /// Premium peer comparison. Non-premium subscriptions get a
  /// ForbiddenException (403 error.drinking.premiumRequired) — callers map
  /// it to the locked overlay, not an error card.
  Future<DrinkingPeerComparison> peerComparison(String livestockId);

  /// Confirm / reject / reset the label of one drinking event row (spec
  /// §15.2; OWNER / B2B_ADMIN / WORKER only — server-side enforced).
  Future<DrinkingEvent> updateLabel({
    required String livestockId,
    required int eventId,
    required DrinkingLabel label,
  });

  /// Back-fill a missed drinking event: `eventStartAt` is a wall-clock
  /// `yyyy-MM-dd HH:mm` string in Asia/Shanghai; the row is created with
  /// source=MANUAL, label=CONFIRMED.
  Future<DrinkingEvent> createManual({
    required String livestockId,
    required String eventStartAt,
    String? note,
  });
}
