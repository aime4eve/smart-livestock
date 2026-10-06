// NIX-256 drinking behavior models (spec §4 endpoint contracts + §15.1
// marking-loop columns; spec-cards drinking-card.md /
// drinking-detail-section.md / drinking-states-and-extras.md). Hand-written
// fromJson following the physiology_models.dart conventions.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Response-default fallback for the server-delivered `baselineMinDays`
/// (config `health.drinking.baseline-min-days`, spec §14: 3). The backend
/// sends the live value on every summary layer; this constant only kicks
/// in when the field is missing from the payload (e.g. an older backend).
const int kDrinkingBaselineMinDays = 3;

/// Label of one drinking event row (spec §15.1). Wire values come from the
/// backend DrinkingEventLabel enum.
enum DrinkingLabel {
  unlabeled,
  confirmed,
  rejected;

  String get wireName => switch (this) {
        unlabeled => 'UNLABELED',
        confirmed => 'CONFIRMED',
        rejected => 'REJECTED',
      };

  static DrinkingLabel fromString(String value) {
    return switch (value) {
      'UNLABELED' => unlabeled,
      'CONFIRMED' => confirmed,
      'REJECTED' => rejected,
      _ => _unknown(value),
    };
  }

  static DrinkingLabel _unknown(String value) {
    // Same lenient-fallback pattern as PhysiologyEventType.fromString.
    debugPrint('DrinkingLabel: unknown value "$value", falling back to unlabeled');
    return unlabeled;
  }
}

/// One drinking event row (GET .../drinking-events, PATCH label response,
/// POST manual response).
class DrinkingEvent {
  const DrinkingEvent({
    required this.id,
    required this.livestockId,
    this.deviceId,
    required this.eventStartAt,
    required this.eventEndAt,
    this.tempDrop,
    this.minTemp,
    required this.source,
    required this.label,
    this.confidence,
    this.algorithmVersion,
    this.note,
    this.lowConfidence = false,
  });

  final int id;
  final String livestockId;
  final int? deviceId;

  /// UTC instants as returned by the backend. Rendered in the local
  /// timezone without any extra toUtc() round-trip (lesson #17).
  final DateTime eventStartAt;
  final DateTime eventEndAt;

  final double? tempDrop;
  final double? minTemp;

  /// Temperature-point source pass-through (DATAGEN/THINGSBOARD/…) plus the
  /// two marking-loop values MANUAL (owner back-fill) and
  /// ALGORITHM_CANDIDATE (auto-discovered borderline valley, spec §15.2).
  final String source;
  final DrinkingLabel label;
  final double? confidence;
  final String? algorithmVersion;
  final String? note;

  /// Server-derived flag (spec §15.2): confidence < the server config
  /// `health.drinking.low-confidence`. MANUAL rows carry confidence 1.0
  /// and never flag. Consumed as-is — the client no longer mirrors the
  /// threshold.
  final bool lowConfidence;

  /// Borderline candidates do not count as events until confirmed (§15.2);
  /// they render under the "to be marked" group.
  bool get isCandidate => source == 'ALGORITHM_CANDIDATE';

  bool get isManual => source == 'MANUAL';

  /// Low-confidence rows (spec §15.2) get the orange "needs verification"
  /// badge — the server-side `lowConfidence` flag drives it.
  bool get needsVerification => lowConfidence;

  factory DrinkingEvent.fromJson(Map<String, dynamic> m) {
    return DrinkingEvent(
      id: (m['id'] as num?)?.toInt() ?? 0,
      livestockId: (m['livestockId'] ?? '').toString(),
      deviceId: (m['deviceId'] as num?)?.toInt(),
      eventStartAt: DateTime.parse(m['eventStartAt'] as String),
      eventEndAt: DateTime.parse(m['eventEndAt'] as String),
      tempDrop: (m['tempDrop'] as num?)?.toDouble(),
      minTemp: (m['minTemp'] as num?)?.toDouble(),
      source: (m['source'] ?? '') as String,
      label: DrinkingLabel.fromString((m['label'] ?? '') as String),
      confidence: (m['confidence'] as num?)?.toDouble(),
      algorithmVersion: m['algorithmVersion'] as String?,
      note: m['note'] as String?,
      lowConfidence: m['lowConfidence'] as bool? ?? false,
    );
  }
}

