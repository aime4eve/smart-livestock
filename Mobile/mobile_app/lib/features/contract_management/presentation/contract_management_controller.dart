import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/contract_management/data/contract_api_repository.dart';
import 'package:hkt_livestock_agentic/features/contract_management/domain/contract_management_repository.dart';

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

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(contractManagementRepositoryProvider).getContracts());
  }

  Future<ContractSummary> getContractDetail(String id) {
    return ref.read(contractManagementRepositoryProvider).getContractDetail(id);
  }

  Future<bool> createContract(Map<String, dynamic> data) async {
    await ref
        .read(contractManagementRepositoryProvider)
        .createContract(data);
    await refresh();
    return true;
  }

  Future<bool> updateDraft(String id, Map<String, dynamic> data) async {
    await ref
        .read(contractManagementRepositoryProvider)
        .updateDraft(id, data);
    await refresh();
    return true;
  }

  Future<bool> signContract(String id) async {
    await ref.read(contractManagementRepositoryProvider).signContract(id);
    await refresh();
    return true;
  }

  Future<bool> updateContractStatus(String id, String targetStatus) async {
    final ok = await ref
        .read(contractManagementRepositoryProvider)
        .updateContractStatus(id, targetStatus);
    if (ok) await refresh();
    return ok;
  }
}

final contractManagementControllerProvider =
    AsyncNotifierProvider<ContractManagementController, ContractListViewData>(
  ContractManagementController.new,
);
