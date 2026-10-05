import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_models.dart';

/// Physiology event CRUD (NIX-256).
///
/// Only MANUAL rows may be updated or deleted; the backend rejects
/// DISPOSITION / ALERT_CONFIRM rows with 409.
abstract class PhysiologyRepository {
  Future<PhysiologyEventListResponse> listEvents(String livestockId);

  /// Idempotent: re-posting the same (livestock, type, local date) triple
  /// with source=MANUAL returns the existing row.
  Future<PhysiologyEventItem> createEvent({
    required String livestockId,
    required PhysiologyEventType eventType,
    required DateTime occurredAt,
    String? note,
  });

  Future<PhysiologyEventItem> updateEvent({
    required String livestockId,
    required int eventId,
    required DateTime occurredAt,
    String? note,
  });

  Future<void> deleteEvent({
    required String livestockId,
    required int eventId,
  });
}
