import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/worker_management/domain/worker_repository.dart';

class WorkerApiRepository implements WorkerRepository {
  const WorkerApiRepository();

  @override
  Future<List<WorkerAssignment>> load(String farmId) async {
    final data = await ApiClient.instance.farmGet('/members');
    final items = data['items'] as List? ?? [];
    return items.whereType<Map<String, dynamic>>().map(WorkerAssignment.fromJson).toList();
  }

  @override
  Future<WorkerAssignment> create(String farmId, {required String name, required String phone, required String password}) async {
    final data = await ApiClient.instance.farmPost('/workers', body: {
      'name': name,
      'phone': phone,
      'password': password,
    });
    return WorkerAssignment.fromJson(data);
  }

  @override
  Future<WorkerAssignment> update(String farmId, String userId, {String? name, String? phone}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    final data = await ApiClient.instance.farmPut('/workers/$userId', body: body);
    return WorkerAssignment.fromJson(data);
  }

  @override
  Future<bool> updateStatus(String farmId, String userId, String status) async {
    await ApiClient.instance.farmPut('/workers/$userId/status', body: {'status': status});
    return true;
  }

  @override
  Future<bool> resetPassword(String farmId, String userId, String newPassword) async {
    await ApiClient.instance.farmPut('/workers/$userId/reset-password', body: {'password': newPassword});
    return true;
  }

  @override
  Future<void> remove(String farmId, String userId) async {
    await ApiClient.instance.farmDelete('/members/$userId');
  }
}
