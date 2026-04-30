import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/worker_management/data/mock_worker_repository.dart';
import 'package:smart_livestock_demo/features/worker_management/domain/worker_repository.dart';

class LiveWorkerRepository implements WorkerRepository {
  const LiveWorkerRepository();

  static const MockWorkerRepository _fallback = MockWorkerRepository();

  @override
  WorkersViewData load({
    required ViewState viewState,
    required String farmId,
  }) {
    final cache = ApiCache.instance;
    final data = cache.workers;
    final rawItems = data?['items'];
    if (!cache.initialized ||
        cache.lastLiveSource != 'api' ||
        cache.workersFarmId != farmId ||
        rawItems is! List) {
      return _fallback.load(viewState: viewState, farmId: farmId);
    }

    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(_parseAssignment)
        .whereType<WorkerAssignment>()
        .toList();

    return WorkersViewData(
      viewState: viewState,
      items: viewState == ViewState.normal ? items : const [],
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无牧工',
        ViewState.error => '加载失败',
        ViewState.forbidden => '无权限管理牧工',
        ViewState.offline => '离线数据',
        ViewState.normal => null,
      },
    );
  }

  WorkerAssignment? _parseAssignment(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['userId'];
    if (id is! String || id.isEmpty || userId is! String || userId.isEmpty) {
      return null;
    }
    final userName = json['userName'];
    final role = json['role'];
    final assignedAt = json['assignedAt'];
    return WorkerAssignment(
      id: id,
      userId: userId,
      userName: userName is String ? userName : userId,
      role: role is String ? role : 'worker',
      assignedAt: assignedAt is String ? assignedAt : '',
    );
  }

  @override
  bool assign(String farmId, String userId, {String role = 'worker'}) {
    final now = DateTime.now();
    return ApiCache.instance.addWorkerAssignment(
      farmId: farmId,
      id: 'wfa_live_${now.microsecondsSinceEpoch}',
      userId: userId,
      userName: userId,
      role: role,
      assignedAt: now.toIso8601String(),
    );
  }

  @override
  bool unassign(String assignmentId) {
    return ApiCache.instance.removeWorkerAssignment(assignmentId);
  }
}
