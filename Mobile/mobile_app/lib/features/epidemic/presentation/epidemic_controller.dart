import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/features/epidemic/data/epidemic_api_repository.dart';
import 'package:hkt_livestock_agentic/features/epidemic/domain/epidemic_repository.dart';

final epidemicRepositoryProvider = Provider<EpidemicRepository>((ref) {
  return const EpidemicApiRepository();
});

class EpidemicController extends FarmScopedAsyncNotifier<EpidemicData> {
  @override
  Future<EpidemicData> build() async {
    watchActiveFarmId();
    return ref.read(epidemicRepositoryProvider).fetchEpidemicOverview();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(epidemicRepositoryProvider).fetchEpidemicOverview(),
    );
  }
}

final epidemicControllerProvider =
    AsyncNotifierProvider<EpidemicController, EpidemicData>(
  EpidemicController.new,
);
