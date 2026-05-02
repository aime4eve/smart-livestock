import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/contract_management/domain/contract_management_repository.dart';

class MockContractManagementRepository implements ContractManagementRepository {
  MockContractManagementRepository();

  static final List<Map<String, dynamic>> _contracts = [
    {
      'id': 'ctr_001',
      'partnerId': 'partner_001',
      'partnerName': '华东示范牧场',
      'status': 'active',
      'tier': 'pro',
      'revenueShare': 30.0,
      'startDate': '2025-06-01',
      'endDate': '2026-06-01',
      'signedAt': '2025-05-20T10:00:00+08:00',
      'terminatedAt': null,
    },
    {
      'id': 'ctr_002',
      'partnerId': 'partner_002',
      'partnerName': '西部高原牧场',
      'status': 'active',
      'tier': 'enterprise',
      'revenueShare': 35.0,
      'startDate': '2025-08-15',
      'endDate': '2026-08-15',
      'signedAt': '2025-08-01T09:30:00+08:00',
      'terminatedAt': null,
    },
    {
      'id': 'ctr_003',
      'partnerId': 'partner_003',
      'partnerName': '东北黑土地牧场',
      'status': 'active',
      'tier': 'basic',
      'revenueShare': 20.0,
      'startDate': '2025-12-01',
      'endDate': '2026-12-01',
      'signedAt': '2025-11-15T14:00:00+08:00',
      'terminatedAt': null,
    },
    {
      'id': 'ctr_004',
      'partnerId': 'partner_004',
      'partnerName': '华北草原牧场',
      'status': 'pending',
      'tier': 'pro',
      'revenueShare': 25.0,
      'startDate': null,
      'endDate': null,
      'signedAt': null,
      'terminatedAt': null,
    },
    {
      'id': 'ctr_005',
      'partnerId': 'partner_005',
      'partnerName': '华南热带牧场',
      'status': 'terminated',
      'tier': 'trial',
      'revenueShare': 15.0,
      'startDate': '2025-04-01',
      'endDate': '2025-10-01',
      'signedAt': '2025-03-20T11:00:00+08:00',
      'terminatedAt': '2025-10-01T00:00:00+08:00',
    },
  ];

  @override
  ContractListViewData getContracts({String? partnerId, String? status}) {
    var filtered = List<Map<String, dynamic>>.from(_contracts);
    if (partnerId != null && partnerId.isNotEmpty) {
      filtered = filtered.where((c) => c['partnerId'] == partnerId).toList();
    }
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((c) => c['status'] == status).toList();
    }
    return ContractListViewData(
      viewState: filtered.isEmpty ? ViewState.empty : ViewState.normal,
      contracts: filtered,
      total: filtered.length,
      message: filtered.isEmpty ? '暂无合同' : null,
    );
  }

  @override
  Future<bool> createContract(Map<String, dynamic> data) async {
    final newContract = Map<String, dynamic>.from(data);
    newContract['id'] = 'ctr_${DateTime.now().millisecondsSinceEpoch}';
    _contracts.add(newContract);
    return true;
  }

  @override
  Future<bool> updateContract(String id, Map<String, dynamic> data) async {
    final index = _contracts.indexWhere((c) => c['id'] == id);
    if (index == -1) return false;
    _contracts[index] = {..._contracts[index], ...data};
    return true;
  }

  @override
  Future<bool> terminateContract(String id) async {
    final index = _contracts.indexWhere((c) => c['id'] == id);
    if (index == -1) return false;
    _contracts[index] = {
      ..._contracts[index],
      'status': 'terminated',
      'terminatedAt': DateTime.now().toIso8601String(),
    };
    return true;
  }
}
