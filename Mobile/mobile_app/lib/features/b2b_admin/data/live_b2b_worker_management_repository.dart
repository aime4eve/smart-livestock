import 'package:smart_livestock_demo/features/b2b_admin/data/mock_b2b_worker_management_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';

class LiveB2bWorkerManagementRepository
    implements B2bWorkerManagementRepository {
  LiveB2bWorkerManagementRepository();

  static final MockB2bWorkerManagementRepository _fallback =
      MockB2bWorkerManagementRepository();

  @override
  B2bWorkerManagementViewData getSubFarms() => _fallback.getSubFarms();

  @override
  List<B2bSubFarmWorker> getSubFarmWorkers(String farmId) =>
      _fallback.getSubFarmWorkers(farmId);

  @override
  Future<bool> assignWorker(String farmId, String workerId) =>
      _fallback.assignWorker(farmId, workerId);

  @override
  Future<bool> removeWorker(String farmId, String workerId) =>
      _fallback.removeWorker(farmId, workerId);

  @override
  List<B2bSubFarmWorker> getAvailableWorkers() =>
      _fallback.getAvailableWorkers();
}
