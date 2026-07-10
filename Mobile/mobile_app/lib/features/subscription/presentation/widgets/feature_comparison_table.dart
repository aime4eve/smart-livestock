import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class FeatureComparisonTable extends ConsumerWidget {
  const FeatureComparisonTable({super.key});

  static const List<String> _featureKeys = [
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

  static const List<SubscriptionTier> _tiers = [
    SubscriptionTier.basic,
    SubscriptionTier.standard,
    SubscriptionTier.premium,
    SubscriptionTier.enterprise,
  ];

  String _featureLabel(AppLocalizations l10n, String featureKey) {
    switch (featureKey) {
      case FeatureFlags.gpsLocation:
        return l10n.subFeatureGpsLocation;
      case FeatureFlags.fence:
        return l10n.cmpFeatureFence;
      case FeatureFlags.trajectory:
        return l10n.subFeatureTrajectory;
      case FeatureFlags.temperatureMonitor:
        return l10n.cmpFeatureTempMonitor;
      case FeatureFlags.peristalticMonitor:
        return l10n.cmpFeaturePeristalticMonitor;
      case FeatureFlags.healthScore:
        return l10n.subFeatureHealthScore;
      case FeatureFlags.estrusDetect:
        return l10n.subFeatureEstrusDetect;
      case FeatureFlags.epidemicAlert:
        return l10n.subFeatureEpidemicAlert;
      case FeatureFlags.gaitAnalysis:
        return l10n.subFeatureGaitAnalysis;
      case FeatureFlags.behaviorStats:
        return l10n.subFeatureBehaviorStats;
      case FeatureFlags.apiAccess:
        return l10n.subFeatureApiAccess;
      case FeatureFlags.stats:
        return l10n.cmpFeatureStats;
      case FeatureFlags.dashboardSummary:
        return l10n.cmpFeatureDashboard;
      case FeatureFlags.dataRetentionDays:
        return l10n.cmpFeatureDataRetention;
      case FeatureFlags.alertHistory:
        return l10n.cmpFeatureAlertHistory;
      case FeatureFlags.dedicatedSupport:
        return l10n.subFeatureDedicatedSupport;
      case FeatureFlags.deviceManagement:
        return l10n.subFeatureDeviceManagement;
      case FeatureFlags.livestockDetail:
        return l10n.cmpFeatureLivestockDetail;
      case FeatureFlags.profile:
        return l10n.cmpFeatureProfile;
      case FeatureFlags.tenantAdmin:
        return l10n.cmpFeatureTenantAdmin;
      default:
        return featureKey;
    }
  }

  String _cellLabel(
      AppLocalizations l10n, SubscriptionTier tier, String featureKey) {
    if (!checkTierAccess(tier, featureKey)) return '—';
    final def = FeatureFlags.all[featureKey];
    if (def == null) return '—';

    final tiersConfig = def.tiers;

    if (tiersConfig is Map) {
      final v = tiersConfig[tier.name];
      if (v is num) {
        if (featureKey == FeatureFlags.dataRetentionDays) {
          if (v >= 1095) {
            return l10n.cmpCellYears('${(v.toInt() / 365).round()}');
          }
          if (v == double.infinity || v == -1) return l10n.cmpCellLifetime;
          return l10n.cmpCellDays('${v.toInt()}');
        }
        return '${v.toInt()}';
      }
    }

    if (def.shape == FeatureShape.limit && def.limit != null) {
      if (featureKey == FeatureFlags.dashboardSummary) {
        return l10n.cmpCellItems('${def.limit}');
      }
    }

    return '✓';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.subComparisonTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: AppSpacing.lg,
                columns: [
                  DataColumn(label: Text(l10n.subscriptionFeature)),
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
                rows: _featureKeys.map((key) {
                  return DataRow(
                    cells: [
                      DataCell(Text(_featureLabel(l10n, key))),
                      ..._tiers.map((t) {
                        final label = _cellLabel(l10n, t, key);
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
