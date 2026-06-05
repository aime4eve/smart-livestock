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
