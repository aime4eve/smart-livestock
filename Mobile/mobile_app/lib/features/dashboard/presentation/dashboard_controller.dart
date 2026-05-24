import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/dashboard/data/live_dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return const LiveDashboardRepository();
});

class DashboardController extends Notifier<DashboardViewData> {
  @override
  DashboardViewData build() {
    return _loadShaped(ViewState.normal, watchRepository: true);
  }

  DashboardViewData _loadShaped(
    ViewState viewState, {
    required bool watchRepository,
  }) {
    final data = watchRepository
        ? ref.watch(dashboardRepositoryProvider).load(viewState)
        : ref.read(dashboardRepositoryProvider).load(viewState);
    return data;
  }

  void setViewState(ViewState viewState) {
    state = _loadShaped(viewState, watchRepository: false);
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardViewData>(
  DashboardController.new,
);
