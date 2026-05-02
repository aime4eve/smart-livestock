import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/api_authorization/domain/api_authorization_repository.dart';

class MockApiAuthorizationRepository implements ApiAuthorizationRepository {
  MockApiAuthorizationRepository();

  static final List<Map<String, dynamic>> _apiKeys = [
    {
      'id': 'key_001',
      'ownerId': 'tenant_001',
      'ownerName': '华东示范牧场',
      'keyName': '智能牧场数据平台',
      'keyPrefix': 'sm_api_',
      'status': 'active',
      'scope': 'read:livestock,read:devices',
      'rateLimit': 1000,
      'createdAt': '2025-09-15T10:00:00+08:00',
      'expiresAt': '2026-09-15T10:00:00+08:00',
    },
    {
      'id': 'key_002',
      'ownerId': 'tenant_003',
      'ownerName': '东北黑土地牧场',
      'keyName': '供应链集成 API',
      'keyPrefix': 'sc_api_',
      'status': 'active',
      'scope': 'read:livestock,read:health',
      'rateLimit': 2000,
      'createdAt': '2025-11-20T14:00:00+08:00',
      'expiresAt': '2026-11-20T14:00:00+08:00',
    },
    {
      'id': 'key_003',
      'ownerId': 'tenant_005',
      'ownerName': '西南高山牧场',
      'keyName': '科研分析 API',
      'keyPrefix': 'rd_api_',
      'status': 'pending',
      'scope': 'read:livestock,read:devices,read:health',
      'rateLimit': 500,
      'createdAt': '2026-01-10T09:00:00+08:00',
      'expiresAt': '2027-01-10T09:00:00+08:00',
    },
  ];

  static final List<Map<String, dynamic>> _authorizations = [
    {
      'id': 'auth_001',
      'keyId': 'key_003',
      'tenantName': '西南高山牧场',
      'requestedScope': 'read:livestock,read:devices,read:health',
      'status': 'pending',
      'requestedAt': '2026-01-10T09:00:00+08:00',
      'reviewedAt': null,
      'reviewedBy': null,
    },
  ];

  @override
  ApiKeyListViewData getApiKeys({String? ownerId}) {
    var filtered = List<Map<String, dynamic>>.from(_apiKeys);
    if (ownerId != null && ownerId.isNotEmpty) {
      filtered = filtered.where((k) => k['ownerId'] == ownerId).toList();
    }
    return ApiKeyListViewData(
      viewState: filtered.isEmpty ? ViewState.empty : ViewState.normal,
      apiKeys: filtered,
      total: filtered.length,
      message: filtered.isEmpty ? '暂无 API Key' : null,
    );
  }

  @override
  ApiAuthorizationListViewData getAuthorizations({String? status}) {
    var filtered = List<Map<String, dynamic>>.from(_authorizations);
    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((a) => a['status'] == status).toList();
    }
    return ApiAuthorizationListViewData(
      viewState: filtered.isEmpty ? ViewState.empty : ViewState.normal,
      authorizations: filtered,
      total: filtered.length,
      message: filtered.isEmpty ? '暂无授权申请' : null,
    );
  }

  @override
  Future<bool> approveAuthorization(String id) async {
    final authIdx = _authorizations.indexWhere((a) => a['id'] == id);
    if (authIdx == -1) return false;
    _authorizations[authIdx] = {
      ..._authorizations[authIdx],
      'status': 'approved',
      'reviewedAt': DateTime.now().toIso8601String(),
      'reviewedBy': '平台管理员',
    };
    final keyId = _authorizations[authIdx]['keyId'] as String;
    final keyIdx = _apiKeys.indexWhere((k) => k['id'] == keyId);
    if (keyIdx != -1) {
      _apiKeys[keyIdx] = {..._apiKeys[keyIdx], 'status': 'active'};
    }
    return true;
  }

  @override
  Future<bool> revokeAuthorization(String id) async {
    final authIdx = _authorizations.indexWhere((a) => a['id'] == id);
    if (authIdx == -1) return false;
    _authorizations[authIdx] = {
      ..._authorizations[authIdx],
      'status': 'revoked',
      'reviewedAt': DateTime.now().toIso8601String(),
      'reviewedBy': '平台管理员',
    };
    return true;
  }

  @override
  Future<bool> issueApiKey(Map<String, dynamic> data) async {
    final newKey = Map<String, dynamic>.from(data);
    newKey['id'] = 'key_${DateTime.now().millisecondsSinceEpoch}';
    _apiKeys.add(newKey);
    return true;
  }

  @override
  Future<bool> revokeApiKey(String keyId) async {
    final index = _apiKeys.indexWhere((k) => k['id'] == keyId);
    if (index == -1) return false;
    _apiKeys[index] = {..._apiKeys[index], 'status': 'revoked'};
    return true;
  }
}
