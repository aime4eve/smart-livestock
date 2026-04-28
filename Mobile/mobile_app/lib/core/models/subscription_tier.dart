enum SubscriptionTier { basic, standard, premium, enterprise }

enum FeatureShape { none, lock, limit, filter }

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
  final double monthlyPrice;
  final int livestockLimit;
  final double perUnitPrice;
  final List<String> features;

  const SubscriptionTierInfo({
    required this.tier,
    required this.name,
    required this.monthlyPrice,
    required this.livestockLimit,
    required this.perUnitPrice,
    required this.features,
  });

  static const Map<SubscriptionTier, SubscriptionTierInfo> all = {
    SubscriptionTier.basic: SubscriptionTierInfo(
      tier: SubscriptionTier.basic,
      name: '基础版',
      monthlyPrice: 0,
      livestockLimit: 50,
      perUnitPrice: 2,
      features: ['GPS定位', '电子围栏(3个)', '告警历史(7天)', '基础看板'],
    ),
    SubscriptionTier.standard: SubscriptionTierInfo(
      tier: SubscriptionTier.standard,
      name: '标准版',
      monthlyPrice: 299,
      livestockLimit: 200,
      perUnitPrice: 2,
      features: [
        'GPS定位',
        '电子围栏(3个)',
        '告警历史(7天)',
        '基础看板',
        '历史轨迹',
        '高级看板',
        '告警历史(30天)',
        '设备管理',
      ],
    ),
    SubscriptionTier.premium: SubscriptionTierInfo(
      tier: SubscriptionTier.premium,
      name: '高级版',
      monthlyPrice: 699,
      livestockLimit: 1000,
      perUnitPrice: 2,
      features: [
        'GPS定位',
        '电子围栏(3个)',
        '告警历史(7天)',
        '基础看板',
        '历史轨迹',
        '高级看板',
        '告警历史(30天)',
        '设备管理',
        '健康评分',
        '发情检测',
        '疫病预警',
        '专属客服',
        '数据保留(365天)',
      ],
    ),
    SubscriptionTier.enterprise: SubscriptionTierInfo(
      tier: SubscriptionTier.enterprise,
      name: '企业版',
      monthlyPrice: -1,
      livestockLimit: -1,
      perUnitPrice: 0,
      features: [
        'GPS定位',
        '电子围栏(3个)',
        '告警历史(7天)',
        '基础看板',
        '历史轨迹',
        '高级看板',
        '告警历史(30天)',
        '设备管理',
        '健康评分',
        '发情检测',
        '疫病预警',
        '专属客服',
        '数据保留(365天)',
        '步态分析',
        '行为统计',
        'API访问',
      ],
    ),
  };
}

class SubscriptionStatus {
  final String id;
  final String tenantId;
  final SubscriptionTier tier;
  final String status;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;
  final int livestockCount;
  final double calculatedDeviceFee;
  final double calculatedTierFee;
  final double calculatedTotal;

  const SubscriptionStatus({
    required this.id,
    required this.tenantId,
    required this.tier,
    required this.status,
    this.trialEndsAt,
    this.currentPeriodEnd,
    required this.livestockCount,
    required this.calculatedDeviceFee,
    required this.calculatedTierFee,
    required this.calculatedTotal,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      tier: SubscriptionTier.values.byName(json['tier'] as String),
      status: json['status'] as String,
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.parse(json['trialEndsAt'] as String)
          : null,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'] as String)
          : null,
      livestockCount: json['livestockCount'] as int,
      calculatedDeviceFee:
          (json['calculatedDeviceFee'] as num).toDouble(),
      calculatedTierFee:
          (json['calculatedTierFee'] as num).toDouble(),
      calculatedTotal:
          (json['calculatedTotal'] as num).toDouble(),
    );
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
      tiers: ['premium', 'enterprise'],
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
        'enterprise': double.infinity,
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
