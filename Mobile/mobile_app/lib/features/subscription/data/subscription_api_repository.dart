import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/subscription/domain/subscription_repository.dart';

class SubscriptionApiRepository implements SubscriptionRepository {
  const SubscriptionApiRepository();

  @override
  Future<SubscriptionStatus> loadCurrent() async {
    final data = await ApiClient.instance.get('/subscription');
    return SubscriptionStatus.fromJson(data);
  }

  @override
  Future<List<SubscriptionTierInfo>> loadPlans() async {
    final data = await ApiClient.instance.get('/subscription/plans');
    final items = data['items'] as List? ?? data['plans'] as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((m) {
          final tierName = m['tier'] as String;
          final tier = SubscriptionTier.values.byName(tierName);
          return SubscriptionTierInfo.all[tier]!;
        })
        .toList();
  }

  @override
  Future<SubscriptionStatus> checkout({
    required String tier,
    required int livestockCount,
  }) async {
    final data = await ApiClient.instance.post(
      '/subscription/checkout',
      body: {'tier': tier, 'livestockCount': livestockCount},
    );
    return SubscriptionStatus.fromJson(data);
  }

  @override
  Future<SubscriptionStatus> changeTier(String tier) async {
    final data = await ApiClient.instance.put(
      '/subscription/tier',
      body: {'tier': tier},
    );
    return SubscriptionStatus.fromJson(data);
  }

  @override
  Future<void> cancel() async {
    await ApiClient.instance.post('/subscription/cancel');
  }

  @override
  Future<SubscriptionUsage> loadUsage() async {
    final data = await ApiClient.instance.get('/subscription/usage');
    return SubscriptionUsage(
      livestockCount: data['livestockCount'] as int? ?? 0,
      livestockLimit: data['livestockLimit'] as int? ?? -1,
      fenceCount: data['fenceCount'] as int? ?? 0,
      fenceLimit: data['fenceLimit'] as int? ?? 0,
      alertHistoryDays: data['alertHistoryDays'] as int? ?? 30,
      dataRetentionDays: data['dataRetentionDays'] as int? ?? 365,
    );
  }
}
