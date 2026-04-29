import 'dart:async';

import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/subscription/data/mock_subscription_repository.dart';
import 'package:smart_livestock_demo/features/subscription/domain/subscription_repository.dart';

class LiveSubscriptionRepository implements SubscriptionRepository {
  const LiveSubscriptionRepository({this.role = 'owner'});

  final String role;
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
    // Fire async POST to backend, return mock result for sync UI update
    unawaited(ApiCache.instance.checkoutSubscriptionRemote(
      role,
      tier: tier.name,
      livestockCount: livestockCount,
      idempotencyKey: idempotencyKey,
    ));

    final result = _mock.checkout(tier, livestockCount, idempotencyKey: idempotencyKey);
    // Update cache so subsequent reads see the new state
    ApiCache.instance.updateSubscriptionCurrent(_statusToJson(result));
    return result;
  }

  @override
  SubscriptionStatus cancel() {
    unawaited(ApiCache.instance.cancelSubscriptionRemote(role));

    final result = _mock.cancel();
    ApiCache.instance.updateSubscriptionCurrent(_statusToJson(result));
    return result;
  }

  @override
  SubscriptionStatus renew(int livestockCount, {String? idempotencyKey}) {
    unawaited(ApiCache.instance.renewSubscriptionRemote(
      role,
      livestockCount: livestockCount,
      idempotencyKey: idempotencyKey,
    ));

    final result = _mock.renew(livestockCount, idempotencyKey: idempotencyKey);
    ApiCache.instance.updateSubscriptionCurrent(_statusToJson(result));
    return result;
  }

  @override
  Map<String, dynamic> loadUsage() {
    final cache = ApiCache.instance;
    final data = cache.subscriptionUsage;
    if (data == null) return _mock.loadUsage();
    return data;
  }

  Map<String, dynamic> _statusToJson(SubscriptionStatus status) => {
        'id': status.id,
        'tenantId': status.tenantId,
        'tier': status.tier.name,
        'status': status.status,
        'trialEndsAt': status.trialEndsAt?.toIso8601String(),
        'currentPeriodEnd': status.currentPeriodEnd?.toIso8601String(),
        'livestockCount': status.livestockCount,
        'calculatedDeviceFee': status.calculatedDeviceFee,
        'calculatedTierFee': status.calculatedTierFee,
        'calculatedTotal': status.calculatedTotal,
      };
}
