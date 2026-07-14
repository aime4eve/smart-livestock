
class StatsTrendPoint {
  const StatsTrendPoint({required this.date, required this.value});
  final String date;
  final double value;
}

class StatsSummary {
  const StatsSummary({
    required this.totalLivestock,
    required this.healthyRate,
    required this.alertCount,
    required this.criticalCount,
    required this.avgTemperature,
    required this.avgMotility,
  });
  final int totalLivestock;
  final double? healthyRate;
  final int alertCount;
  final int criticalCount;
  final double avgTemperature;
  final double avgMotility;
}

class StatsResponse {
  const StatsResponse({
    required this.summary,
    required this.temperatureTrend,
    required this.healthRateTrend,
    required this.alertTrend,
    required this.healthDistribution,
  });
  final StatsSummary summary;
  final List<StatsTrendPoint> temperatureTrend;
  final List<StatsTrendPoint> healthRateTrend;
  final List<StatsTrendPoint> alertTrend;
  final Map<String, int> healthDistribution;
}

abstract class StatsRepository {
  Future<StatsResponse> load();
}
