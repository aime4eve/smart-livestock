import 'package:smart_livestock_demo/core/models/view_state.dart';

class ContractListViewData {
  const ContractListViewData({
    this.viewState = ViewState.normal,
    this.contracts = const [],
    this.total = 0,
    this.message,
  });

  final ViewState viewState;
  final List<Map<String, dynamic>> contracts;
  final int total;
  final String? message;
}

class ContractDetailViewData {
  const ContractDetailViewData({
    this.viewState = ViewState.normal,
    this.contract,
    this.message,
  });

  final ViewState viewState;
  final Map<String, dynamic>? contract;
  final String? message;
}

abstract class ContractManagementRepository {
  ContractListViewData getContracts({String? partnerId, String? status});
  Future<bool> createContract(Map<String, dynamic> data);
  Future<bool> updateContract(String id, Map<String, dynamic> data);
  Future<bool> terminateContract(String id);
}
