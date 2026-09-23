import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/anomaly_models.dart';
import '../domain/anomaly_repository.dart';

class AnomalyApiRepository implements AnomalyRepository {
  const AnomalyApiRepository();

  @override
  Future<AnomalyScoreData> fetchLatest(String livestockId) async {
    final data =
        await ApiClient.instance.farmGet('/health/anomaly/$livestockId');
    final merged = <String, dynamic>{...data, 'livestockId': livestockId};
    return AnomalyScoreData.fromJson(merged);
  }

  @override
  Future<List<AnomalyScoreHistoryItem>> fetchHistory(String livestockId,
      {int limit = 20}) async {
    final data = await ApiClient.instance
        .farmGet('/health/anomaly/$livestockId/history?limit=$limit');
    // farmGet wraps non-map payloads as {'value': [...]}; the endpoint may
    // also return {'items': [...]} — handle both plus a bare list.
    final List items;
    if (data['items'] is List) {
      items = data['items'] as List;
    } else if (data['value'] is List) {
      items = data['value'] as List;
    } else {
      items = const [];
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(AnomalyScoreHistoryItem.fromJson)
        .toList();
  }
}
