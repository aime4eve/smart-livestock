import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';

void main() {
  group('SubscriptionTier', () {
    test('enum has 4 values', () {
      expect(SubscriptionTier.values.length, 4);
      expect(SubscriptionTier.values.byName('basic'), SubscriptionTier.basic);
      expect(SubscriptionTier.values.byName('standard'),
          SubscriptionTier.standard);
      expect(
          SubscriptionTier.values.byName('premium'), SubscriptionTier.premium);
      expect(SubscriptionTier.values.byName('enterprise'),
          SubscriptionTier.enterprise);
    });
  });

  group('SubscriptionTierInfo', () {
    test('all map contains 4 tiers', () {
      expect(SubscriptionTierInfo.all.length, 4);
    });

    test('tier metadata keeps name and features only (pricing lives in PlanInfo)', () {
      final basic = SubscriptionTierInfo.all[SubscriptionTier.basic]!;
      expect(basic.name, 'basic');
      expect(basic.features.isNotEmpty, true);

      final enterprise = SubscriptionTierInfo.all[SubscriptionTier.enterprise]!;
      expect(enterprise.name, 'enterprise');
      expect(
          enterprise.features.length, greaterThan(basic.features.length));
    });
  });

  group('PlanInfo (NIX-245 USD per-head pricing)', () {
    PlanInfo premiumPlan() => PlanInfo.fromJson({
          'tier': 'PREMIUM',
          'currency': 'USD',
          'billingUnit': 'per_head_month',
          'customPricing': false,
          'livestockCap': -1,
          'priceBands': [
            {'minHead': 1, 'maxHead': 99, 'unitPriceUsdCents': 320},
            {'minHead': 100, 'maxHead': 499, 'unitPriceUsdCents': 265},
            {'minHead': 500, 'maxHead': -1, 'unitPriceUsdCents': 175},
          ],
        });

    test('fromJson parses tier, currency and bands', () {
      final plan = premiumPlan();
      expect(plan.tier, SubscriptionTier.premium);
      expect(plan.currency, 'USD');
      expect(plan.livestockCap, -1);
      expect(plan.priceBands.length, 3);
      expect(plan.priceBands[1].unitPriceUsdCents, 265);
    });

    test('band boundaries are inclusive', () {
      final plan = premiumPlan();
      expect(plan.bandFor(99).unitPriceUsdCents, 320);
      expect(plan.bandFor(100).unitPriceUsdCents, 265);
      expect(plan.bandFor(499).unitPriceUsdCents, 265);
      expect(plan.bandFor(500).unitPriceUsdCents, 175);
      expect(plan.bandFor(1200).unitPriceUsdCents, 175);
    });

    test('monthly fee = head count × band unit price', () {
      final plan = premiumPlan();
      expect(plan.monthlyFeeUsdCents(0), 0);
      expect(plan.monthlyFeeUsdCents(80), 80 * 320);
      expect(plan.monthlyFeeUsdCents(260), 260 * 265);
      expect(plan.monthlyFeeUsdCents(1000), 1000 * 175);
    });

    test('custom pricing tiers return null fee', () {
      final plan = PlanInfo.fromJson({
        'tier': 'ENTERPRISE',
        'currency': 'USD',
        'billingUnit': 'per_head_month',
        'customPricing': true,
        'livestockCap': -1,
        'priceBands': [],
      });
      expect(plan.monthlyFeeUsdCents(100), isNull);
    });

    test('rangeLabel renders locale-neutral band ranges', () {
      final plan = premiumPlan();
      expect(plan.priceBands[0].rangeLabel(), '＜100');
      expect(plan.priceBands[1].rangeLabel(), '100–499');
      expect(plan.priceBands[2].rangeLabel(), '≥500');
    });
  });

  group('SubscriptionStatus', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'sub_001',
        'tenantId': 'tenant_001',
        'tier': 'premium',
        'status': 'trial',
        'trialEndsAt': '2026-05-12T00:00:00.000Z',
        'currentPeriodEnd': '2026-05-12T00:00:00.000Z',
        'livestockCount': 50,
        'currency': 'USD',
        'livestockCap': -1,
        'applicableBand': {
          'minHead': 1,
          'maxHead': 99,
          'unitPriceUsdCents': 320,
        },
        'unitPriceUsdCents': 320,
        'monthlyFeeUsdCents': 16000,
      };

      final status = SubscriptionStatus.fromJson(json);
      expect(status.id, 'sub_001');
      expect(status.tenantId, 'tenant_001');
      expect(status.tier, SubscriptionTier.premium);
      expect(status.status, 'trial');
      expect(status.trialEndsAt, isNotNull);
      expect(status.trialEndsAt!.year, 2026);
      expect(status.currentPeriodEnd, isNotNull);
      expect(status.livestockCount, 50);
      expect(status.livestockCap, -1);
      expect(status.unitPriceUsdCents, 320);
      expect(status.monthlyFeeUsdCents, 16000);
      expect(status.applicableBand!.maxHead, 99);
    });

    test('fromJson handles missing pricing fields (enterprise)', () {
      final json = {
        'id': 'sub_003',
        'tenantId': 'tenant_003',
        'tier': 'basic',
        'status': 'expired',
        'trialEndsAt': null,
        'currentPeriodEnd': null,
        'livestockCount': 0,
      };

      final status = SubscriptionStatus.fromJson(json);
      expect(status.currentPeriodEnd, isNull);
      expect(status.tier, SubscriptionTier.basic);
      expect(status.applicableBand, isNull);
      expect(status.unitPriceUsdCents, isNull);
      expect(status.monthlyFeeUsdCents, isNull);
    });
  });

  group('FeatureFlags', () {
    test('all map contains 20 feature keys', () {
      expect(FeatureFlags.all.length, 20);
    });

    test('all 20 string constants are unique', () {
      final keys = [
        FeatureFlags.gpsLocation,
        FeatureFlags.fence,
        FeatureFlags.trajectory,
        FeatureFlags.temperatureMonitor,
        FeatureFlags.peristalticMonitor,
        FeatureFlags.healthScore,
        FeatureFlags.estrusDetect,
        FeatureFlags.epidemicAlert,
        FeatureFlags.gaitAnalysis,
        FeatureFlags.behaviorStats,
        FeatureFlags.apiAccess,
        FeatureFlags.stats,
        FeatureFlags.dashboardSummary,
        FeatureFlags.dataRetentionDays,
        FeatureFlags.alertHistory,
        FeatureFlags.dedicatedSupport,
        FeatureFlags.deviceManagement,
        FeatureFlags.livestockDetail,
        FeatureFlags.profile,
        FeatureFlags.tenantAdmin,
      ];
      expect(keys.toSet().length, 20);
    });

    test('fence has limit shape for lowest tier', () {
      final def = FeatureFlags.all[FeatureFlags.fence]!;
      expect(def.shape, FeatureShape.limit);
      expect(def.tiers, ['basic', 'standard', 'premium', 'enterprise']);
      expect(def.limit, 3);
      expect(def.requiredDevices, ['gps']);
    });

    test('health_score has lock shape and dual device requirement', () {
      final def = FeatureFlags.all[FeatureFlags.healthScore]!;
      expect(def.shape, FeatureShape.lock);
      expect(def.requiredDevices, ['gps', 'capsule']);
    });

    test('gps_location has none shape', () {
      final def = FeatureFlags.all[FeatureFlags.gpsLocation]!;
      expect(def.shape, FeatureShape.none);
    });

    test('data_retention_days has filter shape', () {
      final def = FeatureFlags.all[FeatureFlags.dataRetentionDays]!;
      expect(def.shape, FeatureShape.filter);
    });

    test('enterprise-exclusive features are lock shaped', () {
      final gait = FeatureFlags.all[FeatureFlags.gaitAnalysis]!;
      expect(gait.shape, FeatureShape.lock);
      expect(gait.tiers, ['enterprise']);

      final api = FeatureFlags.all[FeatureFlags.apiAccess]!;
      expect(api.shape, FeatureShape.lock);
      expect(api.tiers, ['enterprise']);
    });
  });

  group('checkTierAccess', () {
    test('basic tier can access gps_location', () {
      expect(checkTierAccess(SubscriptionTier.basic, FeatureFlags.gpsLocation),
          true);
    });

    test('basic tier cannot access health_score (lock)', () {
      expect(checkTierAccess(SubscriptionTier.basic, FeatureFlags.healthScore),
          false);
    });

    test('premium tier can access health_score', () {
      expect(
          checkTierAccess(SubscriptionTier.premium, FeatureFlags.healthScore),
          true);
    });

    test('standard tier can access alert_history', () {
      expect(
          checkTierAccess(SubscriptionTier.standard, FeatureFlags.alertHistory),
          true);
    });

    test('basic tier cannot access alert_history', () {
      expect(checkTierAccess(SubscriptionTier.basic, FeatureFlags.alertHistory),
          false);
    });

    test('enterprise can access all locked features', () {
      expect(
          checkTierAccess(
              SubscriptionTier.enterprise, FeatureFlags.gaitAnalysis),
          true);
      expect(
          checkTierAccess(
              SubscriptionTier.enterprise, FeatureFlags.behaviorStats),
          true);
      expect(
          checkTierAccess(SubscriptionTier.enterprise, FeatureFlags.apiAccess),
          true);
    });

    test('unknown feature key returns false', () {
      expect(checkTierAccess(SubscriptionTier.premium, 'nonexistent'), false);
    });

    test('data_retention_days uses Map tiers config', () {
      expect(
          checkTierAccess(
              SubscriptionTier.basic, FeatureFlags.dataRetentionDays),
          true);
      expect(
          checkTierAccess(
              SubscriptionTier.standard, FeatureFlags.dataRetentionDays),
          true);
    });
  });
}
