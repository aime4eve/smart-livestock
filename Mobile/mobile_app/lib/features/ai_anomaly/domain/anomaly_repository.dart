import 'anomaly_models.dart';

abstract class AnomalyRepository {
  Future<AnomalyScoreData> fetchLatest(String livestockId);
  Future<List<AnomalyScoreHistoryItem>> fetchHistory(String livestockId,
      {int limit = 20});
}
