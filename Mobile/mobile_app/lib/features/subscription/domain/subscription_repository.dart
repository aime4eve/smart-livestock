import 'package:smart_livestock_demo/core/models/subscription_tier.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionStatus> loadCurrent();
  Future<List<SubscriptionTierInfo>> loadPlans();
  Future<SubscriptionStatus> checkout({
    required String tier,
    required int livestockCount,
  });
  Future<SubscriptionStatus> changeTier(String tier);
  Future<void> cancel();
  Future<SubscriptionUsage> loadUsage();
}

class SubscriptionUsage {
  const SubscriptionUsage({
    required this.livestockCount,
    required this.livestockLimit,
    this.fenceCount = 0,
    this.fenceLimit = 0,
    this.alertHistoryDays = 30,
    this.dataRetentionDays = 365,
  });

  final int livestockCount;
  final int livestockLimit;
  final int fenceCount;
  final int fenceLimit;
  final int alertHistoryDays;
  final int dataRetentionDays;
}
