import 'package:hkt_livestock_agentic/core/l10n/l10n.dart';

enum SubscriptionTier { basic, standard, premium, enterprise }

SubscriptionTier parseSubscriptionTier(String value) {
  final lower = value.toLowerCase();
  for (final t in SubscriptionTier.values) {
    if (t.name == lower) return t;
  }
  return SubscriptionTier.basic;
}

enum FeatureShape { none, lock, limit, filter }

/// Resolve a tier key id to a localized display name.
String localizedTierName(SubscriptionTier tier) {
  final l = L10n.instance;
  return switch (tier) {
    SubscriptionTier.basic => l.subscriptionTierBasic,
    SubscriptionTier.standard => l.subscriptionTierStandard,
    SubscriptionTier.premium => l.subscriptionTierPremium,
    SubscriptionTier.enterprise => l.subscriptionTierEnterprise,
  };
}

/// Resolve a feature key id to a localized display label.
/// Called at display time (not in the const model) since l10n is runtime.
String localizedFeatureLabel(String key) {
  final l = L10n.instance;
  switch (key) {
    case 'gps_location': return l.subFeatureGpsLocation;
    case 'fence_3': return l.subFeatureFenceCount('3');
    case 'fence_5': return l.subFeatureFenceCount('5');
    case 'fence_10': return l.subFeatureFenceCount('10');
    case 'fence_unlimited': return l.subFeatureFenceUnlimited;
    case 'alert_7': return l.subFeatureAlertHistoryDays('7');
    case 'alert_30': return l.subFeatureAlertHistoryDays('30');
    case 'alert_90': return l.subFeatureAlertHistoryDays('90');
    case 'alert_1y': return l.subFeatureAlertHistory1Year;
    case 'retention_7': return l.subFeatureDataRetentionDays('7');
    case 'retention_30': return l.subFeatureDataRetentionDays('30');
    case 'retention_365': return l.subFeatureDataRetention365;
    case 'retention_3y': return l.subFeatureDataRetention3Year;
    case 'dashboard_basic': return l.subFeatureDashboardBasic;
    case 'dashboard_advanced': return l.subFeatureDashboardAdvanced;
    case 'trajectory': return l.subFeatureTrajectory;
    case 'device_management': return l.subFeatureDeviceManagement;
    case 'health_score': return l.subFeatureHealthScore;
    case 'estrus_detect': return l.subFeatureEstrusDetect;
    case 'epidemic_alert': return l.subFeatureEpidemicAlert;
    case 'dedicated_support': return l.subFeatureDedicatedSupport;
    case 'gait_analysis': return l.subFeatureGaitAnalysis;
    case 'behavior_stats': return l.subFeatureBehaviorStats;
    case 'api_access': return l.subFeatureApiAccess;
    default: return key;
  }
}

class FeatureDefinition {
  final FeatureShape shape;
  final dynamic tiers;
  final int? limit;
  final List<String>? requiredDevices;

  const FeatureDefinition({
    required this.shape,
    this.tiers,
    this.limit,
    this.requiredDevices,
  });
}

class SubscriptionTierInfo {
  final SubscriptionTier tier;
  final String name;
  final List<String> features;

  const SubscriptionTierInfo({
    required this.tier,
    required this.name,
    required this.features,
  });

  static const Map<SubscriptionTier, SubscriptionTierInfo> all = {
    SubscriptionTier.basic: SubscriptionTierInfo(
      tier: SubscriptionTier.basic,
      name: 'basic',
      features: ['gps_location', 'fence_3', 'alert_7', 'retention_7', 'dashboard_basic'],
    ),
    SubscriptionTier.standard: SubscriptionTierInfo(
      tier: SubscriptionTier.standard,
      name: 'standard',
      features: [
        'gps_location', 'fence_5', 'alert_30', 'retention_30',
        'dashboard_basic', 'dashboard_advanced', 'trajectory', 'device_management',
      ],
    ),
    SubscriptionTier.premium: SubscriptionTierInfo(
      tier: SubscriptionTier.premium,
      name: 'premium',
      features: [
        'gps_location', 'fence_10', 'alert_90', 'retention_365',
        'dashboard_basic', 'dashboard_advanced', 'trajectory', 'device_management',
        'health_score', 'estrus_detect', 'epidemic_alert', 'dedicated_support',
      ],
    ),
    SubscriptionTier.enterprise: SubscriptionTierInfo(
      tier: SubscriptionTier.enterprise,
      name: 'enterprise',
      features: [
        'gps_location', 'fence_unlimited', 'alert_1y', 'retention_3y',
        'dashboard_basic', 'dashboard_advanced', 'trajectory', 'device_management',
        'health_score', 'estrus_detect', 'epidemic_alert', 'dedicated_support',
        'gait_analysis', 'behavior_stats', 'api_access',
      ],
    ),
  };
}

