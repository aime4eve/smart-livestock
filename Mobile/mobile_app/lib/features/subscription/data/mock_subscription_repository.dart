import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/subscription/domain/subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  MockSubscriptionRepository() {
    final trialInfo = SubscriptionTierInfo.all[SubscriptionTier.premium]!;
    _current = SubscriptionStatus(
      id: 'sub_mock_001',
      tenantId: 'tenant_001',
      tier: SubscriptionTier.premium,
      status: 'trial',
      trialEndsAt: DateTime.now().add(const Duration(days: 14)),
      currentPeriodEnd: null,
      livestockCount: 42,
      calculatedDeviceFee: 42 * trialInfo.perUnitPrice,
      calculatedTierFee: 0,
      calculatedTotal: 42 * trialInfo.perUnitPrice,
    );
  }

  late SubscriptionStatus _current;

  @override
  SubscriptionStatus loadCurrent() => _current;

  @override
  List<SubscriptionTierInfo> loadPlans() =>
      SubscriptionTierInfo.all.values.toList();

  @override
  Map<String, FeatureDefinition> loadFeatures() => FeatureFlags.all;

  @override
  SubscriptionStatus checkout(SubscriptionTier tier, int livestockCount,
      {String? idempotencyKey}) {
    final info = SubscriptionTierInfo.all[tier]!;
    final tierFee = info.monthlyPrice < 0 ? 0.0 : info.monthlyPrice;
    final deviceFee = livestockCount * info.perUnitPrice;
    _current = SubscriptionStatus(
      id: _current.id,
      tenantId: _current.tenantId,
      tier: tier,
      status: 'active',
      trialEndsAt: null,
      currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
      livestockCount: livestockCount,
      calculatedDeviceFee: deviceFee,
      calculatedTierFee: tierFee,
      calculatedTotal: tierFee + deviceFee,
    );
    return _current;
  }

  @override
  SubscriptionStatus cancel() {
    _current = SubscriptionStatus(
      id: _current.id,
      tenantId: _current.tenantId,
      tier: _current.tier,
      status: 'cancelled',
      trialEndsAt: _current.trialEndsAt,
      currentPeriodEnd: _current.currentPeriodEnd,
      livestockCount: _current.livestockCount,
      calculatedDeviceFee: _current.calculatedDeviceFee,
      calculatedTierFee: _current.calculatedTierFee,
      calculatedTotal: _current.calculatedTotal,
    );
    return _current;
  }

  @override
  SubscriptionStatus renew(int livestockCount, {String? idempotencyKey}) {
    final info = SubscriptionTierInfo.all[_current.tier]!;
    final tierFee = info.monthlyPrice < 0 ? 0.0 : info.monthlyPrice;
    final deviceFee = livestockCount * info.perUnitPrice;
    _current = SubscriptionStatus(
      id: _current.id,
      tenantId: _current.tenantId,
      tier: _current.tier,
      status: 'active',
      trialEndsAt: null,
      currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
      livestockCount: livestockCount,
      calculatedDeviceFee: deviceFee,
      calculatedTierFee: tierFee,
      calculatedTotal: tierFee + deviceFee,
    );
    return _current;
  }

  @override
  Map<String, dynamic> loadUsage() {
    final info = SubscriptionTierInfo.all[_current.tier];
    return {
      'livestockCount': _current.livestockCount,
      'livestockLimit':
          info?.livestockLimit ?? -1,
      'fenceCount': 3,
      'fenceLimit': 3,
      'alertHistoryDays': 30,
      'dataRetentionDays': 365,
    };
  }
}
