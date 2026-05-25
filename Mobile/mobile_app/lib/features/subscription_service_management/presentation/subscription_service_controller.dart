import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/data/subscription_service_api_repository.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/domain/subscription_service_repository.dart';

final subscriptionServiceRepositoryProvider =
    Provider<SubscriptionServiceRepository>((ref) {
  return const SubscriptionServiceApiRepository();
});

class SubscriptionServiceController
    extends AsyncNotifier<SubscriptionServiceListViewData> {
  @override
  Future<SubscriptionServiceListViewData> build() async {
    return ref.read(subscriptionServiceRepositoryProvider).getServices();
  }

  Future<void> filter({String? tenantId, String? status}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(subscriptionServiceRepositoryProvider).getServices(
              tenantId: tenantId,
              status: status,
            ));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(subscriptionServiceRepositoryProvider).getServices());
  }

  Future<bool> createService(Map<String, dynamic> data) async {
    final ok = await ref.read(subscriptionServiceRepositoryProvider).createService(data);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> renewService(String serviceId, String endDate) async {
    final ok = await ref.read(subscriptionServiceRepositoryProvider).renewService(serviceId, endDate);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> revokeService(String serviceId) async {
    final ok = await ref.read(subscriptionServiceRepositoryProvider).revokeService(serviceId);
    if (ok) await refresh();
    return ok;
  }
}

final subscriptionServiceControllerProvider =
    AsyncNotifierProvider<SubscriptionServiceController,
        SubscriptionServiceListViewData>(
  SubscriptionServiceController.new,
);