/// Herd-size pricing band; maxHead = -1 means unbounded.
/// Mirrors the backend SubscriptionTier.PriceBand (NIX-245 USD per-head model).
class PriceBand {
  final int minHead;
  final int maxHead;
  final int unitPriceUsdCents;

  const PriceBand({
    required this.minHead,
    required this.maxHead,
    required this.unitPriceUsdCents,
  });

  static const int unbounded = -1;

  bool covers(int headCount) =>
      headCount >= minHead && (maxHead == unbounded || headCount <= maxHead);

  /// Locale-neutral range label: "＜100", "100–499", "≥500".
  String rangeLabel() {
    if (maxHead == unbounded) return '≥$minHead';
    if (minHead <= 1) return '＜${maxHead + 1}';
    return '$minHead–$maxHead';
  }

  factory PriceBand.fromJson(Map<String, dynamic> json) => PriceBand(
        minHead: json['minHead'] as int? ?? 1,
        maxHead: json['maxHead'] as int? ?? unbounded,
        unitPriceUsdCents: json['unitPriceUsdCents'] as int? ?? 0,
      );
}

/// Pricing plan for one tier, parsed from GET /subscription/plans.
/// All amounts are US cents; hardware is billed separately (one-time,
/// customer-owned) and is not part of this subscription fee.
class PlanInfo {
  final SubscriptionTier tier;
  final String currency;
  final String billingUnit;
  final bool customPricing;
  final int livestockCap; // -1 = no cap
  final List<PriceBand> priceBands;

  const PlanInfo({
    required this.tier,
    required this.currency,
    required this.billingUnit,
    required this.customPricing,
    required this.livestockCap,
    required this.priceBands,
  });

  PriceBand bandFor(int headCount) => priceBands.firstWhere(
        (b) => b.covers(headCount),
        orElse: () => priceBands.first,
      );

  /// Monthly fee in US cents; null for custom-priced tiers.
  int? monthlyFeeUsdCents(int headCount) {
    if (customPricing || priceBands.isEmpty) return null;
    return bandFor(headCount).unitPriceUsdCents * headCount;
  }

  factory PlanInfo.fromJson(Map<String, dynamic> json) => PlanInfo(
        tier: parseSubscriptionTier(json['tier'] as String? ?? ''),
        currency: json['currency'] as String? ?? 'USD',
        billingUnit: json['billingUnit'] as String? ?? 'per_head_month',
        customPricing: json['customPricing'] as bool? ?? false,
        livestockCap: json['livestockCap'] as int? ?? -1,
        priceBands: (json['priceBands'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PriceBand.fromJson)
            .toList(),
      );
}

class SubscriptionStatus {
  final String id;
  final String tenantId;
  final SubscriptionTier tier;
  final String status;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;
  final int livestockCount;
  final String currency;
  final int? livestockCap;
  final PriceBand? applicableBand;
  final int? unitPriceUsdCents;
  final int? monthlyFeeUsdCents;

