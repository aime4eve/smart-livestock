import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/data/subscription_service_api_repository.dart';
import 'package:smart_livestock_demo/features/subscription_service_management/domain/subscription_service_repository.dart';

final subscriptionServiceRepositoryProvider =
    Provider<SubscriptionServiceRepository>((ref) {
  return const SubscriptionServiceApiRepository();
});

class SubscriptionServiceController
    extends AsyncNotifier<SubscriptionServiceListData> {
  @override
  Future<SubscriptionServiceListData> build() async {
    return ref.read(subscriptionServiceRepositoryProvider).loadServices();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(subscriptionServiceRepositoryProvider).loadServices());
  }

  Future<SubscriptionServiceInfo> createService(
      Map<String, dynamic> body) async {
    final info = await ref
        .read(subscriptionServiceRepositoryProvider)
        .createService(body);
    await refresh();
    return info;
  }

  Future<void> activateService(String id) async {
    await ref
        .read(subscriptionServiceRepositoryProvider)
        .updateServiceStatus(id, 'ACTIVE');
    await refresh();
  }

  Future<void> revokeService(String id) async {
    await ref
        .read(subscriptionServiceRepositoryProvider)
        .updateServiceStatus(id, 'EXPIRED');
    await refresh();
  }

  Future<void> updateQuota(String id, int quota) async {
    await ref
        .read(subscriptionServiceRepositoryProvider)
        .updateServiceQuota(id, quota);
    await refresh();
  }

  // ── Subscription management ───────────────────────────────────────

  Future<SubscriptionListData> loadSubscriptions({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? tier,
  }) async {
    return ref.read(subscriptionServiceRepositoryProvider).loadSubscriptions(
          page: page,
          pageSize: pageSize,
          status: status,
          tier: tier,
        );
  }

  Future<SubscriptionInfo> loadSubscriptionDetail(String id) async {
    return ref
        .read(subscriptionServiceRepositoryProvider)
        .loadSubscriptionDetail(id);
  }

  Future<SubscriptionInfo> updateSubscriptionStatus(
      String id, String targetStatus) async {
    return ref
        .read(subscriptionServiceRepositoryProvider)
        .updateSubscriptionStatus(id, targetStatus);
  }
}

final subscriptionServiceControllerProvider =
    AsyncNotifierProvider<SubscriptionServiceController,
        SubscriptionServiceListData>(
  SubscriptionServiceController.new,
);
