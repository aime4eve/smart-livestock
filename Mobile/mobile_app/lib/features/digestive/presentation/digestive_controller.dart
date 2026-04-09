import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/digestive/data/live_digestive_repository.dart';
import 'package:smart_livestock_demo/features/digestive/data/mock_digestive_repository.dart';
import 'package:smart_livestock_demo/features/digestive/domain/digestive_repository.dart';

final digestiveRepositoryProvider = Provider<DigestiveRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockDigestiveRepository();
    case AppMode.live:
      return const LiveDigestiveRepository();
  }
});

class DigestivePageState {
  const DigestivePageState({
    this.filter,
    required this.viewData,
  });

  final String? filter;
  final DigestiveViewData viewData;
}

class DigestiveController extends Notifier<DigestivePageState> {
  @override
  DigestivePageState build() {
    final data = ref.watch(digestiveRepositoryProvider).load(ViewState.normal);
    return DigestivePageState(filter: null, viewData: data);
  }

  void setViewState(ViewState v) {
    final data = ref.read(digestiveRepositoryProvider).load(v);
    state = DigestivePageState(filter: state.filter, viewData: data);
  }

  void setFilter(String? f) {
    state = DigestivePageState(filter: f, viewData: state.viewData);
  }
}

final digestiveControllerProvider =
    NotifierProvider<DigestiveController, DigestivePageState>(
      DigestiveController.new,
    );
