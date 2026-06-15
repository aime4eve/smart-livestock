import 'package:hkt_livestock_agentic/features/fence/domain/fence_edit_session.dart';
import 'package:hkt_livestock_agentic/core/models/view_state.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_item.dart';
import 'package:hkt_livestock_agentic/features/livestock/data/map_api_repository.dart';

enum FenceEditMode { editIdle, editDirty, saving }

const _unset = Object();

class FenceState {
  const FenceState({
    required this.fences,
    this.selectedFenceId,
    required this.viewState,
    this.message,
    this.editSession,
    this.editMode,
    this.livestockPositions = const [],
  });

  final List<FenceItem> fences;
  final String? selectedFenceId;
  final ViewState viewState;
  final String? message;
  final FenceEditSession? editSession;
  final FenceEditMode? editMode;
  final List<GpsPoint> livestockPositions;

  FenceItem? get selectedFence {
    if (selectedFenceId == null) return null;
    for (final f in fences) {
      if (f.id == selectedFenceId) return f;
    }
    return null;
  }

  FenceState copyWith({
    List<FenceItem>? fences,
    Object? selectedFenceId = _unset,
    bool clearSelectedFence = false,
    ViewState? viewState,
    String? message,
    FenceEditSession? editSession,
    bool clearEditSession = false,
    FenceEditMode? editMode,
    bool clearEditMode = false,
    List<GpsPoint>? livestockPositions,
  }) {
    return FenceState(
      fences: fences ?? this.fences,
      selectedFenceId: clearSelectedFence
          ? null
          : (identical(selectedFenceId, _unset)
              ? this.selectedFenceId
              : selectedFenceId as String?),
      viewState: viewState ?? this.viewState,
      message: message ?? this.message,
      editSession: clearEditSession ? null : (editSession ?? this.editSession),
      editMode: clearEditMode ? null : (editMode ?? this.editMode),
      livestockPositions: livestockPositions ?? this.livestockPositions,
    );
  }
}
