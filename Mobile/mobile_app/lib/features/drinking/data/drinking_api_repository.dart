import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_repository.dart';

class DrinkingApiRepository implements DrinkingRepository {
  const DrinkingApiRepository();

  @override
  Future<List<DrinkingEvent>> listEvents(
    String livestockId, {
    String? from,
    String? to,
  }) async {
    final query = [
      if (from != null && from.isNotEmpty) 'from=$from',
      if (to != null && to.isNotEmpty) 'to=$to',
    ].join('&');
    final suffix = query.isEmpty
        ? '/livestock/$livestockId/drinking-events'
        : '/livestock/$livestockId/drinking-events?$query';
    final data = await ApiClient.instance.farmGet(suffix);
    // A JSON array payload is unwrapped into {'value': [...]} by ApiClient.
    final items = (data['value'] ?? data['items']) as List? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(DrinkingEvent.fromJson)
        .toList();
  }

  @override
  Future<DrinkingSummary> summary(
    String livestockId, {
    String? date,
    required int days,
  }) async {
    final query = 'days=$days${date != null && date.isNotEmpty ? '&date=$date' : ''}';
    final data = await ApiClient.instance
        .farmGet('/livestock/$livestockId/drinking-summary?$query');
    return DrinkingSummary.fromJson(data);
  }

  @override
  Future<DrinkingPeerComparison> peerComparison(String livestockId) async {
    final data = await ApiClient.instance
        .farmGet('/livestock/$livestockId/drinking-peer-comparison');
    return DrinkingPeerComparison.fromJson(data);
  }

  @override
  Future<DrinkingEvent> updateLabel({
    required String livestockId,
    required int eventId,
    required DrinkingLabel label,
  }) async {
    final data = await ApiClient.instance.farmPatch(
      '/livestock/$livestockId/drinking-events/$eventId/label',
      body: {'label': label.wireName},
    );
    return DrinkingEvent.fromJson(data);
  }

  @override
  Future<DrinkingEvent> createManual({
    required String livestockId,
    required String eventStartAt,
    String? note,
  }) async {
    final data = await ApiClient.instance.farmPost(
      '/livestock/$livestockId/drinking-events/manual',
      body: {
        'eventStartAt': eventStartAt,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return DrinkingEvent.fromJson(data);
  }
}
