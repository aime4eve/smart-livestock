import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/live_b2b_worker_management_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/mock_b2b_worker_management_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';

final b2bWorkerManagementRepositoryProvider =
    Provider<B2bWorkerManagementRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockB2bWorkerManagementRepository();
    case AppMode.live:
      return const LiveB2bWorkerManagementRepository();
  }
});

class B2bWorkerManagementController
    extends Notifier<B2bWorkerManagementViewData> {
  @override
  B2bWorkerManagementViewData build() {
    return ref.read(b2bWorkerManagementRepositoryProvider).getSubFarms();
  }

  B2bWorkerManagementRepository get _repo =>
      ref.read(b2bWorkerManagementRepositoryProvider);

  void refresh() {
    state = _repo.getSubFarms();
  }

  List<B2bSubFarmWorker> getSubFarmWorkers(String farmId) {
    return _repo.getSubFarmWorkers(farmId);
  }
}

final b2bWorkerManagementControllerProvider =
    NotifierProvider<B2bWorkerManagementController,
        B2bWorkerManagementViewData>(
  B2bWorkerManagementController.new,
);
