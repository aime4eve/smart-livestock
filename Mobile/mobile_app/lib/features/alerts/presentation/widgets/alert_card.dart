import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Rich alert card with severity bar, type icon, title, meta, and badges.
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    required this.onTap,
    this.onLongPress,
    this.isBatchMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  final AlertItem alert;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isBatchMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isResolved = alert.stage != 'active';
    final severityColor = _severityColor(alert.severity);
    final iconBgColor = _iconBgColor(alert, isResolved);
    final iconColor = _iconColor(alert, isResolved);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: alert.read
              ? Border.all(color: Colors.transparent)
              : Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Severity color bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: isResolved
                    ? _resolvedBarColor(alert).withValues(alpha: 0.3)
                    : severityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            // Batch checkbox (if in batch mode)
            if (isBatchMode)
              Padding(
                padding: const EdgeInsets.only(left: 5, top: 8),
                child: GestureDetector(
                  onTap: onSelectionToggle,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: AppColors.border, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            size: 12, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        _typeIcon(alert.type),
                        size: 14,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 7),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  alert.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                    color: isResolved
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (!alert.read && !isBatchMode)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(left: 4, top: 3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          // Meta row
                          if (alert.livestockCode != '-' ||
                              alert.fenceName != null ||
                              alert.occurredAt != null) ...[
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (alert.livestockCode != '-')
                                  Text(
                                    '#${alert.livestockCode}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                if (alert.livestockCode != '-' &&
                                    alert.fenceName != null)
                                  Text('·',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.border)),
                                if (alert.fenceName != null)
                                  Text(
                                    alert.fenceName!,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                if ((alert.livestockCode != '-' ||
                                        alert.fenceName != null) &&
                                    alert.occurredAt != null)
                                  Text('·',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.border)),
                                if (alert.occurredAt != null)
                                  Text(
                                    _formatTime(l10n, alert.occurredAt!),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          // Badges row
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              _TypeBadge(
                                type: alert.type,
                                isResolved: isResolved,
                              ),
                              _StatusTag(stage: alert.stage),
                              _SourceTag(source: alert.source),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    return switch (severity) {
      'CRITICAL' => AppColors.danger,
      'WARNING' => AppColors.warning,
      'INFO' => AppColors.info,
      _ => AppColors.warning,
    };
  }

  Color _resolvedBarColor(AlertItem alert) {
    if (alert.stage == 'auto_resolved') return AppColors.success;
    return AppColors.textSecondary;
  }

  Color _iconBgColor(AlertItem alert, bool isResolved) {
    if (isResolved) {
      if (alert.stage == 'auto_resolved') {
        return AppColors.success.withValues(alpha: 0.1);
      }
      return const Color(0xFFF0F0F0);
    }
    return switch (alert.type) {
      'FENCE_BREACH' || 'EPIDEMIC' => AppColors.danger.withValues(alpha: 0.1),
      'TEMPERATURE_ABNORMAL' ||
      'DIGESTIVE_ABNORMAL' ||
      'DEVICE_LOW_BATTERY' ||
      'DEVICE_TAMPER' =>
        AppColors.warning.withValues(alpha: 0.1),
      'ESTRUS' => AppColors.estrus.withValues(alpha: 0.1),
      'AI_ANOMALY' => AppColors.aiAnomaly.withValues(alpha: 0.1),
      'ZONE_APPROACH' => AppColors.info.withValues(alpha: 0.1),
      _ => AppColors.warning.withValues(alpha: 0.1),
    };
  }

  Color _iconColor(AlertItem alert, bool isResolved) {
    if (isResolved) {
      if (alert.stage == 'auto_resolved') return AppColors.success;
      return AppColors.textSecondary;
    }
    return switch (alert.type) {
      'FENCE_BREACH' || 'EPIDEMIC' => AppColors.danger,
      'TEMPERATURE_ABNORMAL' ||
      'DIGESTIVE_ABNORMAL' ||
      'DEVICE_LOW_BATTERY' ||
      'DEVICE_TAMPER' =>
        AppColors.warning,
      'ESTRUS' => AppColors.estrus,
      'AI_ANOMALY' => AppColors.aiAnomaly,
      'ZONE_APPROACH' => AppColors.info,
      _ => AppColors.warning,
    };
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'FENCE_BREACH' => Icons.fence,
      'FENCE_APPROACH' => Icons.warning_amber_rounded,
      'ZONE_APPROACH' => Icons.location_on,
      'TEMPERATURE_ABNORMAL' => Icons.thermostat,
      'DIGESTIVE_ABNORMAL' => Icons.pets,
      'ESTRUS' => Icons.favorite,
      'EPIDEMIC' => Icons.shield,
      'AI_ANOMALY' => Icons.psychology,
      'DEVICE_TAMPER' => Icons.sensors,
      'DEVICE_LOW_BATTERY' => Icons.battery_alert,
      _ => Icons.notifications,
    };
  }

  String _formatTime(AppLocalizations l10n, String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return l10n.alertJustNow;
      if (diff.inMinutes < 60) {
        return l10n.alertMinutesAgo(diff.inMinutes);
      }
      if (diff.inHours < 24 && now.day == dt.day) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      if (diff.inDays < 2) return l10n.alertYesterdayTime(
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}');
      return '${dt.month}${l10n.alertMonthUnit}${dt.day}${l10n.alertDayUnit}';
    } catch (_) {
      return iso;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.isResolved});
  final String type;
  final bool isResolved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (type) {
      'FENCE_BREACH' => l10n.alertTypeFenceBreach,
      'FENCE_APPROACH' => l10n.alertTypeFenceApproach,
      'ZONE_APPROACH' => l10n.alertTypeZoneApproach,
      'TEMPERATURE_ABNORMAL' => l10n.alertTypeTemperatureAbnormal,
      'DIGESTIVE_ABNORMAL' => l10n.alertTypeDigestiveAbnormal,
      'ESTRUS' => l10n.alertTypeEstrus,
      'EPIDEMIC' => l10n.alertTypeEpidemic,
      'AI_ANOMALY' => l10n.alertTypeAiAnomaly,
      'DEVICE_TAMPER' => l10n.alertTypeDeviceTamper,
      'DEVICE_LOW_BATTERY' => l10n.alertTypeDeviceLowBattery,
      _ => type,
    };
    final (bg, fg) = isResolved
        ? (AppColors.success.withValues(alpha: 0.1), AppColors.success)
        : switch (type) {
            'FENCE_BREACH' || 'EPIDEMIC' => (
                AppColors.danger.withValues(alpha: 0.1),
                AppColors.danger
              ),
            'TEMPERATURE_ABNORMAL' || 'DIGESTIVE_ABNORMAL' ||
            'DEVICE_LOW_BATTERY' || 'DEVICE_TAMPER' || 'FENCE_APPROACH' => (
                AppColors.warning.withValues(alpha: 0.1),
                const Color(0xFF92580E)
              ),
            'ESTRUS' => (
                AppColors.estrus.withValues(alpha: 0.1),
                AppColors.estrus
              ),
            'AI_ANOMALY' => (
                AppColors.aiAnomaly.withValues(alpha: 0.1),
                AppColors.aiAnomaly
              ),
            'ZONE_APPROACH' => (
                AppColors.info.withValues(alpha: 0.1),
                AppColors.info
              ),
            _ => (AppColors.warning.withValues(alpha: 0.1),
                const Color(0xFF92580E)),
          };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.stage});
  final String stage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, bg, fg) = switch (stage) {
      'active' => (
          l10n.alertStatusActive,
          const Color(0xFFFFF3CD),
          const Color(0xFF92580E)
        ),
      'dismissed' => (
          l10n.alertStatusDismissed,
          const Color(0xFFE8E8E8),
          AppColors.textSecondary
        ),
      'auto_resolved' => (
          l10n.alertStatusAutoResolved,
          AppColors.success.withValues(alpha: 0.1),
          AppColors.success
        ),
      _ => (stage, AppColors.border, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRule = source.toUpperCase() == 'RULE';
    final label = isRule ? l10n.alertSourceRule : l10n.alertSourceAi;
    final (bg, fg) = isRule
        ? (const Color(0xFFE8F0E5), AppColors.primaryDark)
        : (AppColors.aiAnomaly.withValues(alpha: 0.06), AppColors.aiAnomaly);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
