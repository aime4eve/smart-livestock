import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import '../domain/anomaly_models.dart';
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
    final items = data['items'] as List? ?? data as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(AnomalyScoreHistoryItem.fromJson)
        .toList();
  }
}
