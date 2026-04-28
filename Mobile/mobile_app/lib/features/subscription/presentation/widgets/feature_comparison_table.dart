import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class FeatureComparisonTable extends ConsumerWidget {
  const FeatureComparisonTable({super.key});

  static const Map<String, String> _featureLabels = {
    FeatureFlags.gpsLocation: 'GPS定位',
    FeatureFlags.fence: '电子围栏',
    FeatureFlags.trajectory: '历史轨迹',
    FeatureFlags.temperatureMonitor: '瘤胃温度监测',
    FeatureFlags.peristalticMonitor: '瘤胃蠕动监测',
    FeatureFlags.healthScore: '健康评分',
    FeatureFlags.estrusDetect: '发情检测',
    FeatureFlags.epidemicAlert: '疫病预警',
    FeatureFlags.gaitAnalysis: '步态分析',
    FeatureFlags.behaviorStats: '行为统计',
    FeatureFlags.apiAccess: 'API访问',
    FeatureFlags.stats: '数据统计',
    FeatureFlags.dashboardSummary: '看板概览',
    FeatureFlags.dataRetentionDays: '数据保留',
    FeatureFlags.alertHistory: '告警历史',
    FeatureFlags.dedicatedSupport: '专属客服',
    FeatureFlags.deviceManagement: '设备管理',
    FeatureFlags.livestockDetail: '牲畜详情',
    FeatureFlags.profile: '个人中心',
    FeatureFlags.tenantAdmin: '租户管理',
  };

  static const List<SubscriptionTier> _tiers = [
    SubscriptionTier.basic,
    SubscriptionTier.standard,
    SubscriptionTier.premium,
    SubscriptionTier.enterprise,
  ];

  bool _hasAccess(SubscriptionTier tier, FeatureDefinition def) {
    final tiersConfig = def.tiers;
    if (tiersConfig is List) {
      return tiersConfig.contains(tier.name);
    }
    if (tiersConfig is Map) {
      return tiersConfig.containsKey(tier.name);
    }
    return false;
  }

  String _cellLabel(SubscriptionTier tier, String featureKey) {
    final def = FeatureFlags.all[featureKey];
    if (def == null) return '—';
    if (!_hasAccess(tier, def)) return '—';

    if (featureKey == FeatureFlags.dataRetentionDays) {
      final tiersConfig = def.tiers;
      if (tiersConfig is Map) {
        final v = tiersConfig[tier.name];
        if (v is num && v == double.infinity) return '永久';
        if (v is num) return '${v.toInt()}天';
      }
    }

    if (def.shape == FeatureShape.limit && def.limit != null) {
      if (featureKey == FeatureFlags.dashboardSummary) {
        return '${def.limit}项';
      }
      if (featureKey == FeatureFlags.fence) {
        return '${def.limit}个';
      }
    }

    return '✓';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      key: const Key('feature-comparison-table'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.md,
              ),
              child: Text(
                '功能对比',
                style: theme.textTheme.titleMedium,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: AppSpacing.lg,
                columns: [
                  const DataColumn(label: Text('功能')),
                  ..._tiers.map(
                    (t) {
                      final info = SubscriptionTierInfo.all[t]!;
                      return DataColumn(
                        label: Text(
                          info.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ],
                rows: _featureLabels.entries.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(Text(entry.value)),
                      ..._tiers.map((t) {
                        final label = _cellLabel(t, entry.key);
                        return DataCell(
                          Text(
                            label,
                            style: TextStyle(
                              color: label == '✓'
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight:
                                  label == '✓' ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
