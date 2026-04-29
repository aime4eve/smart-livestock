import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/subscription/data/live_subscription_repository.dart';
import 'package:smart_livestock_demo/features/subscription/data/mock_subscription_repository.dart';
import 'package:smart_livestock_demo/features/subscription/domain/subscription_repository.dart';

class SubscriptionController extends Notifier<SubscriptionStatus> {
  @override
  SubscriptionStatus build() {
    final appMode = ref.watch(appModeProvider);
    final repo = appMode.isLive
        ? const LiveSubscriptionRepository() as SubscriptionRepository
        : MockSubscriptionRepository();
    return repo.loadCurrent();
  }

  SubscriptionRepository _repo() {
    final appMode = ref.read(appModeProvider);
    return appMode.isLive ? const LiveSubscriptionRepository() : MockSubscriptionRepository();
  }

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
  final appMode = ref.watch(appModeProvider);
  final repo =
      appMode.isLive ? const LiveSubscriptionRepository() : MockSubscriptionRepository();
  return repo.loadPlans();
});

final subscriptionFeaturesProvider =
    Provider<Map<String, FeatureDefinition>>((ref) {
  final appMode = ref.watch(appModeProvider);
  final repo =
      appMode.isLive ? const LiveSubscriptionRepository() : MockSubscriptionRepository();
  return repo.loadFeatures();
});
