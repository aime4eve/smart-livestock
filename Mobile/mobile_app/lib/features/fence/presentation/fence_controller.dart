import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence/data/live_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_state.dart';

final fenceRepositoryProvider = Provider<FenceRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockFenceRepository();
    case AppMode.live:
      return const LiveFenceRepository();
  }
});

class FenceController extends Notifier<FenceState> {
  @override
  FenceState build() {
    final fences = ref.watch(fenceRepositoryProvider).loadAll();
    return FenceState(
      fences: fences,
      viewState: fences.isEmpty ? ViewState.empty : ViewState.normal,
    );
  }

  void select(String? id) {
    state = state.copyWith(selectedFenceId: id);
  }

  void add(FenceItem item) {
    state = state.copyWith(
      fences: [...state.fences, item],
      viewState: ViewState.normal,
    );
  }

  void update(FenceItem item) {
    state = state.copyWith(
      fences: [
        for (final f in state.fences)
          if (f.id == item.id) item else f,
      ],
    );
  }

  void delete(String id) {
    final newFences = state.fences.where((f) => f.id != id).toList();
    state = FenceState(
      fences: newFences,
      selectedFenceId:
          state.selectedFenceId == id ? null : state.selectedFenceId,
      viewState: newFences.isEmpty ? ViewState.empty : state.viewState,
    );
  }
}

final fenceControllerProvider =
    NotifierProvider<FenceController, FenceState>(FenceController.new);
