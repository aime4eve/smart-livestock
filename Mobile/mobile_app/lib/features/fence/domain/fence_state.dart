import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';

class FenceState {
  const FenceState({
    required this.fences,
    this.selectedFenceId,
    required this.viewState,
    this.message,
  });

  final List<FenceItem> fences;
  final String? selectedFenceId;
  final ViewState viewState;
  final String? message;

  FenceItem? get selectedFence {
    if (selectedFenceId == null) return null;
    for (final f in fences) {
      if (f.id == selectedFenceId) return f;
    }
    return null;
  }

  FenceState copyWith({
    List<FenceItem>? fences,
    String? selectedFenceId,
    bool clearSelectedFence = false,
    ViewState? viewState,
    String? message,
  }) {
    return FenceState(
      fences: fences ?? this.fences,
      selectedFenceId:
          clearSelectedFence ? null : (selectedFenceId ?? this.selectedFenceId),
      viewState: viewState ?? this.viewState,
      message: message ?? this.message,
    );
  }
}
