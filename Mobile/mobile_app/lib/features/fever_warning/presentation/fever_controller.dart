import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fever_warning/data/live_fever_repository.dart';
import 'package:smart_livestock_demo/features/fever_warning/domain/fever_repository.dart';

final feverRepositoryProvider = Provider<FeverRepository>((ref) {
  return const LiveFeverRepository();
});

class FeverPageState {
  const FeverPageState({
    this.filter,
    required this.viewData,
  });

  final String? filter;
  final FeverViewData viewData;
}

class FeverController extends Notifier<FeverPageState> {
  @override
  FeverPageState build() {
    final data = ref.watch(feverRepositoryProvider).load(ViewState.normal);
    return FeverPageState(filter: null, viewData: data);
  }

  void setViewState(ViewState v) {
    final data = ref.read(feverRepositoryProvider).load(v);
    state = FeverPageState(filter: state.filter, viewData: data);
  }

  void setFilter(String? f) {
    state = FeverPageState(filter: f, viewData: state.viewData);
  }
}

final feverControllerProvider =
    NotifierProvider<FeverController, FeverPageState>(FeverController.new);
