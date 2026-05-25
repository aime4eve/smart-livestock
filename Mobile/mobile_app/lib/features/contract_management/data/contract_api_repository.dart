import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/contract_management/domain/contract_management_repository.dart';

class ContractApiRepository implements ContractManagementRepository {
  const ContractApiRepository();

  @override
  Future<ContractListViewData> getContracts({
    String? partnerId,
    String? status,
  }) async {
    var path = '/admin/contracts';
    final query = <String, String>{};
    if (partnerId != null) query['partnerId'] = partnerId;
    if (status != null) query['status'] = status;
    if (query.isNotEmpty) {
      path += '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    final data = await ApiClient.instance.get(path);
    final items = data['items'] as List? ?? [];
    final contracts = items.whereType<Map<String, dynamic>>().toList();
    return ContractListViewData(
      contracts: contracts,
      total: data['total'] as int? ?? contracts.length,
    );
  }

  @override
  Future<bool> createContract(Map<String, dynamic> data) async {
    await ApiClient.instance.post('/admin/contracts', body: data);
    return true;
  }

  @override
  Future<bool> updateContract(String id, Map<String, dynamic> data) async {
    await ApiClient.instance.put('/admin/contracts/$id', body: data);
    return true;
  }

  @override
  Future<bool> terminateContract(String id) async {
    await ApiClient.instance.put('/admin/contracts/$id', body: {'status': 'terminated'});
    return true;
  }
}
