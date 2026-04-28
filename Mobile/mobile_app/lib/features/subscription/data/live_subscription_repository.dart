import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/subscription/data/mock_subscription_repository.dart';
import 'package:smart_livestock_demo/features/subscription/domain/subscription_repository.dart';

class LiveSubscriptionRepository implements SubscriptionRepository {
  const LiveSubscriptionRepository();

  MockSubscriptionRepository get _mock => MockSubscriptionRepository();

  @override
  SubscriptionStatus loadCurrent() {
    final cache = ApiCache.instance;
    final data = cache.subscriptionCurrent;
    if (data == null) return _mock.loadCurrent();
    return SubscriptionStatus.fromJson(data);
  }

  @override
  List<SubscriptionTierInfo> loadPlans() {
    final cache = ApiCache.instance;
    final data = cache.subscriptionPlans;
    if (data == null) return _mock.loadPlans();
    return data
        .map((m) {
          final tierName = m['tier'] as String;
          final tier = SubscriptionTier.values.byName(tierName);
          return SubscriptionTierInfo.all[tier]!;
        })
        .toList();
  }

  @override
  Map<String, FeatureDefinition> loadFeatures() {
    final cache = ApiCache.instance;
    final data = cache.subscriptionFeatures;
    if (data == null) return FeatureFlags.all;
    return Map<String, FeatureDefinition>.fromEntries(
      data.entries.map((e) {
        final def = FeatureFlags.all[e.key];
        return MapEntry(e.key, def ?? const FeatureDefinition(shape: FeatureShape.none));
      }),
    );
  }

  @override
  SubscriptionStatus checkout(SubscriptionTier tier, int livestockCount,
      {String? idempotencyKey}) {
    // In live mode, this would make an HTTP POST to the backend.
    // For now, fallback to mock.
    return _mock.checkout(tier, livestockCount);
  }

  @override
  SubscriptionStatus cancel() {
    // In live mode, this would make an HTTP POST to the backend.
    // For now, fallback to mock.
    return _mock.cancel();
  }

  @override
  SubscriptionStatus renew(int livestockCount, {String? idempotencyKey}) {
    // In live mode, this would make an HTTP POST to the backend.
    // For now, fallback to mock.
    return _mock.renew(livestockCount);
  }

  @override
  Map<String, dynamic> loadUsage() {
    final cache = ApiCache.instance;
    final data = cache.subscriptionUsage;
    if (data == null) return _mock.loadUsage();
    return data;
  }
}
