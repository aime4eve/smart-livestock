import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/contract_management/data/mock_contract_management_repository.dart';
import 'package:smart_livestock_demo/features/contract_management/domain/contract_management_repository.dart';

class LiveContractManagementRepository implements ContractManagementRepository {
  LiveContractManagementRepository();

  static final MockContractManagementRepository _fallback =
      MockContractManagementRepository();

  @override
  ContractListViewData getContracts({String? partnerId, String? status}) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.getContracts(partnerId: partnerId, status: status);
    }
    var all = List<Map<String, dynamic>>.from(cache.contracts);
    if (partnerId != null && partnerId.isNotEmpty) {
      all = all.where((c) => c['partnerId'] == partnerId).toList();
    }
    if (status != null && status.isNotEmpty) {
      all = all.where((c) => c['status'] == status).toList();
    }
    return ContractListViewData(
      viewState: all.isEmpty ? ViewState.empty : ViewState.normal,
      contracts: all,
      total: all.length,
      message: all.isEmpty ? '暂无合同' : null,
    );
  }

  @override
  Future<bool> createContract(Map<String, dynamic> data) async {
    return _fallback.createContract(data);
  }

  @override
  Future<bool> updateContract(String id, Map<String, dynamic> data) async {
    return _fallback.updateContract(id, data);
  }

  @override
  Future<bool> terminateContract(String id) async {
    return _fallback.terminateContract(id);
  }
}
