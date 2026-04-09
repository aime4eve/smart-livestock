import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

class StatsViewData {
  const StatsViewData({
    required this.viewState,
    required this.timeRange,
    this.healthSummary,
    this.alertSummary,
    this.deviceSummary,
    this.message,
  });

  final ViewState viewState;
  final StatsTimeRange timeRange;
  final StatsHealthSummary? healthSummary;
  final StatsAlertSummary? alertSummary;
  final StatsDeviceSummary? deviceSummary;
  final String? message;
}

abstract class StatsRepository {
  StatsViewData load({
    required ViewState viewState,
    required StatsTimeRange timeRange,
  });
}
