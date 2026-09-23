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
  Future<List<PlanInfo>> loadPlans() async {
    // ApiClient wraps non-map payloads as {'value': <list>}.
    final data = await ApiClient.instance.get('/subscription/plans');
    final items = data['value'] as List? ?? [];
    return items.whereType<Map<String, dynamic>>().map(PlanInfo.fromJson).toList();
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
      livestockCap: data['livestockCap'] as int? ?? -1,
      unitPriceUsdCents: data['unitPriceUsdCents'] as int?,
      monthlyFeeUsdCents: data['monthlyFeeUsdCents'] as int?,
    );
  }
}
