import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/farm_scoped_controller.dart';
import 'package:smart_livestock_demo/features/worker_management/data/worker_api_repository.dart';
import 'package:smart_livestock_demo/features/worker_management/domain/worker_repository.dart';

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return const WorkerApiRepository();
});

class WorkerController extends FarmScopedAsyncNotifier<List<WorkerAssignment>> {
  @override
  Future<List<WorkerAssignment>> build() async {
    final farmId = watchActiveFarmId();
    if (farmId != null) {
      return ref.read(workerRepositoryProvider).load(farmId);
    }
    return [];
  }

  Future<void> loadWorkers(String farmId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(workerRepositoryProvider).load(farmId));
  }

  Future<void> assignWorker(String farmId, Map<String, dynamic> body) async {
    await ref.read(workerRepositoryProvider).add(farmId, body);
    await loadWorkers(farmId);
  }

  Future<void> removeWorker(String farmId, String userId) async {
    await ref.read(workerRepositoryProvider).remove(farmId, userId);
    await loadWorkers(farmId);
  }
}

final workerControllerProvider =
    AsyncNotifierProvider<WorkerController, List<WorkerAssignment>>(
  WorkerController.new,
);
