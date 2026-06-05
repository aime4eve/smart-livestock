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

  Future<void> createWorker(String farmId, {required String name, required String phone, required String password}) async {
    await ref.read(workerRepositoryProvider).create(farmId, name: name, phone: phone, password: password);
    await loadWorkers(farmId);
  }

  Future<void> updateWorker(String farmId, String userId, {String? name, String? phone}) async {
    await ref.read(workerRepositoryProvider).update(farmId, userId, name: name, phone: phone);
    await loadWorkers(farmId);
  }

  Future<void> toggleStatus(String farmId, String userId, String status) async {
    await ref.read(workerRepositoryProvider).updateStatus(farmId, userId, status);
    await loadWorkers(farmId);
  }

  Future<void> resetPassword(String farmId, String userId, String newPassword) async {
    await ref.read(workerRepositoryProvider).resetPassword(farmId, userId, newPassword);
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
