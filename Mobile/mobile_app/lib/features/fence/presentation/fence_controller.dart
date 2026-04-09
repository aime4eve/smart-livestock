import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence/data/live_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';

final fenceRepositoryProvider = Provider<FenceRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockFenceRepository();
    case AppMode.live:
      return const LiveFenceRepository();
  }
});

class FenceController extends Notifier<FenceViewData> {
  FenceController(this.role);

  final DemoRole role;

  @override
  FenceViewData build() {
    return ref.watch(fenceRepositoryProvider).load(
      viewState: ViewState.normal,
      role: role,
      editSaved: false,
    );
  }

  void setViewState(ViewState viewState) {
    state = ref.read(fenceRepositoryProvider).load(
      viewState: viewState,
      role: state.role,
      editSaved: state.editSaved,
    );
  }

  void markEditSaved() {
    state = ref.read(fenceRepositoryProvider).load(
      viewState: state.viewState,
      role: state.role,
      editSaved: true,
    );
  }
}

final fenceControllerProvider =
    NotifierProvider.family<FenceController, FenceViewData, DemoRole>(
      FenceController.new,
    );
