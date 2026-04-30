import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/worker_management/data/live_worker_repository.dart';
import 'package:smart_livestock_demo/features/worker_management/data/mock_worker_repository.dart';
import 'package:smart_livestock_demo/features/worker_management/domain/worker_repository.dart';

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return const MockWorkerRepository();
    case AppMode.live:
      return const LiveWorkerRepository();
  }
});

class WorkerController extends Notifier<WorkersViewData> {
  @override
  WorkersViewData build() {
    return const WorkersViewData(viewState: ViewState.normal);
  }

  void loadWorkers(String farmId) {
    state = ref.read(workerRepositoryProvider).load(
          viewState: ViewState.normal,
          farmId: farmId,
        );
  }

  bool assignWorker(String farmId, String userId) {
    final assigned = ref.read(workerRepositoryProvider).assign(farmId, userId);
    if (assigned) loadWorkers(farmId);
    return assigned;
  }

  bool removeWorker(String assignmentId, String farmId) {
    final removed = ref.read(workerRepositoryProvider).unassign(assignmentId);
    if (removed) loadWorkers(farmId);
    return removed;
  }

  void setViewState(ViewState viewState, String farmId) {
    state = ref.read(workerRepositoryProvider).load(
          viewState: viewState,
          farmId: farmId,
        );
  }
}

final workerControllerProvider =
    NotifierProvider<WorkerController, WorkersViewData>(
  WorkerController.new,
);
