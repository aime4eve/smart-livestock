import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/b2b_repository.dart';

final b2bRepositoryProvider =
    Provider<B2bRepository>((_) => B2bRepository());

class B2bDashboardController extends Notifier<B2bDashboardData> {
  @override
  B2bDashboardData build() {
    final appMode = ref.watch(appModeProvider);
    final repo = ref.read(b2bRepositoryProvider);
    return repo.loadDashboard(ViewState.normal, appMode);
  }

  Future<bool> createFarm(
    String name, {
    String? ownerName,
    String? contactPhone,
    String? region,
  }) async {
    final appMode = ref.read(appModeProvider);
    final repo = ref.read(b2bRepositoryProvider);
    final ok = await repo.createFarm(
      name,
      ownerName: ownerName,
      contactPhone: contactPhone,
      region: region,
      appMode: appMode,
    );
    if (ok) {
      ref.invalidateSelf();
    }
    return ok;
  }
}

final b2bDashboardControllerProvider =
    NotifierProvider<B2bDashboardController, B2bDashboardData>(
  B2bDashboardController.new,
);

class B2bContractController extends Notifier<B2bContractData> {
  @override
  B2bContractData build() {
    final appMode = ref.watch(appModeProvider);
    final repo = ref.read(b2bRepositoryProvider);
    return repo.loadContract(ViewState.normal, appMode);
  }
}

final b2bContractControllerProvider =
    NotifierProvider<B2bContractController, B2bContractData>(
  B2bContractController.new,
);
