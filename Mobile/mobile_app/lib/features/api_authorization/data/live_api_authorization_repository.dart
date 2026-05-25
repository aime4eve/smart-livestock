import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/api_authorization/domain/api_authorization_repository.dart';

class LiveApiAuthorizationRepository implements ApiAuthorizationRepository {
  LiveApiAuthorizationRepository();

  @override
  ApiKeyListViewData getApiKeys({String? ownerId}) {
    return const ApiKeyListViewData(
      viewState: ViewState.empty,
      apiKeys: [],
      total: 0,
      message: '暂无 API Key',
    );
  }

  @override
  ApiAuthorizationListViewData getAuthorizations({String? status}) {
    return const ApiAuthorizationListViewData(
      viewState: ViewState.empty,
      authorizations: [],
      total: 0,
      message: '暂无授权申请',
    );
  }

  @override
  Future<bool> approveAuthorization(String id) async {
    return false;
  }

  @override
  Future<bool> revokeAuthorization(String id) async {
    return false;
  }

  @override
  Future<bool> issueApiKey(Map<String, dynamic> data) async {
    return false;
  }

  @override
  Future<bool> revokeApiKey(String keyId) async {
    return false;
  }
}
