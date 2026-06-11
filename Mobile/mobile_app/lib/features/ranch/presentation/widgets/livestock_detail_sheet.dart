import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/ranch/domain/ranch_models.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class LivestockDetailSheet extends StatelessWidget {
  const LivestockDetailSheet({
    super.key,
    required this.marker,
    this.relatedAlerts = const [],
  });

  final RanchLivestockMarker marker;
  final List<RanchAlertData> relatedAlerts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _HealthDot(healthStatus: marker.healthStatus),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    marker.livestockCode,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/livestock/${marker.livestockId}');
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l10n.ranchLivestockDetailBtn),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(label: '状态', value: _healthLabel(marker.healthStatus)),
            if (marker.primaryAlert.isNotEmpty)
              _InfoRow(label: '主要异常', value: _alertLabel(marker.primaryAlert)),
            _InfoRow(
                label: '位置',
                value: '${marker.latitude.toStringAsFixed(4)}, ${marker.longitude.toStringAsFixed(4)}'),
            if (relatedAlerts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l10n.ranchLivestockRelatedAlerts, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final alert in relatedAlerts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _alertColor(alert.severity).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_alertIcon(alert.type),
                            size: 14, color: _alertColor(alert.severity)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: Text(alert.message,
                              style: Theme.of(context).textTheme.bodySmall)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(alert.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _statusLabel(alert.status),
                          style: TextStyle(
                            color: _statusColor(alert.status),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _healthLabel(String status) {
    return switch (status) {
      'CRITICAL' => '严重',
      'WARNING' => '预警',
      _ => '正常',
    };
  }

  String _alertLabel(String alert) {
    return switch (alert) {
      'FEVER' => '发热',
      'DIGESTIVE' => '消化异常',
      'ESTRUS' => '发情高分',
      'EPIDEMIC' => '疫病风险',
      'FENCE_APPROACH' => '接近围栏',
      'ZONE_APPROACH' => '接近区域',
      _ => alert,
    };
  }

  IconData _alertIcon(String type) {
    return switch (type) {
      'FENCE_BREACH' => Icons.fence,
      'FENCE_APPROACH' => Icons.fence,
      'ZONE_APPROACH' => Icons.fence,
      'TEMPERATURE_ABNORMAL' => Icons.thermostat,
      'BEHAVIOR_ABNORMAL' => Icons.pets,
      'DIGESTIVE_ABNORMAL' => Icons.pets,
      'ESTRUS' => Icons.favorite,
      'EPIDEMIC' => Icons.shield,
      _ => Icons.warning,
    };
  }

  Color _alertColor(String severity) {
    return switch (severity) {
      'HIGH' => AppColors.danger,
      'CRITICAL' => AppColors.danger,
      'MEDIUM' => AppColors.warning,
      'WARNING' => AppColors.warning,
      _ => AppColors.info,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'ACTIVE' => '活跃',
      'DISMISSED' => '已忽略',
      'AUTO_RESOLVED' => '已自动解除',
      // Legacy compatibility
      'PENDING' => '活跃',
      'ACKNOWLEDGED' => '活跃',
      'HANDLED' => '已忽略',
      'ARCHIVED' => '已自动解除',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'ACTIVE' => AppColors.warning,
      'DISMISSED' => AppColors.textSecondary,
      'AUTO_RESOLVED' => AppColors.success,
      // Legacy
      'PENDING' => AppColors.warning,
      'ACKNOWLEDGED' => AppColors.info,
      'HANDLED' => AppColors.success,
      'ARCHIVED' => AppColors.textSecondary,
      _ => AppColors.textSecondary,
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _HealthDot extends StatelessWidget {
  const _HealthDot({required this.healthStatus});
  final String healthStatus;

  @override
  Widget build(BuildContext context) {
    final color = switch (healthStatus) {
      'CRITICAL' => AppColors.danger,
      'WARNING' => AppColors.warning,
      _ => AppColors.success,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
