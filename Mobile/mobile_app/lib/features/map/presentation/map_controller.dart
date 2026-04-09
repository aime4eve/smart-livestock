import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/models/demo_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/map/data/live_map_repository.dart';
import 'package:smart_livestock_demo/features/map/data/mock_map_repository.dart';
import 'package:smart_livestock_demo/features/map/domain/map_repository.dart';

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockMapRepository();
    case AppMode.live:
      return const LiveMapRepository();
  }
});

class MapController extends Notifier<MapViewData> {
  @override
  MapViewData build() {
    return ref.watch(mapRepositoryProvider).load(
      viewState: ViewState.normal,
      selectedAnimal: DemoSeed.earTags.first,
      selectedRange: TrajectoryRange.h24,
    );
  }

  void setViewState(ViewState viewState) {
    state = ref.read(mapRepositoryProvider).load(
      viewState: viewState,
      selectedAnimal: state.selectedAnimal,
      selectedRange: state.selectedRange,
    );
  }

  void selectAnimal(String animal) {
    state = ref.read(mapRepositoryProvider).load(
      viewState: state.viewState,
      selectedAnimal: animal,
      selectedRange: state.selectedRange,
    );
  }

  void selectRange(TrajectoryRange range) {
    state = ref.read(mapRepositoryProvider).load(
      viewState: state.viewState,
      selectedAnimal: state.selectedAnimal,
      selectedRange: range,
    );
  }
}

final mapControllerProvider = NotifierProvider<MapController, MapViewData>(
  MapController.new,
);
