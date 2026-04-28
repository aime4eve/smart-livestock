import 'package:smart_livestock_demo/core/models/subscription_tier.dart';

abstract class SubscriptionRepository {
  SubscriptionStatus loadCurrent();
  List<SubscriptionTierInfo> loadPlans();
  Map<String, FeatureDefinition> loadFeatures();
  SubscriptionStatus checkout(SubscriptionTier tier, int livestockCount,
      {String? idempotencyKey});
  SubscriptionStatus cancel();
  SubscriptionStatus renew(int livestockCount, {String? idempotencyKey});
  Map<String, dynamic> loadUsage();
}
