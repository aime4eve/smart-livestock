import 'package:smart_livestock_demo/core/models/view_state.dart';

class B2bSubFarm {
  const B2bSubFarm({
    required this.id,
    required this.name,
    required this.workerCount,
    required this.livestockCount,
    this.deviceCount = 0,
  });

  final String id;
  final String name;
  final int workerCount;
  final int livestockCount;
  final int deviceCount;
}

class B2bSubFarmWorker {
  const B2bSubFarmWorker({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.assignedAt,
  });

  final String id;
  final String name;
  final String role;
  final String status;
  final String? assignedAt;
}

class B2bWorkerManagementViewData {
  const B2bWorkerManagementViewData({
    this.viewState = ViewState.normal,
    this.subFarms = const [],
    this.totalWorkers = 0,
    this.offlineWorkerCount = 0,
    this.message,
  });

  final ViewState viewState;
  final List<B2bSubFarm> subFarms;
  final int totalWorkers;
  final int offlineWorkerCount;
  final String? message;
}

abstract class B2bWorkerManagementRepository {
  B2bWorkerManagementViewData getSubFarms();
  List<B2bSubFarmWorker> getSubFarmWorkers(String farmId);
  Future<bool> assignWorker(String farmId, String workerId);
  Future<bool> removeWorker(String farmId, String workerId);
  List<B2bSubFarmWorker> getAvailableWorkers();
}
