class B2bSubFarm {
  const B2bSubFarm({
    required this.id,
    required this.name,
    required this.workerCount,
    required this.livestockCount,
    this.deviceCount = 0,
    this.latitude,
    this.longitude,
    this.areaHectares,
  });

  final String id;
  final String name;
  final int workerCount;
  final int livestockCount;
  final int deviceCount;
  final double? latitude;
  final double? longitude;
  final double? areaHectares;
}

class B2bSubFarmWorker {
  const B2bSubFarmWorker({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.phone,
    this.assignedAt,
  });

  final String id;
  final String name;
  final String role;
  final String status;
  final String? phone;
  final String? assignedAt;
}

class B2bWorkerManagementViewData {
  const B2bWorkerManagementViewData({
    this.subFarms = const [],
    this.totalWorkers = 0,
    this.offlineWorkerCount = 0,
    this.message,
  });

  final List<B2bSubFarm> subFarms;
  final int totalWorkers;
  final int offlineWorkerCount;
  final String? message;
}

abstract class B2bWorkerManagementRepository {
  Future<B2bWorkerManagementViewData> getSubFarms();
  Future<List<B2bSubFarmWorker>> getSubFarmWorkers(String farmId);
  Future<bool> assignWorker(String farmId, String workerId);
  Future<bool> removeWorker(String farmId, String workerId);
  Future<List<B2bSubFarmWorker>> getAvailableWorkers();
  Future<B2bSubFarmWorker> createWorker({required String name, required String phone, required String password});
  Future<B2bSubFarmWorker> updateWorker(String userId, {String? name, String? phone});
  Future<bool> updateWorkerStatus(String userId, String status);
  Future<bool> resetWorkerPassword(String userId, String newPassword);
}
