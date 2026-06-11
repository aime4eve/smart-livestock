import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/ranch/domain/ranch_models.dart';

/// A single alert item in the drill-down list.
///
/// Visually distinguishes read vs unread alerts and shows
/// type-specific metadata (distance/direction for fence, etc.).
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onDismiss,
    this.showDismiss = false,
  });

  final RanchAlertData alert;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !alert.read;
    final severityColor = _severityColor(alert.severity);
    final typeIcon = _typeIcon(alert.type);

    return Material(
      color: isUnread
          ? severityColor.withValues(alpha: 0.04)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: Key('alert-card-${alert.id}'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isUnread
                  ? severityColor.withValues(alpha: 0.3)
                  : AppColors.border.withValues(alpha: 0.5),
              width: isUnread ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              // Unread indicator dot
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: severityColor,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 8 + AppSpacing.sm),

              // Type icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(typeIcon, color: severityColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                        color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _typeLabel(alert.type),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: severityColor,
                          ),
                        ),
                        if (alert.distance != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${alert.distance!.toStringAsFixed(0)}m',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (alert.direction != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            alert.direction!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (alert.occurredAt != null)
                          Text(
                            _formatTime(alert.occurredAt!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge or dismiss
              if (showDismiss && alert.status == 'ACTIVE')
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  tooltip: '忽略',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                )
              else if (alert.status != 'ACTIVE')
                _StatusBadge(status: alert.status),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(String severity) => switch (severity) {
    'CRITICAL' || 'HIGH' => AppColors.danger,
    'WARNING' || 'MEDIUM' => AppColors.warning,
    _ => AppColors.info,
  };

  IconData _typeIcon(String type) => switch (type) {
    'FENCE_BREACH' || 'FENCE_APPROACH' || 'ZONE_APPROACH' => Icons.fence,
    'TEMPERATURE_ABNORMAL' || 'FEVER' => Icons.thermostat,
    'DIGESTIVE_ABNORMAL' || 'BEHAVIOR_ABNORMAL' => Icons.pets,
    'ESTRUS' => Icons.favorite,
    'EPIDEMIC' => Icons.shield,
    _ => Icons.warning,
  };

  String _typeLabel(String type) => switch (type) {
    'FENCE_BREACH' => '越界',
    'FENCE_APPROACH' => '接近围栏',
    'ZONE_APPROACH' => '接近区域',
    'TEMPERATURE_ABNORMAL' || 'FEVER' => '发热',
    'DIGESTIVE_ABNORMAL' || 'BEHAVIOR_ABNORMAL' => '消化异常',
    'ESTRUS' => '发情',
    'EPIDEMIC' => '疫病',
    _ => type,
  };

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      return '${diff.inDays}天前';
    } catch (_) {
      return '';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'DISMISSED' => ('已忽略', AppColors.textSecondary),
      'AUTO_RESOLVED' => ('已自动解除', AppColors.success),
      'HANDLED' => ('已处理', AppColors.success),
      'ARCHIVED' => ('已归档', AppColors.textSecondary),
      _ => ('', AppColors.textSecondary),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}
