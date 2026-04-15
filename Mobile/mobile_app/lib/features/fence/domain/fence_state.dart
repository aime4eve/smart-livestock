import 'package:smart_livestock_demo/features/fence/domain/fence_edit_session.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';

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
  });

  final List<FenceItem> fences;
  final String? selectedFenceId;
  final ViewState viewState;
  final String? message;
  final FenceEditSession? editSession;
  final FenceEditMode? editMode;

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
    );
  }
}
