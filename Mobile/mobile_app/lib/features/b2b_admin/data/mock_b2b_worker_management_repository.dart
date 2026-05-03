import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';

class MockB2bWorkerManagementRepository implements B2bWorkerManagementRepository {
  MockB2bWorkerManagementRepository();

  static const List<B2bSubFarm> _subFarms = [
    B2bSubFarm(
      id: 'sf_001',
      name: '华东示范牧场 - 一分场',
      workerCount: 8,
      livestockCount: 200,
      deviceCount: 15,
    ),
    B2bSubFarm(
      id: 'sf_002',
      name: '华东示范牧场 - 二分场',
      workerCount: 5,
      livestockCount: 150,
      deviceCount: 10,
    ),
    B2bSubFarm(
      id: 'sf_003',
      name: '华东示范牧场 - 三分场',
      workerCount: 12,
      livestockCount: 300,
      deviceCount: 22,
    ),
  ];

  /// Pool of all workers that can be assigned to farms.
  static final List<B2bSubFarmWorker> _allWorkers = [
    const B2bSubFarmWorker(
      id: 'worker_001',
      name: '张牧工',
      role: '牧工主管',
      status: 'active',
      assignedAt: '2025-09-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_002',
      name: '李牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-09-15',
    ),
    const B2bSubFarmWorker(
      id: 'worker_003',
      name: '王牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-10-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_004',
      name: '赵牧工',
      role: '牧工',
      status: 'inactive',
      assignedAt: '2025-10-10',
    ),
    const B2bSubFarmWorker(
      id: 'worker_005',
      name: '钱牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-10-20',
    ),
    const B2bSubFarmWorker(
      id: 'worker_006',
      name: '孙牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-11-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_007',
      name: '周牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-11-05',
    ),
    const B2bSubFarmWorker(
      id: 'worker_008',
      name: '吴牧工',
      role: '牧工',
      status: 'inactive',
      assignedAt: '2025-11-10',
    ),
    const B2bSubFarmWorker(
      id: 'worker_009',
      name: '陈牧工',
      role: '牧工主管',
      status: 'active',
      assignedAt: '2025-08-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_010',
      name: '杨牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-09-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_011',
      name: '刘牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-09-15',
    ),
    const B2bSubFarmWorker(
      id: 'worker_012',
      name: '黄牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-10-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_013',
      name: '吕牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-10-10',
    ),
    const B2bSubFarmWorker(
      id: 'worker_014',
      name: '马牧工',
      role: '牧工主管',
      status: 'active',
      assignedAt: '2025-07-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_015',
      name: '朱牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-08-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_016',
      name: '胡牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-08-15',
    ),
    const B2bSubFarmWorker(
      id: 'worker_017',
      name: '郭牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-09-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_018',
      name: '何牧工',
      role: '牧工',
      status: 'inactive',
      assignedAt: '2025-09-15',
    ),
    const B2bSubFarmWorker(
      id: 'worker_019',
      name: '高牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-10-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_020',
      name: '林牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-10-15',
    ),
    const B2bSubFarmWorker(
      id: 'worker_021',
      name: '罗牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-11-01',
    ),
    const B2bSubFarmWorker(
      id: 'worker_022',
      name: '梁牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-11-05',
    ),
    const B2bSubFarmWorker(
      id: 'worker_023',
      name: '宋牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-11-10',
    ),
    const B2bSubFarmWorker(
      id: 'worker_024',
      name: '唐牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-11-15',
    ),
    const B2bSubFarmWorker(
      id: 'worker_025',
      name: '许牧工',
      role: '牧工',
      status: 'active',
      assignedAt: '2025-11-20',
    ),
    // Unassigned workers (available pool)
    const B2bSubFarmWorker(
      id: 'worker_026',
      name: '郑牧工',
      role: '牧工',
      status: 'active',
    ),
    const B2bSubFarmWorker(
      id: 'worker_027',
      name: '韩牧工',
      role: '牧工',
      status: 'active',
    ),
    const B2bSubFarmWorker(
      id: 'worker_028',
      name: '冯牧工',
      role: '牧工',
      status: 'active',
    ),
  ];

  /// Mutable assignment map: farmId -> list of worker IDs.
  final Map<String, List<String>> _assignments = {
    'sf_001': [
      'worker_001',
      'worker_002',
      'worker_003',
      'worker_004',
      'worker_005',
      'worker_006',
      'worker_007',
      'worker_008',
    ],
    'sf_002': [
      'worker_009',
      'worker_010',
      'worker_011',
      'worker_012',
      'worker_013',
    ],
    'sf_003': [
      'worker_014',
      'worker_015',
      'worker_016',
      'worker_017',
      'worker_018',
      'worker_019',
      'worker_020',
      'worker_021',
      'worker_022',
      'worker_023',
      'worker_024',
      'worker_025',
    ],
  };

  B2bSubFarmWorker? _findWorkerById(String id) {
    for (final w in _allWorkers) {
      if (w.id == id) return w;
    }
    return null;
  }

  Set<String> get _assignedWorkerIds {
    final ids = <String>{};
    for (final list in _assignments.values) {
      ids.addAll(list);
    }
    return ids;
  }

  @override
  B2bWorkerManagementViewData getSubFarms() {
    final allAssigned = _assignedWorkerIds;
    final totalWorkers = allAssigned.length;
    var offlineCount = 0;
    for (final workerId in allAssigned) {
      final w = _findWorkerById(workerId);
      if (w != null && w.status == 'inactive') offlineCount++;
    }

    final farmsWithLiveCounts = _subFarms.map((f) {
      final liveCount = _assignments[f.id]?.length ?? f.workerCount;
      return B2bSubFarm(
        id: f.id,
        name: f.name,
        workerCount: liveCount,
        livestockCount: f.livestockCount,
        deviceCount: f.deviceCount,
      );
    }).toList();

    return B2bWorkerManagementViewData(
      viewState: _subFarms.isEmpty ? ViewState.empty : ViewState.normal,
      subFarms: farmsWithLiveCounts,
      totalWorkers: totalWorkers,
      offlineWorkerCount: offlineCount,
      message: _subFarms.isEmpty ? '暂无牧场' : null,
    );
  }

  @override
  List<B2bSubFarmWorker> getSubFarmWorkers(String farmId) {
    final ids = _assignments[farmId];
    if (ids == null) return [];
    return ids
        .map(_findWorkerById)
        .whereType<B2bSubFarmWorker>()
        .toList();
  }

  @override
  Future<bool> assignWorker(String farmId, String workerId) async {
    if (!_assignments.containsKey(farmId)) return false;
    if (_assignedWorkerIds.contains(workerId)) return false;
    _assignments[farmId]!.add(workerId);
    return true;
  }

  @override
  Future<bool> removeWorker(String farmId, String workerId) async {
    final list = _assignments[farmId];
    if (list == null) return false;
    return list.remove(workerId);
  }

  @override
  List<B2bSubFarmWorker> getAvailableWorkers() {
    final assigned = _assignedWorkerIds;
    return _allWorkers.where((w) => !assigned.contains(w.id)).toList();
  }
}