  const SubscriptionStatus({
    required this.id,
    required this.tenantId,
    required this.tier,
    required this.status,
    this.trialEndsAt,
    this.currentPeriodEnd,
    required this.livestockCount,
    this.currency = 'USD',
    this.livestockCap,
    this.applicableBand,
    this.unitPriceUsdCents,
    this.monthlyFeeUsdCents,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    // id/tenantId: 后端返回 int，前端统一为 String
    final rawId = json['id'];
    final rawTid = json['tenantId'];
    final band = json['applicableBand'];
    return SubscriptionStatus(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      tenantId: rawTid is int ? rawTid.toString() : (rawTid as String? ?? ''),
      tier: parseSubscriptionTier(json['tier'] as String? ?? ''),
      status: json['status'] as String? ?? '',
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.parse(json['trialEndsAt'] as String)
          : null,
      currentPeriodEnd: (json['currentPeriodEnd'] ?? json['expiresAt']) != null
          ? DateTime.parse(
              (json['currentPeriodEnd'] ?? json['expiresAt']) as String)
          : null,
      livestockCount: json['livestockCount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      livestockCap: json['livestockCap'] as int?,
      applicableBand:
          band is Map<String, dynamic> ? PriceBand.fromJson(band) : null,
      unitPriceUsdCents: json['unitPriceUsdCents'] as int?,
      monthlyFeeUsdCents: json['monthlyFeeUsdCents'] as int?,
    );
  }

  int get daysUntilExpiry {
    final end = status == 'trial' ? trialEndsAt : currentPeriodEnd;
    if (end == null) return -1;
    return end.difference(DateTime.now()).inDays;
  }
}

class FeatureFlags {
  FeatureFlags._();

  static const String gpsLocation = 'gps_location';
  static const String fence = 'fence';
  static const String trajectory = 'trajectory';
  static const String temperatureMonitor = 'temperature_monitor';
  static const String peristalticMonitor = 'peristaltic_monitor';
  static const String healthScore = 'health_score';
  static const String estrusDetect = 'estrus_detect';
  static const String epidemicAlert = 'epidemic_alert';
  static const String gaitAnalysis = 'gait_analysis';
  static const String behaviorStats = 'behavior_stats';
  static const String apiAccess = 'api_access';
  static const String stats = 'stats';
  static const String dashboardSummary = 'dashboard_summary';
  static const String dataRetentionDays = 'data_retention_days';
  static const String alertHistory = 'alert_history';
  static const String dedicatedSupport = 'dedicated_support';
  static const String deviceManagement = 'device_management';
  static const String livestockDetail = 'livestock_detail';
  static const String profile = 'profile';
  static const String tenantAdmin = 'tenant_admin';

  static const Map<String, FeatureDefinition> all = {
    FeatureFlags.gpsLocation: FeatureDefinition(
      shape: FeatureShape.none,
      tiers: ['basic', 'standard', 'premium', 'enterprise'],
    ),
    FeatureFlags.fence: FeatureDefinition(
      shape: FeatureShape.limit,
      tiers: ['basic', 'standard', 'premium', 'enterprise'],
      limit: 3,
      requiredDevices: ['gps'],
    ),
    FeatureFlags.trajectory: FeatureDefinition(
      shape: FeatureShape.lock,
      tiers: ['standard', 'premium', 'enterprise'],
      requiredDevices: ['gps'],
    ),
    FeatureFlags.temperatureMonitor: FeatureDefinition(
      shape: FeatureShape.none,
      tiers: ['basic', 'standard', 'premium', 'enterprise'],
      requiredDevices: ['capsule'],
    ),
    FeatureFlags.peristalticMonitor: FeatureDefinition(
      shape: FeatureShape.none,
      tiers: ['basic', 'standard', 'premium', 'enterprise'],
      requiredDevices: ['capsule'],
    ),
    FeatureFlags.healthScore: FeatureDefinition(
      shape: FeatureShape.lock,
      tiers: ['standard', 'premium', 'enterprise'],
      requiredDevices: ['gps', 'capsule'],
    ),
    FeatureFlags.estrusDetect: FeatureDefinition(
      shape: FeatureShape.lock,
      tiers: ['premium', 'enterprise'],
      requiredDevices: ['gps', 'capsule'],
    ),
    FeatureFlags.epidemicAlert: FeatureDefinition(
      shape: FeatureShape.lock,
      tiers: ['premium', 'enterprise'],
      requiredDevices: ['gps', 'capsule'],
    ),
    FeatureFlags.gaitAnalysis: FeatureDefinition(
      shape: FeatureShape.lock,
      tiers: ['enterprise'],
    ),
    FeatureFlags.behaviorStats: FeatureDefinition(
      shape: FeatureShape.lock,
      tiers: ['enterprise'],
    ),
    FeatureFlags.apiAccess: FeatureDefinition(
      shape: FeatureShape.lock,
      tiers: ['enterprise'],
    ),
    FeatureFlags.stats: FeatureDefinition(
      shape: FeatureShape.none,
      tiers: ['basic', 'standard', 'premium', 'enterprise'],
    ),
    FeatureFlags.dashboardSummary: FeatureDefinition(
      shape: FeatureShape.limit,
      tiers: ['basic', 'standard', 'premium', 'enterprise'],
      limit: 4,
    ),
    FeatureFlags.dataRetentionDays: FeatureDefinition(
      shape: FeatureShape.filter,
      tiers: {
        'basic': 7,
        'standard': 30,
        'premium': 365,
        'enterprise': 1095,
      },
    ),
    FeatureFlags.alertHistory: FeatureDefinition(
      shape: FeatureShape.lock,
      tiers: ['standard', 'premium', 'enterprise'],
    ),
    FeatureFlags.dedicatedSupport: FeatureDefinition(
      shape: FeatureShape.lock,
      tiers: ['premium', 'enterprise'],
    ),
    FeatureFlags.deviceManagement: FeatureDefinition(
      shape: FeatureShape.none,
      tiers: ['basic', 'standard', 'premium', 'enterprise'],
    ),
    FeatureFlags.livestockDetail: FeatureDefinition(
      shape: FeatureShape.none,
      tiers: ['basic', 'standard', 'premium', 'enterprise'],
    ),
    FeatureFlags.profile: FeatureDefinition(
      shape: FeatureShape.none,
      tiers: ['basic', 'standard', 'premium', 'enterprise'],
    ),
    FeatureFlags.tenantAdmin: FeatureDefinition(
      shape: FeatureShape.none,
      tiers: ['basic', 'standard', 'premium', 'enterprise'],
    ),
  };
}

bool checkTierAccess(SubscriptionTier tier, String featureKey) {
  final def = FeatureFlags.all[featureKey];
  if (def == null) return false;
  final tiersConfig = def.tiers;
  if (tiersConfig is List) {
    return tiersConfig.contains(tier.name);
  }
  if (tiersConfig is Map) {
    return tiersConfig.containsKey(tier.name);
  }
  return false;
}
