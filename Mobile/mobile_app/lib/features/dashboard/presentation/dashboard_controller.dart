import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/data/apply_mock_shaping.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/dashboard/data/live_dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';

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
    return _loadShaped(ViewState.normal, watchRepository: true);
  }

  DashboardViewData _loadShaped(
    ViewState viewState, {
    required bool watchRepository,
  }) {
    final data = watchRepository
        ? ref.watch(dashboardRepositoryProvider).load(viewState)
        : ref.read(dashboardRepositoryProvider).load(viewState);
    final appMode = ref.watch(appModeProvider);
    if (appMode.isLive || data.viewState != ViewState.normal) return data;

    final tier = ref.watch(subscriptionControllerProvider).tier;
    final itemMaps =
        data.metrics.map((m) => <String, dynamic>{'id': m.widgetKey}).toList();
    final result = shapeListItems(
      items: itemMaps,
      tier: tier,
      featureKeys: [FeatureFlags.dashboardSummary],
    );
    if (result.retainedCount < data.metrics.length) {
      return DashboardViewData(
        viewState: data.viewState,
        metrics: data.metrics.take(result.retainedCount).toList(),
        message: data.message,
      );
    }
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
