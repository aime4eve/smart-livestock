import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/stats/data/live_stats_repository.dart';
import 'package:smart_livestock_demo/features/stats/data/mock_stats_repository.dart';
import 'package:smart_livestock_demo/features/stats/domain/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockStatsRepository();
    case AppMode.live:
      return const LiveStatsRepository();
  }
});

class StatsController extends Notifier<StatsViewData> {
  @override
  StatsViewData build() {
    return ref.watch(statsRepositoryProvider).load(
          viewState: ViewState.normal,
          timeRange: StatsTimeRange.d7,
        );
  }

  void setViewState(ViewState viewState) {
    state = ref.read(statsRepositoryProvider).load(
          viewState: viewState,
          timeRange: state.timeRange,
        );
  }

  void setTimeRange(StatsTimeRange range) {
    state = ref.read(statsRepositoryProvider).load(
          viewState: state.viewState,
          timeRange: range,
        );
  }
}

final statsControllerProvider =
    NotifierProvider<StatsController, StatsViewData>(
  StatsController.new,
);
