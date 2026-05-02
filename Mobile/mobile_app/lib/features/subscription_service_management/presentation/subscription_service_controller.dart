import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/data/live_subscription_service_repository.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/data/mock_subscription_service_repository.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/domain/subscription_service_repository.dart';

final subscriptionServiceRepositoryProvider =
    Provider<SubscriptionServiceRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return MockSubscriptionServiceRepository();
    case AppMode.live:
      return LiveSubscriptionServiceRepository();
  }
});

class SubscriptionServiceController
    extends Notifier<SubscriptionServiceListViewData> {
  @override
  SubscriptionServiceListViewData build() {
    return ref.read(subscriptionServiceRepositoryProvider).getServices();
  }

  SubscriptionServiceRepository get _repo =>
      ref.read(subscriptionServiceRepositoryProvider);

  void filter({String? tenantId, String? status}) {
    state = _repo.getServices(tenantId: tenantId, status: status);
  }

  void refresh() {
    state = _repo.getServices();
  }

  Future<bool> createService(Map<String, dynamic> data) async {
    final ok = await _repo.createService(data);
    if (ok) refresh();
    return ok;
  }

  Future<bool> renewService(String serviceId, String endDate) async {
    final ok = await _repo.renewService(serviceId, endDate);
    if (ok) refresh();
    return ok;
  }

  Future<bool> revokeService(String serviceId) async {
    final ok = await _repo.revokeService(serviceId);
    if (ok) refresh();
    return ok;
  }
}

final subscriptionServiceControllerProvider =
    NotifierProvider<SubscriptionServiceController,
        SubscriptionServiceListViewData>(
  SubscriptionServiceController.new,
);
