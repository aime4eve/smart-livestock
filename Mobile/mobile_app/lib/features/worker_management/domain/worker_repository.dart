class WorkerAssignment {
  const WorkerAssignment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.assignedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String role;
  final String assignedAt;
}

abstract class WorkerRepository {
  Future<List<WorkerAssignment>> load(String farmId);
  Future<WorkerAssignment> add(String farmId, Map<String, dynamic> body);
  Future<void> remove(String farmId, String userId);
}
