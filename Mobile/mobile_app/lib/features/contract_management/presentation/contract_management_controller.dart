import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/contract_management/data/contract_api_repository.dart';
import 'package:smart_livestock_demo/features/contract_management/domain/contract_management_repository.dart';

final contractManagementRepositoryProvider =
    Provider<ContractManagementRepository>((ref) {
  return const ContractApiRepository();
});

class ContractManagementController
    extends AsyncNotifier<ContractListViewData> {
  @override
  Future<ContractListViewData> build() async {
    return ref.read(contractManagementRepositoryProvider).getContracts();
  }

  Future<void> filter({String? partnerId, String? status}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(contractManagementRepositoryProvider).getContracts(
              partnerId: partnerId,
              status: status,
            ));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(contractManagementRepositoryProvider).getContracts());
  }

  Future<bool> createContract(Map<String, dynamic> data) async {
    final ok = await ref.read(contractManagementRepositoryProvider).createContract(data);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> updateContract(String id, Map<String, dynamic> data) async {
    final ok = await ref.read(contractManagementRepositoryProvider).updateContract(id, data);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> terminateContract(String id) async {
    final ok = await ref.read(contractManagementRepositoryProvider).terminateContract(id);
    if (ok) await refresh();
    return ok;
  }
}

final contractManagementControllerProvider =
    AsyncNotifierProvider<ContractManagementController, ContractListViewData>(
  ContractManagementController.new,
);
