import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/subscription/domain/subscription_repository.dart';

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
    if (items.isEmpty) {
      return SubscriptionTierInfo.all.values.toList();
    }
    return items.whereType<Map<String, dynamic>>().map((m) {
      final tier = parseSubscriptionTier(m['tier'] as String? ?? '');
      final fallback = SubscriptionTierInfo.all[tier]!;
      return SubscriptionTierInfo(
        tier: tier,
        name: m['name'] as String? ?? fallback.name,
        monthlyPrice: (m['monthlyPrice'] as num?)?.toDouble() ?? fallback.monthlyPrice,
        livestockLimit: m['livestockLimit'] as int? ?? fallback.livestockLimit,
        perUnitPrice: (m['perUnitPrice'] as num?)?.toDouble() ?? fallback.perUnitPrice,
        features: (m['features'] as List?)?.whereType<String>().toList() ?? fallback.features,
      );
    }).toList();
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
