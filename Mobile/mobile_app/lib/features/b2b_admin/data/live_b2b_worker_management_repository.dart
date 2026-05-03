import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/mock_b2b_worker_management_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';

class LiveB2bWorkerManagementRepository
    implements B2bWorkerManagementRepository {
  LiveB2bWorkerManagementRepository();

  static final MockB2bWorkerManagementRepository _fallback =
      MockB2bWorkerManagementRepository();

  @override
  B2bWorkerManagementViewData getSubFarms() {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.getSubFarms();
    }
    return _fallback.getSubFarms();
  }

  @override
  List<B2bSubFarmWorker> getSubFarmWorkers(String farmId) {
    final cache = ApiCache.instance;
    final data = cache.workers;
    final rawItems = data?['items'];
    if (!cache.initialized ||
        cache.lastLiveSource != 'api' ||
        cache.workersFarmId != farmId ||
        rawItems is! List) {
      return _fallback.getSubFarmWorkers(farmId);
    }

    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(_parseWorker)
        .whereType<B2bSubFarmWorker>()
        .toList();
  }

  @override
  Future<bool> assignWorker(String farmId, String workerId) async {
    final now = DateTime.now();
    return ApiCache.instance.addWorkerAssignment(
      farmId: farmId,
      id: 'b2b_wa_${now.microsecondsSinceEpoch}',
      userId: workerId,
      userName: workerId,
      role: '牧工',
      assignedAt: now.toIso8601String().substring(0, 10),
    );
  }

  @override
  Future<bool> removeWorker(String farmId, String workerId) async {
    return ApiCache.instance.removeWorkerAssignment(workerId);
  }

  @override
  List<B2bSubFarmWorker> getAvailableWorkers() {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.getAvailableWorkers();
    }
    // The workers cache only holds workers for the current farm,
    // so available workers require a separate endpoint. Fallback for now.
    return _fallback.getAvailableWorkers();
  }

  B2bSubFarmWorker? _parseWorker(Map<String, dynamic> json) {
    final id = json['id'];
    final userName = json['userName'];
    if (id is! String || id.isEmpty) return null;

    return B2bSubFarmWorker(
      id: id,
      name: userName is String ? userName : id,
      role: (json['role'] ?? '牧工') as String,
      status: (json['status'] ?? 'active') as String,
      assignedAt: json['assignedAt'] as String?,
    );
  }
}
