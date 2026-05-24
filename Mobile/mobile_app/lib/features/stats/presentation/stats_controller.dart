import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/stats/data/live_stats_repository.dart';
import 'package:smart_livestock_demo/features/stats/domain/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return const LiveStatsRepository();
});

class StatsController extends Notifier<StatsViewData> {
  @override
  StatsViewData build() {
    return _loadShaped(
      viewState: ViewState.normal,
      timeRange: StatsTimeRange.d7,
      watchRepository: true,
    );
  }

  StatsViewData _loadShaped({
    required ViewState viewState,
    required StatsTimeRange timeRange,
    required bool watchRepository,
  }) {
    final data = watchRepository
        ? ref.watch(statsRepositoryProvider).load(
              viewState: viewState,
              timeRange: timeRange,
            )
        : ref.read(statsRepositoryProvider).load(
              viewState: viewState,
              timeRange: timeRange,
            );
    return data;
  }

  void setViewState(ViewState viewState) {
    state = _loadShaped(
      viewState: viewState,
      timeRange: state.timeRange,
      watchRepository: false,
    );
  }

  void setTimeRange(StatsTimeRange range) {
    state = _loadShaped(
      viewState: state.viewState,
      timeRange: range,
      watchRepository: false,
    );
  }
}

final statsControllerProvider =
    NotifierProvider<StatsController, StatsViewData>(
  StatsController.new,
);
