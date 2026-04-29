import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';

void main() {
  group('SubscriptionTier', () {
    test('enum has 4 values', () {
      expect(SubscriptionTier.values.length, 4);
      expect(SubscriptionTier.values.byName('basic'), SubscriptionTier.basic);
      expect(SubscriptionTier.values.byName('standard'), SubscriptionTier.standard);
      expect(SubscriptionTier.values.byName('premium'), SubscriptionTier.premium);
      expect(SubscriptionTier.values.byName('enterprise'), SubscriptionTier.enterprise);
    });
  });

  group('SubscriptionTierInfo', () {
    test('all map contains 4 tiers', () {
      expect(SubscriptionTierInfo.all.length, 4);
    });

    test('basic tier has correct metadata', () {
      final info = SubscriptionTierInfo.all[SubscriptionTier.basic]!;
      expect(info.name, '基础版');
      expect(info.monthlyPrice, 0);
      expect(info.livestockLimit, 50);
      expect(info.perUnitPrice, 2);
      expect(info.features.isNotEmpty, true);
    });

    test('standard tier has correct metadata', () {
      final info = SubscriptionTierInfo.all[SubscriptionTier.standard]!;
      expect(info.name, '标准版');
      expect(info.monthlyPrice, 299);
      expect(info.livestockLimit, 200);
      expect(info.perUnitPrice, 2);
    });

    test('premium tier has correct metadata', () {
      final info = SubscriptionTierInfo.all[SubscriptionTier.premium]!;
      expect(info.name, '高级版');
      expect(info.monthlyPrice, 699);
      expect(info.livestockLimit, 1000);
      expect(info.perUnitPrice, 2);
    });

    test('enterprise tier has sentinel values', () {
      final info = SubscriptionTierInfo.all[SubscriptionTier.enterprise]!;
      expect(info.name, '企业版');
      expect(info.monthlyPrice, -1);
      expect(info.livestockLimit, -1);
    });

    test('enterprise has most features', () {
      final enterprise = SubscriptionTierInfo.all[SubscriptionTier.enterprise]!;
      final basic = SubscriptionTierInfo.all[SubscriptionTier.basic]!;
      expect(enterprise.features.length, greaterThan(basic.features.length));
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
        'calculatedDeviceFee': 2250,
        'calculatedTierFee': 0,
        'calculatedTotal': 2250,
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
      expect(status.calculatedDeviceFee, 2250.0);
      expect(status.calculatedTierFee, 0.0);
      expect(status.calculatedTotal, 2250.0);
    });

    test('fromJson handles null trialEndsAt', () {
      final json = {
        'id': 'sub_002',
        'tenantId': 'tenant_002',
        'tier': 'standard',
        'status': 'active',
        'trialEndsAt': null,
        'currentPeriodEnd': '2026-06-01T00:00:00.000Z',
        'livestockCount': 100,
        'calculatedDeviceFee': 4500,
        'calculatedTierFee': 299,
        'calculatedTotal': 4799,
      };

      final status = SubscriptionStatus.fromJson(json);
      expect(status.trialEndsAt, isNull);
      expect(status.status, 'active');
      expect(status.calculatedTierFee, 299.0);
    });

    test('fromJson handles null currentPeriodEnd', () {
      final json = {
        'id': 'sub_003',
        'tenantId': 'tenant_003',
        'tier': 'basic',
        'status': 'expired',
        'trialEndsAt': null,
        'currentPeriodEnd': null,
        'livestockCount': 0,
        'calculatedDeviceFee': 0,
        'calculatedTierFee': 0,
        'calculatedTotal': 0,
      };

      final status = SubscriptionStatus.fromJson(json);
      expect(status.currentPeriodEnd, isNull);
      expect(status.tier, SubscriptionTier.basic);
    });

    test('calculatedTotal equals deviceFee + tierFee', () {
      final json = {
        'id': 'sub_004',
        'tenantId': 'tenant_004',
        'tier': 'premium',
        'status': 'active',
        'trialEndsAt': null,
        'currentPeriodEnd': '2026-06-01T00:00:00.000Z',
        'livestockCount': 100,
        'calculatedDeviceFee': 4500,
        'calculatedTierFee': 699,
        'calculatedTotal': 5199,
      };

      final status = SubscriptionStatus.fromJson(json);
      expect(status.calculatedTotal, status.calculatedDeviceFee + status.calculatedTierFee);
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

    test('fence has limit shape and requiredDevices', () {
      final def = FeatureFlags.all[FeatureFlags.fence]!;
      expect(def.shape, FeatureShape.limit);
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
      expect(checkTierAccess(SubscriptionTier.basic, FeatureFlags.gpsLocation), true);
    });

    test('basic tier cannot access health_score (lock)', () {
      expect(checkTierAccess(SubscriptionTier.basic, FeatureFlags.healthScore), false);
    });

    test('premium tier can access health_score', () {
      expect(checkTierAccess(SubscriptionTier.premium, FeatureFlags.healthScore), true);
    });

    test('standard tier can access alert_history', () {
      expect(checkTierAccess(SubscriptionTier.standard, FeatureFlags.alertHistory), true);
    });

    test('basic tier cannot access alert_history', () {
      expect(checkTierAccess(SubscriptionTier.basic, FeatureFlags.alertHistory), false);
    });

    test('enterprise can access all locked features', () {
      expect(checkTierAccess(SubscriptionTier.enterprise, FeatureFlags.gaitAnalysis), true);
      expect(checkTierAccess(SubscriptionTier.enterprise, FeatureFlags.behaviorStats), true);
      expect(checkTierAccess(SubscriptionTier.enterprise, FeatureFlags.apiAccess), true);
    });

    test('unknown feature key returns false', () {
      expect(checkTierAccess(SubscriptionTier.premium, 'nonexistent'), false);
    });

    test('data_retention_days uses Map tiers config', () {
      expect(checkTierAccess(SubscriptionTier.basic, FeatureFlags.dataRetentionDays), true);
      expect(checkTierAccess(SubscriptionTier.standard, FeatureFlags.dataRetentionDays), true);
    });
  });
}
