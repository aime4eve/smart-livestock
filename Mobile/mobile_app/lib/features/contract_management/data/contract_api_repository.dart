import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/contract_management/domain/contract_management_repository.dart';

class ContractApiRepository implements ContractManagementRepository {
  const ContractApiRepository();

  @override
  Future<ContractListViewData> getContracts() async {
    final data = await ApiClient.instance.get('/admin/contracts');
    final items = data['items'] as List<dynamic>? ??
        data['value'] as List<dynamic>? ??
        [];
    final contracts = items
        .whereType<Map<String, dynamic>>()
        .map((m) => ContractSummary.fromJson(m))
        .toList();
    return ContractListViewData(
      contracts: contracts,
      total: data['total'] as int? ?? contracts.length,
    );
  }

  @override
  Future<ContractSummary> getContractDetail(String id) async {
    final data = await ApiClient.instance.get('/admin/contracts/$id');
    return ContractSummary.fromJson(data);
  }

  @override
  Future<ContractSummary> createContract(Map<String, dynamic> body) async {
    final data =
        await ApiClient.instance.post('/admin/contracts', body: body);
    return ContractSummary.fromJson(data);
  }

  @override
  Future<ContractSummary> updateDraft(
      String id, Map<String, dynamic> body) async {
    final data =
        await ApiClient.instance.put('/admin/contracts/$id', body: body);
    return ContractSummary.fromJson(data);
  }

  @override
  Future<ContractSummary> signContract(String id) async {
    final data =
        await ApiClient.instance.post('/admin/contracts/$id/sign');
    return ContractSummary.fromJson(data);
  }

  @override
  Future<bool> updateContractStatus(String id, String targetStatus) async {
    await ApiClient.instance.put('/admin/contracts/$id/status',
        body: {'targetStatus': targetStatus.toUpperCase()});
    return true;
  }
}
