import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/stats/domain/stats_repository.dart';

class LiveStatsRepository implements StatsRepository {
  const LiveStatsRepository();

  @override
  StatsViewData load(
      {required ViewState viewState, required StatsTimeRange timeRange}) {
    if (viewState != ViewState.normal) {
      return StatsViewData(viewState: viewState, timeRange: timeRange);
    }

    final cache = ApiCache.instance;

    final healthSummary = StatsHealthSummary(
      healthyCount: _metricValue(cache, 'healthHealthy'),
      watchCount: _metricValue(cache, 'healthWarning'),
      abnormalCount: _metricValue(cache, 'healthCritical'),
    );

    var fenceBreach = 0;
    var batteryLow = 0;
    var signalLost = 0;
    for (final a in cache.alerts) {
      final type = (a['type'] as String?)?.toUpperCase() ?? '';
      if (type.contains('FENCE')) fenceBreach++;
      if (type.contains('TEMPERATURE')) batteryLow++;
      if (type.contains('BEHAVIOR')) signalLost++;
    }
    final alertSummary = StatsAlertSummary(
      fenceBreachCount: fenceBreach,
      batteryLowCount: batteryLow,
      signalLostCount: signalLost,
      dailyTrend: const [],
    );

    final onlineDevices = _metricValue(cache, 'onlineDeviceCount');
    final totalDevices = cache.devices.isNotEmpty
        ? cache.devices.length
        : onlineDevices;
    final deviceSummary = StatsDeviceSummary(
      totalDevices: totalDevices,
      onlineCount: onlineDevices,
      weeklyOnlineRate: totalDevices > 0 ? onlineDevices / totalDevices : 0.0,
      weeklyTrend: const [],
    );

    return StatsViewData(
      viewState: viewState,
      timeRange: timeRange,
      healthSummary: healthSummary,
      alertSummary: alertSummary,
      deviceSummary: deviceSummary,
    );
  }

  static int _metricValue(ApiCache cache, String key) {
    final entry = cache.dashboardMetrics.cast<Map<String, dynamic>?>().firstWhere(
          (m) => m?['key'] == key,
          orElse: () => null,
        );
    if (entry == null) return 0;
    final v = entry['value'];
    return v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
