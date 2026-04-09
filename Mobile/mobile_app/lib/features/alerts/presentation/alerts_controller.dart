import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/data/live_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/data/mock_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockAlertsRepository();
    case AppMode.live:
      return const LiveAlertsRepository();
  }
});

class AlertsController extends Notifier<AlertsViewData> {
  AlertsController(this.role);

  final DemoRole role;

  @override
  AlertsViewData build() {
    return ref.watch(alertsRepositoryProvider).load(
      viewState: ViewState.normal,
      role: role,
      stage: AlertStage.pending,
    );
  }

  void setViewState(ViewState viewState) {
    state = ref.read(alertsRepositoryProvider).load(
      viewState: viewState,
      role: state.role,
      stage: state.stage,
    );
  }

  void acknowledge() {
    state = ref.read(alertsRepositoryProvider).load(
      viewState: state.viewState,
      role: state.role,
      stage: AlertStage.acknowledged,
    );
  }

  void handle() {
    state = ref.read(alertsRepositoryProvider).load(
      viewState: state.viewState,
      role: state.role,
      stage: AlertStage.handled,
    );
  }

  void archive() {
    state = ref.read(alertsRepositoryProvider).load(
      viewState: state.viewState,
      role: state.role,
      stage: AlertStage.archived,
    );
  }
}

final alertsControllerProvider =
    NotifierProvider.family<AlertsController, AlertsViewData, DemoRole>(
      AlertsController.new,
    );
