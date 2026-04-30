import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/worker_management/domain/worker_repository.dart';

class MockWorkerRepository implements WorkerRepository {
  const MockWorkerRepository();

  static const List<_WorkerAssignmentRecord> _seedAssignments = [
    _WorkerAssignmentRecord(
      farmId: 'tenant_001',
      id: 'wfa_001',
      userId: 'u_002',
      userName: '李四（牧工）',
      role: 'worker',
      assignedAt: '2026-04-28T00:00:00+08:00',
    ),
    _WorkerAssignmentRecord(
      farmId: 'tenant_007',
      id: 'wfa_002',
      userId: 'u_002',
      userName: '李四（牧工）',
      role: 'worker',
      assignedAt: '2026-04-29T00:00:00+08:00',
    ),
  ];

  static final List<_WorkerAssignmentRecord> _assignments =
      List<_WorkerAssignmentRecord>.from(_seedAssignments);

  static int _nextAssignmentNumber = 3;

  @override
  WorkersViewData load({
    required ViewState viewState,
    required String farmId,
  }) {
    final items = _assignments
        .where((assignment) => assignment.farmId == farmId)
        .map((assignment) => assignment.toPublic())
        .toList();

    return WorkersViewData(
      viewState: viewState,
      items: viewState == ViewState.normal ? items : const [],
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无牧工',
        ViewState.error => '加载失败（演示）',
        ViewState.forbidden => '无权限管理牧工（演示）',
        ViewState.offline => '离线数据（演示）',
        ViewState.normal => null,
      },
    );
  }

  @override
  bool assign(String farmId, String userId, {String role = 'worker'}) {
    final exists = _assignments.any(
      (assignment) => assignment.farmId == farmId && assignment.userId == userId,
    );
    if (exists) return false;
    final assignmentNumber = _nextAssignmentNumber++;
    _assignments.add(
      _WorkerAssignmentRecord(
        farmId: farmId,
        id: 'wfa_mock_${assignmentNumber.toString().padLeft(3, '0')}',
        userId: userId,
        userName: userId == 'u_002' ? '李四（牧工）' : userId,
        role: role,
        assignedAt: DateTime.now().toIso8601String(),
      ),
    );
    return true;
  }

  @override
  bool unassign(String assignmentId) {
    final before = _assignments.length;
    _assignments.removeWhere((assignment) => assignment.id == assignmentId);
    return _assignments.length != before;
  }

  static void resetForTesting() {
    _assignments
      ..clear()
      ..addAll(_seedAssignments);
    _nextAssignmentNumber = 3;
  }
}

class _WorkerAssignmentRecord {
  const _WorkerAssignmentRecord({
    required this.farmId,
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.assignedAt,
  });

  final String farmId;
  final String id;
  final String userId;
  final String userName;
  final String role;
  final String assignedAt;

  WorkerAssignment toPublic() {
    return WorkerAssignment(
      id: id,
      userId: userId,
      userName: userName,
      role: role,
      assignedAt: assignedAt,
    );
  }
}
