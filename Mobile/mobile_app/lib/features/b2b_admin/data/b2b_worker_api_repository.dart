import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';

class B2bWorkerApiRepository implements B2bWorkerManagementRepository {
  const B2bWorkerApiRepository();

  @override
  Future<B2bWorkerManagementViewData> getSubFarms() async {
    final data = await ApiClient.instance.get('/b2b/farms');
    final items = data['items'] as List? ?? [];
    final farms = items.whereType<Map<String, dynamic>>().map((f) => B2bSubFarm(
      id: f['id'] as String,
      name: f['name'] as String,
      workerCount: f['workerCount'] as int? ?? 0,
      livestockCount: f['livestockCount'] as int? ?? 0,
      deviceCount: f['deviceCount'] as int? ?? 0,
    )).toList();
    return B2bWorkerManagementViewData(
      subFarms: farms,
      totalWorkers: data['totalWorkers'] as int? ?? farms.fold(0, (s, f) => s + f.workerCount),
    );
  }

  @override
  Future<List<B2bSubFarmWorker>> getSubFarmWorkers(String farmId) async {
    final data = await ApiClient.instance.get('/b2b/farms/$farmId/workers');
    final items = data['items'] as List? ?? [];
    return items.whereType<Map<String, dynamic>>().map((w) => B2bSubFarmWorker(
      id: w['id'] as String,
      name: w['name'] as String,
      role: w['role'] as String? ?? 'worker',
      status: w['status'] as String? ?? 'active',
      assignedAt: w['assignedAt'] as String?,
    )).toList();
  }

  @override
  Future<bool> assignWorker(String farmId, String workerId) async {
    await ApiClient.instance.post('/b2b/farms/$farmId/workers', body: {'workerId': workerId});
    return true;
  }

  @override
  Future<bool> removeWorker(String farmId, String workerId) async {
    await ApiClient.instance.delete('/b2b/farms/$farmId/workers/$workerId');
    return true;
  }

  @override
  Future<List<B2bSubFarmWorker>> getAvailableWorkers() async {
    final data = await ApiClient.instance.get('/b2b/available-workers');
    final items = data['items'] as List? ?? [];
    return items.whereType<Map<String, dynamic>>().map((w) => B2bSubFarmWorker(
      id: w['id'] as String,
      name: w['name'] as String,
      role: w['role'] as String? ?? 'worker',
      status: w['status'] as String? ?? 'active',
      assignedAt: w['assignedAt'] as String?,
    )).toList();
  }
}
