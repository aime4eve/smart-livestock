import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fence_create/data/live_fence_create_repository.dart';
import 'package:smart_livestock_demo/features/fence_create/data/mock_fence_create_repository.dart';
import 'package:smart_livestock_demo/features/fence_create/domain/fence_create_repository.dart';

final fenceCreateRepositoryProvider = Provider<FenceCreateRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockFenceCreateRepository();
    case AppMode.live:
      return const LiveFenceCreateRepository();
  }
});

class FenceCreateController extends Notifier<FenceCreateViewData> {
  @override
  FenceCreateViewData build() {
    return ref.watch(fenceCreateRepositoryProvider).load(
          viewState: ViewState.normal,
        );
  }

  void setViewState(ViewState viewState) {
    state = ref
        .read(fenceCreateRepositoryProvider)
        .load(viewState: viewState)
        .copyWith(
          name: state.name,
          fenceType: state.fenceType,
          enterAlert: state.enterAlert,
          leaveAlert: state.leaveAlert,
        );
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setFenceType(FenceType type) {
    state = state.copyWith(fenceType: type);
  }

  void setEnterAlert(bool value) {
    state = state.copyWith(enterAlert: value);
  }

  void setLeaveAlert(bool value) {
    state = state.copyWith(leaveAlert: value);
  }

  void save() {
    state = state.copyWith(saving: true);
    Future.delayed(const Duration(milliseconds: 500), () {
      state = state.copyWith(saving: false, saved: true);
    });
  }
}

final fenceCreateControllerProvider =
    NotifierProvider<FenceCreateController, FenceCreateViewData>(
  FenceCreateController.new,
);
