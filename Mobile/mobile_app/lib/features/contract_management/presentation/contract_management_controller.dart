import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/contract_management/data/live_contract_management_repository.dart';
import 'package:smart_livestock_demo/features/contract_management/data/mock_contract_management_repository.dart';
import 'package:smart_livestock_demo/features/contract_management/domain/contract_management_repository.dart';

final contractManagementRepositoryProvider =
    Provider<ContractManagementRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return MockContractManagementRepository();
    case AppMode.live:
      return LiveContractManagementRepository();
  }
});

class ContractManagementController
    extends Notifier<ContractListViewData> {
  @override
  ContractListViewData build() {
    return ref
        .read(contractManagementRepositoryProvider)
        .getContracts();
  }

  ContractManagementRepository get _repo =>
      ref.read(contractManagementRepositoryProvider);

  void filter({String? partnerId, String? status}) {
    state = _repo.getContracts(partnerId: partnerId, status: status);
  }

  void refresh() {
    state = _repo.getContracts();
  }

  Future<bool> createContract(Map<String, dynamic> data) async {
    final ok = await _repo.createContract(data);
    if (ok) refresh();
    return ok;
  }

  Future<bool> updateContract(String id, Map<String, dynamic> data) async {
    final ok = await _repo.updateContract(id, data);
    if (ok) refresh();
    return ok;
  }

  Future<bool> terminateContract(String id) async {
    final ok = await _repo.terminateContract(id);
    if (ok) refresh();
    return ok;
  }
}

final contractManagementControllerProvider =
    NotifierProvider<ContractManagementController, ContractListViewData>(
  ContractManagementController.new,
);
