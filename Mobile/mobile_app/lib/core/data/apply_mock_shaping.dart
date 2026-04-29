import 'package:smart_livestock_demo/core/models/subscription_tier.dart';

String? _getMinTierForFeature(FeatureDefinition def) {
  final tiersConfig = def.tiers;
  if (tiersConfig is List && tiersConfig.isNotEmpty) {
    return tiersConfig.first as String;
  }
  if (tiersConfig is Map && tiersConfig.isNotEmpty) {
    return tiersConfig.keys.first as String;
  }
  return null;
}

int _getRetentionDays(SubscriptionTier tier) {
  final def = FeatureFlags.all[FeatureFlags.dataRetentionDays];
  if (def == null) return 7;
  final tiersConfig = def.tiers;
  if (tiersConfig is Map) {
    final v = tiersConfig[tier.name];
    if (v is num) return v.toInt();
  }
  return 7;
}

Map<String, dynamic> _applyLimit(Map<String, dynamic> data, int limit) {
  final items = data['items'];
  if (items is! List) return data;

  if (items.length <= limit) return data;

  final result = Map<String, dynamic>.from(data);
  result['items'] = items.sublist(0, limit);
  result['limitExceeded'] = true;
  result['limitValue'] = limit;
  result['totalBeforeLimit'] = items.length;
  result['total'] = limit;
  return result;
}

Map<String, dynamic> _applyFilter(
    Map<String, dynamic> data, int retentionDays) {
  final items = data['items'];
  if (items is! List) return data;

  final cutoff = DateTime.now().subtract(Duration(days: retentionDays));

  final filtered = items.where((item) {
    if (item is! Map<String, dynamic>) return true;
    final dateStr = item['occurredAt'] ??
        item['recordedAt'] ??
        item['timestamp'];
    if (dateStr == null) return true;
    return DateTime.parse(dateStr as String).isAfter(cutoff);
  }).toList();

  final result = Map<String, dynamic>.from(data);
  result['items'] = filtered;
  result['total'] = filtered.length;
  result['filteredTotal'] = items.length;
  return result;
}

Map<String, dynamic> applyMockShaping(
  Map<String, dynamic> data,
  SubscriptionTier tier,
  List<String> featureKeys,
) {
  Map<String, dynamic> result = Map<String, dynamic>.from(data);

  for (final key in featureKeys) {
    final flag = FeatureFlags.all[key];
    if (flag == null) continue;

    switch (flag.shape) {
      case FeatureShape.none:
        break;
      case FeatureShape.lock:
        if (!checkTierAccess(tier, key)) {
          final minTier = _getMinTierForFeature(flag);
          if (result['items'] is List) {
            result['items'] = <Map<String, dynamic>>[];
            result['total'] = 0;
          }
          result['locked'] = true;
          result['upgradeTier'] = minTier;
        }
        break;
      case FeatureShape.limit:
        final minTier = _getMinTierForFeature(flag);
        if (tier.name == minTier && flag.limit != null) {
          result = _applyLimit(result, flag.limit!);
        }
        break;
      case FeatureShape.filter:
        final retentionDays = _getRetentionDays(tier);
        result = _applyFilter(result, retentionDays);
        break;
    }
  }

  return result;
}
