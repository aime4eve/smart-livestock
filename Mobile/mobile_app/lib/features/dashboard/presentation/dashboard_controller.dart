import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/dashboard/data/live_dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockDashboardRepository();
    case AppMode.live:
      return const LiveDashboardRepository();
  }
});

class DashboardController extends Notifier<DashboardViewData> {
  @override
  DashboardViewData build() {
    return ref.watch(dashboardRepositoryProvider).load(ViewState.normal);
  }

  void setViewState(ViewState viewState) {
    state = ref.read(dashboardRepositoryProvider).load(viewState);
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardViewData>(
      DashboardController.new,
    );
