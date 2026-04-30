import 'package:smart_livestock_demo/core/models/view_state.dart';

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

class WorkersViewData {
  const WorkersViewData({
    required this.viewState,
    this.items = const [],
    this.message,
  });

  final ViewState viewState;
  final List<WorkerAssignment> items;
  final String? message;
}

abstract class WorkerRepository {
  WorkersViewData load({
    required ViewState viewState,
    required String farmId,
  });

  bool assign(String farmId, String userId, {String role = 'worker'});

  bool unassign(String assignmentId);
}