/// One buffered fever window (GET .../drinking-events `feverWindows`,
/// NIX-259 m-q): physiology illness windows ∪ TEMPERATURE_ABNORMAL alert
/// windows with the 6h defervescence buffer already applied — the same
/// exclusion semantics the detector uses. The server clips both bounds to
/// the queried cow-day range (open-ended windows end at the `to` bound),
/// so the client always receives a finite rectangle.
class FeverWindow {
  const FeverWindow({required this.start, required this.end});

  /// UTC instants as returned by the backend; rendered locally without a
  /// toUtc() round-trip (lesson #17).
  final DateTime start;
  final DateTime end;

  factory FeverWindow.fromJson(Map<String, dynamic> m) {
    return FeverWindow(
      start: DateTime.parse(m['start'] as String),
      end: DateTime.parse(m['end'] as String),
    );
  }
}

/// GET .../drinking-events response body (NIX-259 m-q): the event rows
/// plus the fever windows overlapping the same queried range. The windows
/// feed the 48h temperature × drinking chart's fever shadow bands.
class DrinkingEventsPage {
  const DrinkingEventsPage({required this.events, this.feverWindows = const []});

  final List<DrinkingEvent> events;
  final List<FeverWindow> feverWindows;

  factory DrinkingEventsPage.fromJson(Map<String, dynamic> m) {
    return DrinkingEventsPage(
      events: (m['events'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DrinkingEvent.fromJson)
          .toList(),
      feverWindows: (m['feverWindows'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FeverWindow.fromJson)
          .toList(),
    );
  }
}

/// One event of the daily timeline inside the summary (DrinkingDayEvent).
class DrinkingDayTimelineEvent {
  const DrinkingDayTimelineEvent({
    required this.startAt,
    required this.endAt,
    this.tempDrop,
    required this.label,
    this.confidence,
    required this.source,
  });

  final DateTime startAt;
  final DateTime endAt;
  final double? tempDrop;
  final DrinkingLabel label;
  final double? confidence;
  final String source;

  factory DrinkingDayTimelineEvent.fromJson(Map<String, dynamic> m) {
    return DrinkingDayTimelineEvent(
      startAt: DateTime.parse(m['startAt'] as String),
      endAt: DateTime.parse(m['endAt'] as String),
      tempDrop: (m['tempDrop'] as num?)?.toDouble(),
      label: DrinkingLabel.fromString((m['label'] ?? '') as String),
      confidence: (m['confidence'] as num?)?.toDouble(),
      source: (m['source'] ?? '') as String,
    );
  }
}

/// `daily` block of the summary: the requested cow-day's counted events.
class DrinkingDaily {
  const DrinkingDaily({
    required this.count,
    required this.events,
    this.lastDrinkEndAt,
  });

  final int count;
  final List<DrinkingDayTimelineEvent> events;

  /// End of the last counted event — the client renders "N min ago" from it.
  final DateTime? lastDrinkEndAt;

  factory DrinkingDaily.fromJson(Map<String, dynamic> m) {
    return DrinkingDaily(
      count: (m['count'] as num?)?.toInt() ?? 0,
      events: (m['events'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DrinkingDayTimelineEvent.fromJson)
          .toList(),
      lastDrinkEndAt: m['lastDrinkEndAt'] == null
          ? null
          : DateTime.parse(m['lastDrinkEndAt'] as String),
    );
  }
}

/// `weekly` block (days=7 only): direct sum including fever days (F4 layer 1).
class DrinkingWeekly {
  const DrinkingWeekly({required this.count, required this.avgPerDay});

  final int count;
  final double avgPerDay;

  factory DrinkingWeekly.fromJson(Map<String, dynamic> m) {
    return DrinkingWeekly(
      count: (m['count'] as num?)?.toInt() ?? 0,
      avgPerDay: (m['avgPerDay'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// `rolling30dBaseline` block (days=30 only): average over sample days only
/// (fever-covered days excluded, F4 layer 2). [avgPerDay] is null when
/// there is not a single sample day.
class DrinkingRollingBaseline {
  const DrinkingRollingBaseline({this.avgPerDay, required this.sampleDays});

  final double? avgPerDay;
  final int sampleDays;

  factory DrinkingRollingBaseline.fromJson(Map<String, dynamic> m) {
    return DrinkingRollingBaseline(
      avgPerDay: (m['avgPerDay'] as num?)?.toDouble(),
      sampleDays: (m['sampleDays'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One bar of the mini bar chart; fever-covered days render orange.
class DrinkingDayCount {
  const DrinkingDayCount({
    required this.date,
    required this.count,
    this.feverCoveredPercent,
  });

  /// Shanghai cow-day, `yyyy-MM-dd`.
  final String date;
  final int count;
  final double? feverCoveredPercent;

  bool get isFeverDay => (feverCoveredPercent ?? 0) > 0;

  factory DrinkingDayCount.fromJson(Map<String, dynamic> m) {
    return DrinkingDayCount(
      date: (m['date'] ?? '') as String,
      count: (m['count'] as num?)?.toInt() ?? 0,
      feverCoveredPercent: (m['feverCoveredPercent'] as num?)?.toDouble(),
    );
  }
}

/// GET .../drinking-summary response (one endpoint, three layers; shapes
/// pinned by the prototype 3c tracing table).
class DrinkingSummary {
  const DrinkingSummary({
    required this.date,
    required this.days,
    required this.daily,
    this.weekly,
    this.rolling30dBaseline,
    required this.dayCounts,
    this.baselineMinDays = kDrinkingBaselineMinDays,
  });

  final String date;
  final int days;
  final DrinkingDaily daily;
  final DrinkingWeekly? weekly;
  final DrinkingRollingBaseline? rolling30dBaseline;
  final List<DrinkingDayCount> dayCounts;

  /// Server-delivered building threshold (config
  /// `health.drinking.baseline-min-days`; rides on every summary layer
  /// variant). Falls back to [kDrinkingBaselineMinDays] only when the
  /// payload omits the field.
  final int baselineMinDays;

  factory DrinkingSummary.fromJson(Map<String, dynamic> m) {
    return DrinkingSummary(
      date: (m['date'] ?? '') as String,
      days: (m['days'] as num?)?.toInt() ?? 1,
      daily: DrinkingDaily.fromJson(
        (m['daily'] ?? const {}) as Map<String, dynamic>,
      ),
      weekly: m['weekly'] is Map<String, dynamic>
          ? DrinkingWeekly.fromJson(m['weekly'] as Map<String, dynamic>)
          : null,
      rolling30dBaseline: m['rolling30dBaseline'] is Map<String, dynamic>
          ? DrinkingRollingBaseline.fromJson(
              m['rolling30dBaseline'] as Map<String, dynamic>,
            )
          : null,
      dayCounts: (m['dayCounts'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DrinkingDayCount.fromJson)
          .toList(),
      baselineMinDays:
          (m['baselineMinDays'] as num?)?.toInt() ?? kDrinkingBaselineMinDays,
    );
  }
}

/// The card merges two summary calls (days=7 for today/weekly/7 bars and
/// days=30 for the rolling baseline + sample-day count).
class DrinkingSummaryBundle {
  const DrinkingSummaryBundle({required this.summary7, required this.summary30});

  final DrinkingSummary summary7;
  final DrinkingSummary summary30;

  /// Last-7-day bars, ascending by date (oldest first, today last).
  List<DrinkingDayCount> get weekBars {
    final bars = [...summary7.dayCounts]..sort((a, b) => a.date.compareTo(b.date));
    return bars.length <= 7 ? bars : bars.sublist(bars.length - 7);
  }

  /// Sample days of the rolling 30-day baseline (0 when no baseline block).
  int get baselineSampleDays => rolling30dBaseline?.sampleDays ?? 0;

  /// Server-delivered threshold the building state compares
  /// [baselineSampleDays] against. Both layers carry it (backend rides it
  /// on every summary variant); the days=30 layer drives the building
  /// state, so its value wins.
  int get baselineMinDays => summary30.baselineMinDays;

  DrinkingRollingBaseline? get rolling30dBaseline => summary30.rolling30dBaseline;

  /// Most recent fever day among the last 7 bars, if any (drives the
  /// fever context note).
  DrinkingDayCount? get lastFeverDay {
    for (final bar in weekBars.reversed) {
      if (bar.isFeverDay) return bar;
    }
    return null;
  }
}

/// GET .../drinking-peer-comparison response (Premium endpoint; non-premium
/// gets 403 error.drinking.premiumRequired → AsyncError(ForbiddenException)).
class DrinkingPeerComparison {
  const DrinkingPeerComparison({
    this.peerAvgPerDay,
    this.reason,
    this.groupBreed,
    this.groupStage,
    required this.peerCount,
    required this.sampleDaysTotal,
    required this.minSampleDays,
  });

  final double? peerAvgPerDay;

  /// "INSUFFICIENT_PEERS" when no other group member reaches the minimum
  /// sample days (the UI shows the degraded copy, not an error).
  final String? reason;
  final String? groupBreed;

  /// LACTATING / DRY / null (undetermined).
  final String? groupStage;
  final int peerCount;
  final int sampleDaysTotal;
  final int minSampleDays;

  bool get insufficientPeers => reason == 'INSUFFICIENT_PEERS';

  factory DrinkingPeerComparison.fromJson(Map<String, dynamic> m) {
    return DrinkingPeerComparison(
      peerAvgPerDay: (m['peerAvgPerDay'] as num?)?.toDouble(),
      reason: m['reason'] as String?,
      groupBreed: m['groupBreed'] as String?,
      groupStage: m['groupStage'] as String?,
      peerCount: (m['peerCount'] as num?)?.toInt() ?? 0,
      sampleDaysTotal: (m['sampleDaysTotal'] as num?)?.toInt() ?? 0,
      minSampleDays: (m['minSampleDays'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The five card states shared by card + detail section (spec §3.3;
/// backfill is skipped in P1 — trigger detection not implemented).
enum DrinkingCardUiState { loading, noData, building, error, ready }

/// Pure state resolution for the DrinkingCard five-state convention so it
/// stays unit-testable without widgets:
/// 1. summary loading → skeleton;
/// 2. summary error (5xx/timeout) → red error card;
/// 3. no bound rumen capsule → noData;
/// 4. baseline sample days < the server-delivered `baselineMinDays`
///    (model-default 3 when the payload omits it) → building;
/// 5. otherwise → ready.
DrinkingCardUiState resolveDrinkingCardUiState({
  required bool hasCapsule,
  required AsyncValue<DrinkingSummaryBundle> summary,
}) {
  if (summary.isLoading) return DrinkingCardUiState.loading;
  if (summary.hasError) return DrinkingCardUiState.error;
  final bundle = summary.value;
  if (bundle == null) return DrinkingCardUiState.loading;
  if (!hasCapsule) return DrinkingCardUiState.noData;
  if (bundle.baselineSampleDays < bundle.baselineMinDays) {
    return DrinkingCardUiState.building;
  }
  return DrinkingCardUiState.ready;
}
