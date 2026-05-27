import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/subscription/data/subscription_api_repository.dart';
import 'package:smart_livestock_demo/features/subscription/domain/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (_) => const SubscriptionApiRepository(),
);

class SubscriptionController extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    return ref.read(subscriptionRepositoryProvider).loadCurrent();
  }

  Future<void> checkout({
    required String tier,
    required int livestockCount,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(subscriptionRepositoryProvider).checkout(
              tier: tier,
              livestockCount: livestockCount,
            ));
  }

  Future<void> changeTier(String tier) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(subscriptionRepositoryProvider).changeTier(tier));
  }

  Future<void> cancel() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(subscriptionRepositoryProvider).cancel();
      return ref.read(subscriptionRepositoryProvider).loadCurrent();
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(subscriptionRepositoryProvider).loadCurrent());
  }
}

final subscriptionControllerProvider =
    AsyncNotifierProvider<SubscriptionController, SubscriptionStatus>(
        SubscriptionController.new);

final subscriptionPlansProvider =
    FutureProvider<List<SubscriptionTierInfo>>((ref) async {
  return ref.read(subscriptionRepositoryProvider).loadPlans();
});

final subscriptionUsageProvider =
    FutureProvider<SubscriptionUsage>((ref) async {
  return ref.read(subscriptionRepositoryProvider).loadUsage();
});
