import 'package:smart_livestock_demo/core/models/view_state.dart';

class ApiKeyListViewData {
  const ApiKeyListViewData({
    this.viewState = ViewState.normal,
    this.apiKeys = const [],
    this.total = 0,
    this.message,
  });

  final ViewState viewState;
  final List<Map<String, dynamic>> apiKeys;
  final int total;
  final String? message;
}

class ApiAuthorizationListViewData {
  const ApiAuthorizationListViewData({
    this.viewState = ViewState.normal,
    this.authorizations = const [],
    this.total = 0,
    this.message,
  });

  final ViewState viewState;
  final List<Map<String, dynamic>> authorizations;
  final int total;
  final String? message;
}

abstract class ApiAuthorizationRepository {
  ApiKeyListViewData getApiKeys({String? ownerId});
  ApiAuthorizationListViewData getAuthorizations({String? status});
  Future<bool> approveAuthorization(String id);
  Future<bool> revokeAuthorization(String id);
  Future<bool> issueApiKey(Map<String, dynamic> data);
  Future<bool> revokeApiKey(String keyId);
}
