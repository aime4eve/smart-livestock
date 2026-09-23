import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionStatus> loadCurrent();
  Future<List<PlanInfo>> loadPlans();
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
    this.livestockCap = -1,
    this.unitPriceUsdCents,
    this.monthlyFeeUsdCents,
    this.fenceCount = 0,
    this.fenceLimit = 0,
    this.alertHistoryDays = 30,
    this.dataRetentionDays = 365,
  });

  final int livestockCount;
  final int livestockCap; // -1 = no cap
  final int? unitPriceUsdCents;
  final int? monthlyFeeUsdCents;
  final int fenceCount;
  final int fenceLimit;
  final int alertHistoryDays;
  final int dataRetentionDays;
}
