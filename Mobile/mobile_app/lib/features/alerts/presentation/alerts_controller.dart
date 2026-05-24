import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/data/live_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return const LiveAlertsRepository();
});

class AlertsController extends Notifier<AlertsViewData> {
  AlertsController(this.role);

  final UserRole role;

  @override
  AlertsViewData build() {
    return _loadShaped(
      viewState: ViewState.normal,
      role: role,
      stage: AlertStage.pending,
    );
  }

  AlertsViewData _loadShaped({
    required ViewState viewState,
    required UserRole role,
    required AlertStage stage,
  }) {
    final data = ref.read(alertsRepositoryProvider).load(
          viewState: viewState,
          role: role,
          stage: stage,
        );
    return data;
  }

  void setViewState(ViewState viewState) {
    state = _loadShaped(
      viewState: viewState,
      role: state.role,
      stage: state.stage,
    );
  }

  void acknowledge() {
    state = _loadShaped(
      viewState: state.viewState,
      role: state.role,
      stage: AlertStage.acknowledged,
    );
  }

  void handle() {
    state = _loadShaped(
      viewState: state.viewState,
      role: state.role,
      stage: AlertStage.handled,
    );
  }

  void archive() {
    state = _loadShaped(
      viewState: state.viewState,
      role: state.role,
      stage: AlertStage.archived,
    );
  }
}

final alertsControllerProvider =
    NotifierProvider.family<AlertsController, AlertsViewData, UserRole>(
  AlertsController.new,
);
