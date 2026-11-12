import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class FenceAnalyticsEventName {
  static const fenceEditEnter = 'fence_edit_enter';
  static const fenceEditSaveSuccess = 'fence_edit_save_success';
  static const fenceEditExitWithoutSave = 'fence_edit_exit_without_save';
  static const trackDraftWizardEnter = 'fence_track_draft_wizard_enter';
  static const trackDraftGenerateSuccess = 'fence_track_draft_generate_success';
  static const trackDraftLoadedIntoForm = 'fence_track_draft_loaded_into_form';
}

abstract final class FenceAnalyticsParamKey {
  static const fenceId = 'fence_id';
  static const deviceCount = 'device_count';
  static const pointCount = 'point_count';
  static const vertexCount = 'vertex_count';
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

  /// Entry card tap on the fence form (spec §3.1 entry → wizard).
  factory FenceAnalyticsEvent.trackDraftWizardEnter() {
    return const FenceAnalyticsEvent(
      FenceAnalyticsEventName.trackDraftWizardEnter,
    );
  }

  /// Wizard confirmed a successful preview; carries the device count and
  /// the valid point count used for the envelope.
  factory FenceAnalyticsEvent.trackDraftGenerateSuccess({
    required int deviceCount,
    required int pointCount,
  }) {
    return FenceAnalyticsEvent(
      FenceAnalyticsEventName.trackDraftGenerateSuccess,
      {
        FenceAnalyticsParamKey.deviceCount: deviceCount,
        FenceAnalyticsParamKey.pointCount: pointCount,
      },
    );
  }

  /// Wizard output applied to the fence form (vertices loaded onto the map).
  factory FenceAnalyticsEvent.trackDraftLoadedIntoForm(int vertexCount) {
    return FenceAnalyticsEvent(
      FenceAnalyticsEventName.trackDraftLoadedIntoForm,
      {FenceAnalyticsParamKey.vertexCount: vertexCount},
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
