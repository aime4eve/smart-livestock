import 'package:smart_livestock_demo/core/models/core_models.dart';
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

    return StatsViewData(
      viewState: viewState,
      timeRange: timeRange,
      healthSummary: StatsHealthSummary(
        healthyCount: 0,
        watchCount: 0,
        abnormalCount: 0,
      ),
      alertSummary: StatsAlertSummary(
        fenceBreachCount: 0,
        batteryLowCount: 0,
        signalLostCount: 0,
        dailyTrend: const [],
      ),
      deviceSummary: StatsDeviceSummary(
        totalDevices: 0,
        onlineCount: 0,
        weeklyOnlineRate: 0.0,
        weeklyTrend: const [],
      ),
    );
  }
}
