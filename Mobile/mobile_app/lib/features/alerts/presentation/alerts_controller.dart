import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/data/apply_mock_shaping.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/alerts/data/live_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/data/mock_alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';

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
    return _loadShaped(
      viewState: ViewState.normal,
      role: role,
      stage: AlertStage.pending,
    );
  }

  AlertsViewData _loadShaped({
    required ViewState viewState,
    required DemoRole role,
    required AlertStage stage,
  }) {
    final data = ref.read(alertsRepositoryProvider).load(
          viewState: viewState,
          role: role,
          stage: stage,
        );
    final appMode = ref.watch(appModeProvider);
    if (appMode.isLive ||
        data.viewState != ViewState.normal ||
        data.items.isEmpty) {
      return data;
    }

    final tier = ref.watch(subscriptionControllerProvider).tier;
    final itemMaps = data.items
        .map((a) => <String, dynamic>{
              'id': a.id,
              'title': a.title,
              'subtitle': a.subtitle,
              'priority': a.priority,
              'type': a.type,
              'stage': a.stage,
              'earTag': a.earTag,
              if (a.livestockId != null) 'livestockId': a.livestockId,
            })
        .toList();
    final result = shapeListItems(
      items: itemMaps,
      tier: tier,
      featureKeys: [FeatureFlags.alertHistory],
    );

    if (result.locked) {
      return AlertsViewData(
        viewState: ViewState.forbidden,
        role: data.role,
        stage: data.stage,
        title: '告警历史',
        subtitle: '升级套餐后可查看',
        items: const [],
        message: '当前套餐不支持告警历史',
      );
    }

    if (result.retainedCount < data.items.length) {
      final retainedIds = itemMaps
          .take(result.retainedCount)
          .map((m) => m['id'] as String)
          .toSet();
      return AlertsViewData(
        viewState: data.viewState,
        role: data.role,
        stage: data.stage,
        title: data.title,
        subtitle: data.subtitle,
        items: data.items.where((a) => retainedIds.contains(a.id)).toList(),
        message: data.message,
      );
    }

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
    NotifierProvider.family<AlertsController, AlertsViewData, DemoRole>(
  AlertsController.new,
);
