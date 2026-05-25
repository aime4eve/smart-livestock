abstract class ContractManagementRepository {
  Future<ContractListViewData> getContracts({String? partnerId, String? status});
  Future<bool> createContract(Map<String, dynamic> data);
  Future<bool> updateContract(String id, Map<String, dynamic> data);
  Future<bool> terminateContract(String id);
}

class ContractListViewData {
  const ContractListViewData({
    this.contracts = const [],
    this.total = 0,
    this.message,
  });

  final List<Map<String, dynamic>> contracts;
  final int total;
  final String? message;

  bool get isEmpty => contracts.isEmpty;
}
