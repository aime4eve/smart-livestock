import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
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

  /// 支付并开通套餐。
  ///
  /// Returns null on success, or the failure message for the UI toast —
  /// the backend's localized text (e.g. state-conflict guidance) beats a
  /// blanket "please retry" that hides actionable causes (2026-10-06).
  Future<String?> checkout({
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
    final error = result.error;
    if (error == null) return null;
    return error is ApiException ? error.message : error.toString();
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
    FutureProvider<List<PlanInfo>>((ref) async {
  return ref.read(subscriptionRepositoryProvider).loadPlans();
});

final subscriptionUsageProvider =
    FutureProvider<SubscriptionUsage>((ref) async {
  return ref.read(subscriptionRepositoryProvider).loadUsage();
});
