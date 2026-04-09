import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/epidemic/data/live_epidemic_repository.dart';
import 'package:smart_livestock_demo/features/epidemic/data/mock_epidemic_repository.dart';
import 'package:smart_livestock_demo/features/epidemic/domain/epidemic_repository.dart';

final epidemicRepositoryProvider = Provider<EpidemicRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockEpidemicRepository();
    case AppMode.live:
      return const LiveEpidemicRepository();
  }
});

class EpidemicController extends Notifier<EpidemicViewData> {
  @override
  EpidemicViewData build() {
    return ref.watch(epidemicRepositoryProvider).load(ViewState.normal);
  }

  void setViewState(ViewState viewState) {
    state = ref.read(epidemicRepositoryProvider).load(viewState);
  }
}

final epidemicControllerProvider =
    NotifierProvider<EpidemicController, EpidemicViewData>(
      EpidemicController.new,
    );
