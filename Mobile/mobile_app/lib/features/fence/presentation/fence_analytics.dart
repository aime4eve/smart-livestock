import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class FenceAnalyticsEventName {
  static const fenceEditEnter = 'fence_edit_enter';
  static const fenceEditSaveSuccess = 'fence_edit_save_success';
  static const fenceEditExitWithoutSave = 'fence_edit_exit_without_save';
}

abstract final class FenceAnalyticsParamKey {
  static const fenceId = 'fence_id';
}

class FenceAnalyticsEvent {
  const FenceAnalyticsEvent(this.name, [this.parameters]);

  final String name;
  final Map<String, Object?>? parameters;

  factory FenceAnalyticsEvent.fenceEditEnter(String fenceId) {
    return FenceAnalyticsEvent(
      FenceAnalyticsEventName.fenceEditEnter,
      {FenceAnalyticsParamKey.fenceId: fenceId},
    );
  }

  factory FenceAnalyticsEvent.fenceEditSaveSuccess(String fenceId) {
    return FenceAnalyticsEvent(
      FenceAnalyticsEventName.fenceEditSaveSuccess,
      {FenceAnalyticsParamKey.fenceId: fenceId},
    );
  }

  factory FenceAnalyticsEvent.fenceEditExitWithoutSave(String fenceId) {
    return FenceAnalyticsEvent(
      FenceAnalyticsEventName.fenceEditExitWithoutSave,
      {FenceAnalyticsParamKey.fenceId: fenceId},
    );
  }
}

abstract class FenceAnalyticsSink {
  void emitEvent(FenceAnalyticsEvent event);
}

class InMemoryFenceAnalyticsSink implements FenceAnalyticsSink {
  final List<FenceAnalyticsEvent> events = [];

  @override
  void emitEvent(FenceAnalyticsEvent event) {
    events.add(event);
  }
}

final fenceAnalyticsSinkProvider = Provider<FenceAnalyticsSink>((ref) {
  return InMemoryFenceAnalyticsSink();
});
