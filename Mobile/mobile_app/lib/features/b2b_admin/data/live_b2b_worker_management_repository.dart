import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/mock_b2b_worker_management_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';

class LiveB2bWorkerManagementRepository
    implements B2bWorkerManagementRepository {
  const LiveB2bWorkerManagementRepository();

  static const MockB2bWorkerManagementRepository _fallback =
      MockB2bWorkerManagementRepository();

  @override
  B2bWorkerManagementViewData getSubFarms() {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.getSubFarms();
    }
    return _fallback.getSubFarms();
  }

  @override
  List<B2bSubFarmWorker> getSubFarmWorkers(String farmId) {
    return _fallback.getSubFarmWorkers(farmId);
  }
}
