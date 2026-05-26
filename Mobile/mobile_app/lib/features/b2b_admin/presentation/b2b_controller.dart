import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/b2b_api_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_repository.dart';

final b2bRepositoryProvider =
    Provider<B2bRepository>((_) => const B2bApiRepository());

class B2bDashboardController extends AsyncNotifier<B2bDashboardData> {
  @override
  Future<B2bDashboardData> build() async {
    return ref.read(b2bRepositoryProvider).loadDashboard();
  }

  Future<bool> createFarm(Map<String, dynamic> body) async {
    final ok = await ref.read(b2bRepositoryProvider).createFarm(body);
    if (ok) {
      ref.invalidateSelf();
    }
    return ok;
  }

  Future<bool> changeOwner(String farmId, int ownerId) async {
    final ok = await ref.read(b2bRepositoryProvider).changeOwner(farmId, ownerId);
    if (ok) {
      ref.invalidateSelf();
    }
    return ok;
  }
}

final b2bDashboardControllerProvider =
    AsyncNotifierProvider<B2bDashboardController, B2bDashboardData>(
  B2bDashboardController.new,
);

final b2bOwnerUsersProvider =
    FutureProvider<List<B2bUserSummary>>((ref) async {
  return ref.read(b2bRepositoryProvider).loadUsers(role: 'OWNER');
});

class B2bContractController extends AsyncNotifier<B2bContractData> {
  @override
  Future<B2bContractData> build() async {
    return ref.read(b2bRepositoryProvider).loadContract();
  }
}

final b2bContractControllerProvider =
    AsyncNotifierProvider<B2bContractController, B2bContractData>(
  B2bContractController.new,
);
