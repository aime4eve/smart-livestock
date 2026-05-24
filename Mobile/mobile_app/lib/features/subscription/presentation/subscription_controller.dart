import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/subscription/data/live_subscription_repository.dart';
import 'package:smart_livestock_demo/features/subscription/domain/subscription_repository.dart';

class SubscriptionController extends Notifier<SubscriptionStatus> {
  @override
  SubscriptionStatus build() {
    return const LiveSubscriptionRepository().loadCurrent();
  }

  SubscriptionRepository _repo() => const LiveSubscriptionRepository();

  void checkout(SubscriptionTier tier, int livestockCount,
      {String? idempotencyKey}) {
    state = _repo().checkout(tier, livestockCount, idempotencyKey: idempotencyKey);
  }

  void cancel() {
    state = _repo().cancel();
  }

  void renew(int livestockCount, {String? idempotencyKey}) {
    state = _repo().renew(livestockCount, idempotencyKey: idempotencyKey);
  }
}

final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, SubscriptionStatus>(
        SubscriptionController.new);

final subscriptionPlansProvider = Provider<List<SubscriptionTierInfo>>((ref) {
  return const LiveSubscriptionRepository().loadPlans();
});

final subscriptionFeaturesProvider =
    Provider<Map<String, FeatureDefinition>>((ref) {
  return const LiveSubscriptionRepository().loadFeatures();
});
