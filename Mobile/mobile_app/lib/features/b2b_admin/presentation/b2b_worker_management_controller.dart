import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/b2b_worker_api_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';

final b2bWorkerManagementRepositoryProvider =
    Provider<B2bWorkerManagementRepository>((ref) {
  return const B2bWorkerApiRepository();
});

class B2bWorkerManagementController
    extends AsyncNotifier<B2bWorkerManagementViewData> {
  @override
  Future<B2bWorkerManagementViewData> build() async {
    return ref.read(b2bWorkerManagementRepositoryProvider).getSubFarms();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(b2bWorkerManagementRepositoryProvider).getSubFarms());
  }

  Future<List<B2bSubFarmWorker>> getSubFarmWorkers(String farmId) {
    return ref.read(b2bWorkerManagementRepositoryProvider).getSubFarmWorkers(farmId);
  }

  Future<bool> assignWorker(String farmId, String workerId) async {
    final ok = await ref.read(b2bWorkerManagementRepositoryProvider).assignWorker(farmId, workerId);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> removeWorker(String farmId, String workerId) async {
    final ok = await ref.read(b2bWorkerManagementRepositoryProvider).removeWorker(farmId, workerId);
    if (ok) await refresh();
    return ok;
  }

  Future<List<B2bSubFarmWorker>> getAvailableWorkers() {
    return ref.read(b2bWorkerManagementRepositoryProvider).getAvailableWorkers();
  }
}

final b2bWorkerManagementControllerProvider =
    AsyncNotifierProvider<B2bWorkerManagementController,
        B2bWorkerManagementViewData>(
  B2bWorkerManagementController.new,
);
