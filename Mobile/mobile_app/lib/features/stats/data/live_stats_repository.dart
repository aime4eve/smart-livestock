import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/stats/domain/stats_repository.dart';

class LiveStatsRepository implements StatsRepository {
  const LiveStatsRepository();

  @override
  StatsViewData load(
      {required ViewState viewState, required StatsTimeRange timeRange}) {
    return StatsViewData(viewState: viewState, timeRange: timeRange);
  }
}
