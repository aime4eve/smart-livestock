import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/mine/data/live_mine_repository.dart';
import 'package:smart_livestock_demo/features/mine/data/mock_mine_repository.dart';
import 'package:smart_livestock_demo/features/mine/domain/mine_repository.dart';

final mineRepositoryProvider = Provider<MineRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockMineRepository();
    case AppMode.live:
      return const LiveMineRepository();
  }
});

class MineController extends Notifier<MineViewData> {
  @override
  MineViewData build() {
    return ref.watch(mineRepositoryProvider).load(ViewState.normal);
  }

  void setViewState(ViewState viewState) {
    state = ref.read(mineRepositoryProvider).load(viewState);
  }
}

final mineControllerProvider = NotifierProvider<MineController, MineViewData>(
  MineController.new,
);
