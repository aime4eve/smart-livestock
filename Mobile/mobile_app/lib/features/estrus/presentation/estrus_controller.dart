import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/estrus/data/live_estrus_repository.dart';
import 'package:smart_livestock_demo/features/estrus/data/mock_estrus_repository.dart';
import 'package:smart_livestock_demo/features/estrus/domain/estrus_repository.dart';

final estrusRepositoryProvider = Provider<EstrusRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockEstrusRepository();
    case AppMode.live:
      return const LiveEstrusRepository();
  }
});

class EstrusPageState {
  const EstrusPageState({
    this.filter,
    required this.viewData,
  });

  final String? filter;
  final EstrusViewData viewData;
}

class EstrusController extends Notifier<EstrusPageState> {
  @override
  EstrusPageState build() {
    final data = ref.watch(estrusRepositoryProvider).load(ViewState.normal);
    return EstrusPageState(filter: null, viewData: data);
  }

  void setViewState(ViewState v) {
    final data = ref.read(estrusRepositoryProvider).load(v);
    state = EstrusPageState(filter: state.filter, viewData: data);
  }

  void setFilter(String? f) {
    state = EstrusPageState(filter: f, viewData: state.viewData);
  }
}

final estrusControllerProvider =
    NotifierProvider<EstrusController, EstrusPageState>(EstrusController.new);
