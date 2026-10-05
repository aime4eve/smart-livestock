import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_models.dart';
import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_repository.dart';

/// Formats a local calendar date as the wire format the backend expects
/// (`yyyy-MM-dd`, B3: stored as that day's midnight in Asia/Shanghai).
String _wireDate(DateTime localDate) {
  final y = localDate.year.toString().padLeft(4, '0');
  final m = localDate.month.toString().padLeft(2, '0');
  final d = localDate.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class PhysiologyApiRepository implements PhysiologyRepository {
  const PhysiologyApiRepository();

  @override
  Future<PhysiologyEventListResponse> listEvents(String livestockId) async {
    final data = await ApiClient.instance
        .farmGet('/livestock/$livestockId/physiology-events');
    return PhysiologyEventListResponse.fromJson(data);
  }

  @override
  Future<PhysiologyEventItem> createEvent({
    required String livestockId,
    required PhysiologyEventType eventType,
    required DateTime occurredAt,
    String? note,
  }) async {
    final data = await ApiClient.instance.farmPost(
      '/livestock/$livestockId/physiology-events',
      body: {
        'eventType': eventType.wireName,
        'occurredAt': _wireDate(occurredAt),
        // Create: an empty note is simply omitted — nothing to clear yet.
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return PhysiologyEventItem.fromJson(data);
  }

  @override
  Future<PhysiologyEventItem> updateEvent({
    required String livestockId,
    required int eventId,
    required DateTime occurredAt,
    String? note,
  }) async {
    final data = await ApiClient.instance.farmPut(
      '/livestock/$livestockId/physiology-events/$eventId',
      body: {
        'occurredAt': _wireDate(occurredAt),
        // N17 explicit-clearing contract (backend c836b14e):
        // null/omitted keeps the old note, an empty string clears it, a
        // non-empty value updates it. The sheet trims before calling, so
        // an empty field reaches the wire as '' — never silently dropped.
        if (note != null) 'note': note,
      },
    );
    return PhysiologyEventItem.fromJson(data);
  }

  @override
  Future<void> deleteEvent({
    required String livestockId,
    required int eventId,
  }) async {
    await ApiClient.instance
        .farmDelete('/livestock/$livestockId/physiology-events/$eventId');
  }
}
