class WorkerAssignment {
  const WorkerAssignment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.status,
    this.phone,
    this.assignedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String role;
  final String status;
  final String? phone;
  final String? assignedAt;

  factory WorkerAssignment.fromJson(Map<String, dynamic> json) {
    return WorkerAssignment(
      id: _s(json['id']) ?? _s(json['userId']) ?? '',
      userId: _s(json['userId']) ?? '',
      userName: _s(json['userName']) ?? _s(json['name']) ?? '',
      role: _s(json['role']) ?? 'worker',
      status: _s(json['status']) ?? 'active',
      phone: _s(json['phone']),
      assignedAt: _s(json['assignedAt']),
    );
  }
}

String? _s(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

abstract class WorkerRepository {
  Future<List<WorkerAssignment>> load(String farmId);
  Future<WorkerAssignment> create(String farmId, {required String name, required String phone, required String password});
  Future<WorkerAssignment> update(String farmId, String userId, {String? name, String? phone});
  Future<bool> updateStatus(String farmId, String userId, String status);
  Future<bool> resetPassword(String farmId, String userId, String newPassword);
  Future<void> remove(String farmId, String userId);
}
