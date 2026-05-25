import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/worker_management/domain/worker_repository.dart';

class WorkerApiRepository implements WorkerRepository {
  const WorkerApiRepository();

  @override
  Future<List<WorkerAssignment>> load(String farmId) async {
    final data = await ApiClient.instance.farmGet('/members');
    final items = data['items'] as List? ?? [];
    return items.whereType<Map<String, dynamic>>().map((m) => WorkerAssignment(
      id: m['id'] as String? ?? '',
      userId: m['userId'] as String? ?? '',
      userName: m['userName'] as String? ?? m['name'] as String? ?? '',
      role: m['role'] as String? ?? 'worker',
      assignedAt: m['assignedAt'] as String? ?? '',
    )).toList();
  }

  @override
  Future<WorkerAssignment> add(String farmId, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.farmPost('/members', body: body);
    return WorkerAssignment(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'worker',
      assignedAt: data['assignedAt'] as String? ?? '',
    );
  }

  @override
  Future<void> remove(String farmId, String userId) async {
    await ApiClient.instance.farmDelete('/members/$userId');
  }
}
