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

class EpidemicWorkbenchController extends FarmScopedAsyncNotifier<EpidemicWorkbenchData> {
  String? sourceLivestockId;
  int windowHours = 72;

  @override
  Future<EpidemicWorkbenchData> build() async {
    watchActiveFarmId();
    return ref.read(epidemicRepositoryProvider).fetchWorkbench(
          sourceLivestockId: sourceLivestockId,
          windowHours: windowHours,
        );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref
        .read(epidemicRepositoryProvider)
        .fetchWorkbench(sourceLivestockId: sourceLivestockId, windowHours: windowHours));
  }

  Future<void> setSource(String? value) async {
    sourceLivestockId = value;
    await refresh();
  }

  Future<void> setWindowHours(int value) async {
    windowHours = value;
    await refresh();
  }

  Future<void> markDisposition(EpidemicLivestockItem item) async {
    await ref.read(epidemicRepositoryProvider).createDisposition(
          livestockId: item.livestockId,
          sourceLivestockId: state.value!.context.source.livestockId,
          actionCode: item.recommendedAction,
        );
    await refresh();
  }

  Future<void> complete(EpidemicLivestockItem item) async {
    final id = item.dispositionId;
    if (id != null) {
      await ref.read(epidemicRepositoryProvider).completeDisposition(id);
      await refresh();
    }
  }
}

final epidemicWorkbenchControllerProvider =
    AsyncNotifierProvider<EpidemicWorkbenchController, EpidemicWorkbenchData>(
  EpidemicWorkbenchController.new,
);

class EpidemicContactController extends AsyncNotifier<ContactNetworkResponse> {
  EpidemicContactController(this.livestockId);
  final String livestockId;

  @override
  Future<ContactNetworkResponse> build() async {
    return ref.read(epidemicRepositoryProvider).fetchContactNetwork(livestockId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(epidemicRepositoryProvider).fetchContactNetwork(livestockId),
    );
  }

  Future<void> markDiseased(String diseaseType) async {
    await ref.read(epidemicRepositoryProvider).markDiseased(livestockId, diseaseType);
    await refresh();
  }

  Future<void> unmarkDiseased() async {
    await ref.read(epidemicRepositoryProvider).unmarkDiseased(livestockId);
    await refresh();
  }
}

final epidemicContactControllerProvider =
    AsyncNotifierProvider.family<EpidemicContactController, ContactNetworkResponse, String>(
  EpidemicContactController.new,
);
