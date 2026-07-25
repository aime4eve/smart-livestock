class FeatureGateEntry {
  const FeatureGateEntry({
    required this.id,
    required this.tier,
    required this.featureKey,
    this.gateType,
    this.limitValue = 0,
    this.retentionDays = 0,
    this.isEnabled = true,
  });

  final int id;
  final String tier;
  final String featureKey;
  final String? gateType;
  final int limitValue;
  final int retentionDays;
  final bool isEnabled;
}

/// Metadata for each feature key: display name i18n key, category, and unit.
class FeatureMeta {
  const FeatureMeta({
    required this.nameKey,
    required this.category,
    this.unit = FeatureUnit.none,
  });

  /// AppLocalizations key for the feature display name.
  final String nameKey;
  final FeatureCategory category;
  final FeatureUnit unit;

  static const Map<String, FeatureMeta> _map = {
    'livestock_management':   FeatureMeta(nameKey: 'featLivestockManagement',  category: FeatureCategory.platform, unit: FeatureUnit.head),
    'fence_management':       FeatureMeta(nameKey: 'featFenceManagement',     category: FeatureCategory.platform, unit: FeatureUnit.count),
    'alert_management':       FeatureMeta(nameKey: 'featAlertManagement',     category: FeatureCategory.platform),
    'worker_management':      FeatureMeta(nameKey: 'featWorkerManagement',    category: FeatureCategory.platform, unit: FeatureUnit.person),
    'advanced_analytics':     FeatureMeta(nameKey: 'featAdvancedAnalytics',   category: FeatureCategory.platform, unit: FeatureUnit.day),
    'api_access':             FeatureMeta(nameKey: 'featApiAccess',           category: FeatureCategory.platform),
    'health_monitoring':      FeatureMeta(nameKey: 'featHealthMonitoring',    category: FeatureCategory.platform),
    'temperature_monitor':    FeatureMeta(nameKey: 'featTemperatureMonitor',  category: FeatureCategory.health,   unit: FeatureUnit.day),
    'peristaltic_monitor':    FeatureMeta(nameKey: 'featPeristalticMonitor',  category: FeatureCategory.health,   unit: FeatureUnit.day),
    'health_score':           FeatureMeta(nameKey: 'featHealthScore',         category: FeatureCategory.health,   unit: FeatureUnit.day),
    'estrus_detect':          FeatureMeta(nameKey: 'featEstrusDetect',        category: FeatureCategory.health,   unit: FeatureUnit.day),
    'epidemic_alert':         FeatureMeta(nameKey: 'featEpidemicAlert',       category: FeatureCategory.health,   unit: FeatureUnit.day),
  };

  static FeatureMeta? forKey(String featureKey) => _map[featureKey];
}

enum FeatureCategory { platform, health }

enum FeatureUnit { none, head, count, person, day }

extension FeatureGateEntryX on FeatureGateEntry {
  FeatureMeta? get meta => FeatureMeta.forKey(featureKey);
}
