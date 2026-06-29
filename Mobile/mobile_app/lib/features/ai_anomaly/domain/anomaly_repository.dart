import 'package:hkt_livestock_agentic/core/models/anomaly_models.dart';

abstract class AnomalyRepository {
  Future<AnomalyScoreData> fetchLatest(String livestockId);
  Future<List<AnomalyScoreHistoryItem>> fetchHistory(String livestockId,
      {int limit = 20});
}
