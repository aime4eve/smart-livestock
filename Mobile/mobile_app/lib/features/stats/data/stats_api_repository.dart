import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/stats/domain/stats_repository.dart';

class StatsApiRepository implements StatsRepository {
  const StatsApiRepository();

  @override
  Future<StatsResponse> load() async {
    final data = await ApiClient.instance.farmGet('/health/stats');
    final summaryData = data['summary'] as Map<String, dynamic>;
    final summary = StatsSummary(
      totalLivestock: summaryData['totalLivestock'] as int? ?? 0,
      healthyRate: (summaryData['healthyRate'] as num?)?.toDouble(),
      alertCount: summaryData['alertCount'] as int? ?? 0,
      criticalCount: summaryData['criticalCount'] as int? ?? 0,
      avgTemperature: (summaryData['avgTemperature'] as num?)?.toDouble() ?? 38.5,
      avgMotility: (summaryData['avgMotility'] as num?)?.toDouble() ?? 3.0,
    );

    List<StatsTrendPoint> parseTrend(String key) {
      final items = data[key] as List? ?? [];
      return items.whereType<Map<String, dynamic>>().map((e) => StatsTrendPoint(
        date: e['date'] as String? ?? '',
        value: (e['value'] as num?)?.toDouble() ?? 0.0,
      )).toList();
    }

    final dist = <String, int>{};
    (data['healthDistribution'] as Map<String, dynamic>?)?.forEach((k, v) {
      dist[k] = (v as num?)?.toInt() ?? 0;
    });

    return StatsResponse(
      summary: summary,
      temperatureTrend: parseTrend('temperatureTrend'),
      healthRateTrend: parseTrend('healthRateTrend'),
      alertTrend: parseTrend('alertTrend'),
      healthDistribution: dist,
    );
  }
}
