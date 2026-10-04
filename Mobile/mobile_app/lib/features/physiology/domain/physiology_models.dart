// NIX-256 physiology event models (spec: physiology-record-card.md /
// physiology-entry-sheet.md). Hand-written fromJson following the
// health_models.dart conventions.

import 'package:flutter/foundation.dart';

/// Physiology event type wire values come from the backend enum
/// (GET /farms/{farmId}/livestock/{id}/physiology-events).
enum PhysiologyEventType {
  calving,
  breeding,
  pregnancyCheck,
  dryOff,
  illness,
  recovery;

  String get wireName => switch (this) {
        calving => 'CALVING',
        breeding => 'BREEDING',
        pregnancyCheck => 'PREGNANCY_CHECK',
        dryOff => 'DRY_OFF',
        illness => 'ILLNESS',
        recovery => 'RECOVERY',
      };

  static PhysiologyEventType fromString(String value) {
    return switch (value) {
      'CALVING' => calving,
      'BREEDING' => breeding,
      'PREGNANCY_CHECK' => pregnancyCheck,
      'DRY_OFF' => dryOff,
      'ILLNESS' => illness,
      'RECOVERY' => recovery,
      _ => _unknown(value),
    };
  }

  static PhysiologyEventType _unknown(String value) {
    // Same lenient-fallback pattern as UserRole.fromString.
    debugPrint('PhysiologyEventType: unknown value "$value", falling back to illness');
    return illness;
  }
}

/// How the event row was produced. MANUAL rows are user-editable;
/// DISPOSITION rows are read-only projections from epidemic dispositions
/// (id == null on the wire); ALERT_CONFIRM rows come from alert triage.
enum PhysiologySource {
  manual,
  alertConfirm,
  disposition;

  String get wireName => switch (this) {
        manual => 'MANUAL',
        alertConfirm => 'ALERT_CONFIRM',
        disposition => 'DISPOSITION',
      };

  static PhysiologySource fromString(String value) {
    return switch (value) {
      'MANUAL' => manual,
      'ALERT_CONFIRM' => alertConfirm,
      'DISPOSITION' => disposition,
      _ => _unknown(value),
    };
  }

  static PhysiologySource _unknown(String value) {
    debugPrint('PhysiologySource: unknown value "$value", falling back to manual');
    return manual;
  }
}

enum PhysiologyStageType {
  lactating,
  dry;

  static PhysiologyStageType fromString(String value) {
    return switch (value) {
      'LACTATING' => lactating,
      'DRY' => dry,
      _ => _unknown(value),
    };
  }

  static PhysiologyStageType _unknown(String value) {
    debugPrint('PhysiologyStageType: unknown value "$value", falling back to lactating');
    return lactating;
  }
}

class PhysiologyEventItem {
  const PhysiologyEventItem({
    required this.id,
    required this.livestockId,
    required this.eventType,
    required this.source,
    this.refId,
    this.note,
    required this.occurredAt,
    required this.active,
  });

  /// Null for disposition projection rows (read-only, no persisted row).
  final int? id;
  final String livestockId;
  final PhysiologyEventType eventType;
  final PhysiologySource source;
  final int? refId;
  final String? note;

  /// UTC instant as returned by the backend. Rendered in the local
  /// timezone without any extra toUtc() round-trip (lesson #17).
  final DateTime occurredAt;

  /// True while the illness window opened by this event is still open.
  final bool active;

  factory PhysiologyEventItem.fromJson(Map<String, dynamic> m) {
    return PhysiologyEventItem(
      id: (m['id'] as num?)?.toInt(),
      livestockId: (m['livestockId'] ?? '').toString(),
      eventType: PhysiologyEventType.fromString(
        (m['eventType'] ?? '') as String,
      ),
      source: PhysiologySource.fromString((m['source'] ?? '') as String),
      refId: (m['refId'] as num?)?.toInt(),
      note: m['note'] as String?,
      // Fail fast on malformed instants instead of hiding them behind a
      // default (lesson #18).
      occurredAt: DateTime.parse(m['occurredAt'] as String),
      active: m['active'] as bool? ?? false,
    );
  }
}

class PhysiologyStageProjection {
  const PhysiologyStageProjection({required this.type, required this.since});

  final PhysiologyStageType type;

  /// UTC instant when the stage started.
  final DateTime since;

  factory PhysiologyStageProjection.fromJson(Map<String, dynamic> m) {
    return PhysiologyStageProjection(
      type: PhysiologyStageType.fromString((m['type'] ?? '') as String),
      since: DateTime.parse(m['since'] as String),
    );
  }
}

class PhysiologyEventListResponse {
  const PhysiologyEventListResponse({required this.items, this.stage});

  final List<PhysiologyEventItem> items;
  final PhysiologyStageProjection? stage;

  factory PhysiologyEventListResponse.fromJson(Map<String, dynamic> m) {
    return PhysiologyEventListResponse(
      items: (m['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PhysiologyEventItem.fromJson)
          .toList(),
      stage: m['stage'] is Map<String, dynamic>
          ? PhysiologyStageProjection.fromJson(
              m['stage'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
