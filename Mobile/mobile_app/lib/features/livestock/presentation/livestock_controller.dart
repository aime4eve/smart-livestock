import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/livestock/data/live_livestock_repository.dart';
import 'package:smart_livestock_demo/features/livestock/data/mock_livestock_repository.dart';
import 'package:smart_livestock_demo/features/livestock/domain/livestock_repository.dart';

final livestockRepositoryProvider = Provider<LivestockRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockLivestockRepository();
    case AppMode.live:
      return const LiveLivestockRepository();
  }
});

class LivestockController extends Notifier<LivestockViewData> {
  LivestockController(this.earTag);

  final String earTag;

  @override
  LivestockViewData build() {
    return ref.watch(livestockRepositoryProvider).load(
          viewState: ViewState.normal,
          earTag: earTag,
        );
  }

  void setViewState(ViewState viewState) {
    state = ref.read(livestockRepositoryProvider).load(
          viewState: viewState,
          earTag: earTag,
        );
  }
}

final livestockControllerProvider =
    NotifierProvider.family<LivestockController, LivestockViewData, String>(
  LivestockController.new,
);
