import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';

class MockB2bWorkerManagementRepository implements B2bWorkerManagementRepository {
  const MockB2bWorkerManagementRepository();

  static const List<B2bSubFarm> _subFarms = [
    B2bSubFarm(
      id: 'sf_001',
      name: '华东示范牧场 - 一分场',
      workerCount: 8,
      livestockCount: 200,
    ),
    B2bSubFarm(
      id: 'sf_002',
      name: '华东示范牧场 - 二分场',
      workerCount: 5,
      livestockCount: 150,
    ),
    B2bSubFarm(
      id: 'sf_003',
      name: '华东示范牧场 - 三分场',
      workerCount: 12,
      livestockCount: 300,
    ),
  ];

  static final Map<String, List<B2bSubFarmWorker>> _workers = {
    'sf_001': const [
      B2bSubFarmWorker(name: '张牧工', role: '牧工主管', status: 'active'),
      B2bSubFarmWorker(name: '李牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '王牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '赵牧工', role: '牧工', status: 'inactive'),
      B2bSubFarmWorker(name: '钱牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '孙牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '周牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '吴牧工', role: '牧工', status: 'inactive'),
    ],
    'sf_002': const [
      B2bSubFarmWorker(name: '陈牧工', role: '牧工主管', status: 'active'),
      B2bSubFarmWorker(name: '杨牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '刘牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '黄牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '吕牧工', role: '牧工', status: 'active'),
    ],
    'sf_003': const [
      B2bSubFarmWorker(name: '马牧工', role: '牧工主管', status: 'active'),
      B2bSubFarmWorker(name: '朱牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '胡牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '郭牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '何牧工', role: '牧工', status: 'inactive'),
      B2bSubFarmWorker(name: '高牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '林牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '罗牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '梁牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '宋牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '唐牧工', role: '牧工', status: 'active'),
      B2bSubFarmWorker(name: '许牧工', role: '牧工', status: 'active'),
    ],
  };

  @override
  B2bWorkerManagementViewData getSubFarms() {
    return B2bWorkerManagementViewData(
      viewState: _subFarms.isEmpty ? ViewState.empty : ViewState.normal,
      subFarms: _subFarms,
      message: _subFarms.isEmpty ? '暂无牧场' : null,
    );
  }

  @override
  List<B2bSubFarmWorker> getSubFarmWorkers(String farmId) {
    return _workers[farmId] ?? [];
  }
}
