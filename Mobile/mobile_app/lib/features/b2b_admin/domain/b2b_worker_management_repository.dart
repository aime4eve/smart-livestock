import 'package:smart_livestock_demo/core/models/view_state.dart';

class B2bSubFarm {
  const B2bSubFarm({
    required this.id,
    required this.name,
    required this.workerCount,
    required this.livestockCount,
  });

  final String id;
  final String name;
  final int workerCount;
  final int livestockCount;
}

class B2bSubFarmWorker {
  const B2bSubFarmWorker({
    required this.name,
    required this.role,
    required this.status,
  });

  final String name;
  final String role;
  final String status;
}

class B2bWorkerManagementViewData {
  const B2bWorkerManagementViewData({
    this.viewState = ViewState.normal,
    this.subFarms = const [],
    this.message,
  });

  final ViewState viewState;
  final List<B2bSubFarm> subFarms;
  final String? message;
}

abstract class B2bWorkerManagementRepository {
  B2bWorkerManagementViewData getSubFarms();
  List<B2bSubFarmWorker> getSubFarmWorkers(String farmId);
}
