import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/api_authorization/data/mock_api_authorization_repository.dart';
import 'package:smart_livestock_demo/features/api_authorization/domain/api_authorization_repository.dart';

class LiveApiAuthorizationRepository implements ApiAuthorizationRepository {
  LiveApiAuthorizationRepository();

  static final MockApiAuthorizationRepository _fallback =
      MockApiAuthorizationRepository();

  @override
  ApiKeyListViewData getApiKeys({String? ownerId}) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.getApiKeys(ownerId: ownerId);
    }
    var all = List<Map<String, dynamic>>.from(cache.apiKeys);
    if (ownerId != null && ownerId.isNotEmpty) {
      all = all.where((k) => k['ownerId'] == ownerId).toList();
    }
    return ApiKeyListViewData(
      viewState: all.isEmpty ? ViewState.empty : ViewState.normal,
      apiKeys: all,
      total: all.length,
      message: all.isEmpty ? '暂无 API Key' : null,
    );
  }

  @override
  ApiAuthorizationListViewData getAuthorizations({String? status}) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.getAuthorizations(status: status);
    }
    var all =
        List<Map<String, dynamic>>.from(cache.apiAuthorizations);
    if (status != null && status.isNotEmpty) {
      all = all.where((a) => a['status'] == status).toList();
    }
    return ApiAuthorizationListViewData(
      viewState: all.isEmpty ? ViewState.empty : ViewState.normal,
      authorizations: all,
      total: all.length,
      message: all.isEmpty ? '暂无授权申请' : null,
    );
  }

  @override
  Future<bool> approveAuthorization(String id) async {
    return _fallback.approveAuthorization(id);
  }

  @override
  Future<bool> revokeAuthorization(String id) async {
    return _fallback.revokeAuthorization(id);
  }

  @override
  Future<bool> issueApiKey(Map<String, dynamic> data) async {
    return _fallback.issueApiKey(data);
  }

  @override
  Future<bool> revokeApiKey(String keyId) async {
    return _fallback.revokeApiKey(keyId);
  }
}
