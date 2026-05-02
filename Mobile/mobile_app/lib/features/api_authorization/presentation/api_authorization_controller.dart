import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/api_authorization/data/live_api_authorization_repository.dart';
import 'package:smart_livestock_demo/features/api_authorization/data/mock_api_authorization_repository.dart';
import 'package:smart_livestock_demo/features/api_authorization/domain/api_authorization_repository.dart';

final apiAuthorizationRepositoryProvider =
    Provider<ApiAuthorizationRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return MockApiAuthorizationRepository();
    case AppMode.live:
      return LiveApiAuthorizationRepository();
  }
});

class ApiAuthorizationController
    extends Notifier<ApiAuthorizationListViewData> {
  @override
  ApiAuthorizationListViewData build() {
    return ref.read(apiAuthorizationRepositoryProvider).getAuthorizations();
  }

  ApiAuthorizationRepository get _repo =>
      ref.read(apiAuthorizationRepositoryProvider);

  void filterByStatus(String? status) {
    state = _repo.getAuthorizations(status: status);
  }

  void refresh() {
    state = _repo.getAuthorizations();
  }

  Future<bool> approveAuthorization(String id) async {
    final ok = await _repo.approveAuthorization(id);
    if (ok) refresh();
    return ok;
  }

  Future<bool> revokeAuthorization(String id) async {
    final ok = await _repo.revokeAuthorization(id);
    if (ok) refresh();
    return ok;
  }
}

final apiAuthorizationControllerProvider =
    NotifierProvider<ApiAuthorizationController, ApiAuthorizationListViewData>(
  ApiAuthorizationController.new,
);

class ApiKeyController extends Notifier<ApiKeyListViewData> {
  @override
  ApiKeyListViewData build() {
    return ref.read(apiAuthorizationRepositoryProvider).getApiKeys();
  }

  ApiAuthorizationRepository get _repo =>
      ref.read(apiAuthorizationRepositoryProvider);

  void refresh() {
    state = _repo.getApiKeys();
  }

  Future<bool> issueApiKey(Map<String, dynamic> data) async {
    final ok = await _repo.issueApiKey(data);
    if (ok) refresh();
    return ok;
  }

  Future<bool> revokeApiKey(String keyId) async {
    final ok = await _repo.revokeApiKey(keyId);
    if (ok) refresh();
    return ok;
  }
}

final apiKeyControllerProvider =
    NotifierProvider<ApiKeyController, ApiKeyListViewData>(
  ApiKeyController.new,
);
