import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/api/api_exception.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';

String _parseId(dynamic raw) =>
    raw is int ? raw.toString() : (raw as String? ?? '');

class B2bWorkerApiRepository implements B2bWorkerManagementRepository {
  const B2bWorkerApiRepository();

  @override
  Future<B2bWorkerManagementViewData> getSubFarms() async {
    final Map<String, dynamic> data;
    try {
      data = await ApiClient.instance.get('/b2b/farms');
    } on NotFoundException {
      return const B2bWorkerManagementViewData();
    }
    final items = data['items'] as List? ?? [];
    final farms =
        items.whereType<Map<String, dynamic>>().map((f) => B2bSubFarm(
              id: _parseId(f['id']),
              name: f['name'] as String,
              workerCount: f['workerCount'] as int? ?? 0,
              livestockCount: f['livestockCount'] as int? ?? 0,
              deviceCount: f['deviceCount'] as int? ?? 0,
              latitude: (f['latitude'] as num?)?.toDouble(),
              longitude: (f['longitude'] as num?)?.toDouble(),
              areaHectares: (f['areaHectares'] as num?)?.toDouble(),
            )).toList();
    return B2bWorkerManagementViewData(
      subFarms: farms,
      totalWorkers: data['totalWorkers'] as int? ??
          farms.fold(0, (s, f) => s + f.workerCount),
      offlineWorkerCount: data['offlineWorkerCount'] as int? ?? 0,
    );
  }

  @override
  Future<List<B2bSubFarmWorker>> getSubFarmWorkers(String farmId) async {
    final Map<String, dynamic> data;
    try {
      data =
          await ApiClient.instance.get('/b2b/farms/$farmId/workers');
    } on NotFoundException {
      return const [];
    }
    final items = data['items'] as List? ?? [];
    return items.whereType<Map<String, dynamic>>().map((w) => B2bSubFarmWorker(
          id: _parseId(w['id']),
          name: w['name'] as String,
          role: w['role'] as String? ?? 'worker',
          status: w['status'] as String? ?? 'active',
          phone: w['phone'] as String?,
          assignedAt: w['assignedAt'] as String?,
        )).toList();
  }

  @override
  Future<bool> assignWorker(String farmId, String workerId) async {
    await ApiClient.instance
        .post('/b2b/farms/$farmId/workers', body: {'workerId': workerId});
    return true;
  }

  @override
  Future<bool> removeWorker(String farmId, String workerId) async {
    await ApiClient.instance
        .delete('/b2b/farms/$farmId/workers/$workerId');
    return true;
  }

  @override
  Future<List<B2bSubFarmWorker>> getAvailableWorkers() async {
    final Map<String, dynamic> data;
    try {
      data = await ApiClient.instance.get('/b2b/available-workers');
    } on NotFoundException {
      return const [];
    }
    final items = data['items'] as List? ?? [];
    return items.whereType<Map<String, dynamic>>().map((w) => B2bSubFarmWorker(
          id: _parseId(w['id']),
          name: w['name'] as String,
          role: w['role'] as String? ?? 'worker',
          status: w['status'] as String? ?? 'active',
          phone: w['phone'] as String?,
          assignedAt: w['assignedAt'] as String?,
        )).toList();
  }

  @override
  Future<B2bSubFarmWorker> createWorker({required String name, required String phone, required String password}) async {
    final data = await ApiClient.instance.post('/b2b/users', body: {
      'name': name,
      'phone': phone,
      'password': password,
    });
    return B2bSubFarmWorker(
      id: _parseId(data['id']),
      name: data['name'] as String,
      role: 'worker',
      status: 'active',
      phone: data['phone'] as String?,
    );
  }

  @override
  Future<B2bSubFarmWorker> updateWorker(String userId, {String? name, String? phone}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    final data = await ApiClient.instance.put('/b2b/users/$userId', body: body);
    return B2bSubFarmWorker(
      id: _parseId(data['id']),
      name: data['name'] as String,
      role: 'worker',
      status: 'active',
      phone: data['phone'] as String?,
    );
  }

  @override
  Future<bool> updateWorkerStatus(String userId, String status) async {
    await ApiClient.instance.put('/b2b/users/$userId/status', body: {'status': status});
    return true;
  }

  @override
  Future<bool> resetWorkerPassword(String userId, String newPassword) async {
    await ApiClient.instance.put('/b2b/users/$userId/reset-password', body: {'password': newPassword});
    return true;
  }
}
