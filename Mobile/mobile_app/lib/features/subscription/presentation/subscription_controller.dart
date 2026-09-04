import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/subscription/data/subscription_api_repository.dart';
import 'package:hkt_livestock_agentic/features/subscription/domain/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (_) => const SubscriptionApiRepository(),
);

class SubscriptionController extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    return ref.read(subscriptionRepositoryProvider).loadCurrent();
  }

  /// 支付并开通套餐；返回是否成功，供 UI 区分成功/失败提示
  Future<bool> checkout({
    required String tier,
    required int livestockCount,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() =>
        ref.read(subscriptionRepositoryProvider).checkout(
              tier: tier,
              livestockCount: livestockCount,
            ));
    state = result;
    return result.hasValue;
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
