import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/twin_overview/data/live_twin_overview_repository.dart';
import 'package:smart_livestock_demo/features/twin_overview/domain/twin_overview_repository.dart';

final twinOverviewRepositoryProvider = Provider<TwinOverviewRepository>((ref) {
  return const LiveTwinOverviewRepository();
});

class TwinOverviewController extends Notifier<TwinOverviewViewData> {
  @override
  TwinOverviewViewData build() {
    return ref.watch(twinOverviewRepositoryProvider).load(ViewState.normal);
  }

  void setViewState(ViewState viewState) {
    state = ref.read(twinOverviewRepositoryProvider).load(viewState);
  }
}

final twinOverviewControllerProvider =
    NotifierProvider<TwinOverviewController, TwinOverviewViewData>(
      TwinOverviewController.new,
    );
