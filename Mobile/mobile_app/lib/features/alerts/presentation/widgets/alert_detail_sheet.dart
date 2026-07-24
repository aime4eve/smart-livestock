import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/permissions/role_permission.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/alerts_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/widgets/trajectory_sheet.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Shows the alert detail bottom sheet.
Future<void> showAlertDetailSheet(
  BuildContext context, {
  required AlertItem alert,
  required UserRole role,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AlertDetailSheet(
      alert: alert,
      role: role,
    ),
  );
}

class AlertDetailSheet extends ConsumerStatefulWidget {
  const AlertDetailSheet({
    super.key,
    required this.alert,
    required this.role,
  });

  final AlertItem alert;
  final UserRole role;

  @override
  ConsumerState<AlertDetailSheet> createState() => _AlertDetailSheetState();
}

class _AlertDetailSheetState extends ConsumerState<AlertDetailSheet> {
  late AlertItem _alert;


  @override
  void initState() {
    super.initState();
    _alert = widget.alert;
    _loadDetail();
  }

  Future<void> _loadDetail() async {

    try {
      final detail = await ref
          .read(alertsRepositoryProvider)
          .loadDetail(widget.alert.id);
      {
        setState(() {
          _alert = AlertItem(
            id: detail.id,
            title: detail.title,
            subtitle: detail.subtitle,
            priority: detail.priority,
            type: detail.type,
            stage: detail.stage,
            livestockCode: detail.livestockCode,
            livestockId: detail.livestockId,
            source: detail.source,
            severity: detail.severity,
            read: detail.read,
            occurredAt: detail.occurredAt,
            resolvedAt: detail.resolvedAt,
            fenceName: detail.fenceName,
            resolvedType: detail.resolvedType,
          );
        });
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -4),
            blurRadius: 24,
            color: Color.fromRGBO(38, 49, 38, 0.15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle + close button
          _buildHeader(l10n),
          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md - 2, vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescription(l10n),
                  const SizedBox(height: 10),
                  _buildMetadataGrid(l10n),
                  const SizedBox(height: 10),
                  _buildTimeline(l10n),
                ],
              ),
            ),
          ),
          // Action buttons
          _buildActions(l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final (iconBg, iconFg) = _iconColors();
    return Stack(
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                children: [
                  // Large type icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_typeIcon(), size: 24, color: iconFg),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    _alert.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Badges
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    alignment: WrapAlignment.center,
                    children: [
                      _DetailBadge(
                        label: _typeLabel(l10n),
                        bg: _typeBadgeBg(),
                        fg: _typeBadgeFg(),
                      ),
                      _DetailBadge(
                        label: _severityLabel(l10n),
                        bg: _severityBadgeBg(),
                        fg: _severityBadgeFg(),
                      ),
                      _DetailBadge(
                        label: _statusLabel(l10n),
                        bg: _statusBadgeBg(),
                        fg: _statusBadgeFg(),
                      ),
                      _DetailBadge(
                        label: _sourceLabel(l10n),
                        bg: _sourceBadgeBg(),
                        fg: _sourceBadgeFg(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
          ],
        ),
        // Close button
        Positioned(
          top: 10,
          right: 14,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _alert.title,
        style: const TextStyle(
          fontSize: 11,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMetadataGrid(AppLocalizations l10n) {
    final fields = <_MetadataField>[
      _MetadataField(
       l10n.alertDetailOccurredAt,
       _formatTime(l10n, _alert.occurredAt) ?? '-',
      ),
      _MetadataField(
        l10n.alertDetailLivestockCode,
        _alert.livestockCode,
      ),
      _MetadataField(
        l10n.alertDetailFence,
        _alert.fenceName ?? '-',
      ),
      _MetadataField(
        l10n.alertDetailSeverity,
        _severityLabel(l10n),
        valueColor: _severityBadgeFg(),
      ),
      _MetadataField(
        l10n.alertDetailStatus,
        _statusLabel(l10n),
      ),
      _MetadataField(
        l10n.alertDetailSource,
        _sourceLabel(l10n),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < fields.length; i += 2)
          Padding(
            padding: EdgeInsets.only(
              bottom: i + 2 < fields.length ? 8 : 0,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _MetadataItem(field: fields[i])),
                  const SizedBox(width: 12),
                  if (i + 1 < fields.length)
                    Expanded(child: _MetadataItem(field: fields[i + 1]))
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeline(AppLocalizations l10n) {
    final entries = _buildTimelineEntries(l10n);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 10),
              const SizedBox(width: 4),
              Text(
                l10n.alertDetailTimeline,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: entry.done
                          ? AppColors.success
                          : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.label,
                      style: TextStyle(
                        fontSize: 9,
                        color: entry.done
                            ? AppColors.textSecondary
                            : AppColors.border,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    final isActive = _alert.stage == 'active';
    final canDismiss = RolePermission.canHandleAlert(widget.role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          // Locate
          _ActionButton(
            label: l10n.alertActionLocate,
            icon: Icons.location_on,
            bgColor: AppColors.info,
            fgColor: Colors.white,
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoute.ranch.path);
            },
          ),
          // Trajectory
          if (_alert.livestockId != null)
            _ActionButton(
              label: l10n.alertActionTrajectory,
              icon: Icons.show_chart,
              bgColor: AppColors.aiAnomaly.withValues(alpha: 0.1),
              fgColor: AppColors.aiAnomaly,
              onTap: () {
                Navigator.of(context).pop();
                showTrajectorySheet(
                  context,
                  _alert.livestockId!,
                  livestockCode: _alert.livestockCode,
                );
              },
            ),
          // Mark read (only if active and unread)
          if (isActive && !_alert.read)
            _ActionButton(
              label: l10n.alertActionMarkRead,
              icon: Icons.check,
              bgColor: AppColors.primarySoft,
              fgColor: AppColors.primaryDark,
              onTap: () {
                ref.read(alertsControllerProvider.notifier).markRead(_alert.id);
                Navigator.of(context).pop();
              },
            ),
          // Dismiss (only active + owner/b2b_admin)
          if (isActive && canDismiss)
            _ActionButton(
              label: l10n.alertActionDismiss,
              icon: Icons.block,
              bgColor: AppColors.danger.withValues(alpha: 0.1),
              fgColor: AppColors.danger,
              onTap: () {
                ref
                    .read(alertsControllerProvider.notifier)
                    .dismiss(_alert.id);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  // ── Timeline entries ──

  List<_TimelineEntry> _buildTimelineEntries(AppLocalizations l10n) {
    final entries = <_TimelineEntry>[];

    // Triggered event
    entries.add(_TimelineEntry(
      label:
          '${_formatTime(l10n, _alert.occurredAt) ?? ''} ${_triggerLabel(l10n)}',
      done: true,
    ));

    if (_alert.stage == 'active') {
      entries.add(_TimelineEntry(
        label: l10n.alertDetailTimelineWaiting,
        done: false,
      ));
    } else if (_alert.stage == 'dismissed') {
      entries.add(_TimelineEntry(
        label:
            '${_formatTime(l10n, _alert.resolvedAt) ?? ''} ${l10n.alertDetailTimelineDismissed}',
        done: true,
      ));
    } else if (_alert.stage == 'auto_resolved') {
      entries.add(_TimelineEntry(
        label:
            '${_formatTime(l10n, _alert.resolvedAt) ?? ''} ${l10n.alertDetailTimelineResolved}',
        done: true,
      ));
    }

    return entries;
  }

  String _triggerLabel(AppLocalizations l10n) {
    return _alert.source.toUpperCase() == 'AI'
        ? l10n.alertSourceAi
        : l10n.alertDetailTimelineTriggered;
  }

  // ── Type / severity / status / source helpers ──

  IconData _typeIcon() {
    return switch (_alert.type) {
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

  (Color, Color) _iconColors() {
    final isResolved = _alert.stage != 'active';
    if (isResolved) {
      if (_alert.stage == 'auto_resolved') {
        return (AppColors.success.withValues(alpha: 0.1), AppColors.success);
      }
      return (const Color(0xFFF0F0F0), AppColors.textSecondary);
    }
    return switch (_alert.type) {
      'FENCE_BREACH' || 'EPIDEMIC' => (
          AppColors.danger.withValues(alpha: 0.1),
          AppColors.danger
        ),
      'TEMPERATURE_ABNORMAL' || 'DIGESTIVE_ABNORMAL' ||
      'DEVICE_LOW_BATTERY' || 'DEVICE_TAMPER' || 'FENCE_APPROACH' => (
          AppColors.warning.withValues(alpha: 0.1),
          AppColors.warning
        ),
      'ESTRUS' => (AppColors.estrus.withValues(alpha: 0.1), AppColors.estrus),
      'AI_ANOMALY' => (AppColors.aiAnomaly.withValues(alpha: 0.1), AppColors.aiAnomaly),
      'ZONE_APPROACH' => (AppColors.info.withValues(alpha: 0.1), AppColors.info),
      _ => (AppColors.warning.withValues(alpha: 0.1), AppColors.warning),
    };
  }

  String _typeLabel(AppLocalizations l10n) {
    return switch (_alert.type) {
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
      _ => _alert.type,
    };
  }

  String _severityLabel(AppLocalizations l10n) {
    return switch (_alert.severity) {
      'CRITICAL' => l10n.alertSeverityCritical,
      'WARNING' => l10n.alertSeverityWarning,
      'INFO' => l10n.alertSeverityInfo,
      _ => _alert.severity,
    };
  }

  String _statusLabel(AppLocalizations l10n) {
    return switch (_alert.stage) {
      'active' => l10n.alertStatusActive,
      'dismissed' => l10n.alertStatusDismissed,
      'auto_resolved' => l10n.alertStatusAutoResolved,
      _ => _alert.stage,
    };
  }

  String _sourceLabel(AppLocalizations l10n) {
    return _alert.source.toUpperCase() == 'AI'
        ? l10n.alertSourceAi
        : l10n.alertSourceRule;
  }

  Color _typeBadgeBg() {
    final isResolved = _alert.stage != 'active';
    if (isResolved) return AppColors.success.withValues(alpha: 0.1);
    return switch (_alert.type) {
      'FENCE_BREACH' || 'EPIDEMIC' => AppColors.danger.withValues(alpha: 0.1),
      'TEMPERATURE_ABNORMAL' || 'DIGESTIVE_ABNORMAL' ||
      'DEVICE_LOW_BATTERY' || 'DEVICE_TAMPER' || 'FENCE_APPROACH' =>
        AppColors.warning.withValues(alpha: 0.1),
      'ESTRUS' => AppColors.estrus.withValues(alpha: 0.1),
      'AI_ANOMALY' => AppColors.aiAnomaly.withValues(alpha: 0.1),
      'ZONE_APPROACH' => AppColors.info.withValues(alpha: 0.1),
      _ => AppColors.warning.withValues(alpha: 0.1),
    };
  }

  Color _typeBadgeFg() {
    final isResolved = _alert.stage != 'active';
    if (isResolved) return AppColors.success;
    return switch (_alert.type) {
      'FENCE_BREACH' || 'EPIDEMIC' => AppColors.danger,
      'TEMPERATURE_ABNORMAL' || 'DIGESTIVE_ABNORMAL' ||
      'DEVICE_LOW_BATTERY' || 'DEVICE_TAMPER' || 'FENCE_APPROACH' =>
        const Color(0xFF92580E),
      'ESTRUS' => AppColors.estrus,
      'AI_ANOMALY' => AppColors.aiAnomaly,
      'ZONE_APPROACH' => AppColors.info,
      _ => const Color(0xFF92580E),
    };
  }

  Color _severityBadgeBg() {
    return switch (_alert.severity) {
      'CRITICAL' => AppColors.danger.withValues(alpha: 0.1),
      'WARNING' => const Color(0xFFFBF0E0),
      _ => AppColors.info.withValues(alpha: 0.1),
    };
  }

  Color _severityBadgeFg() {
    return switch (_alert.severity) {
      'CRITICAL' => AppColors.danger,
      'WARNING' => const Color(0xFF92580E),
      _ => AppColors.info,
    };
  }

  Color _statusBadgeBg() {
    return switch (_alert.stage) {
      'active' => const Color(0xFFFFF3CD),
      'dismissed' => const Color(0xFFE8E8E8),
      'auto_resolved' => AppColors.success.withValues(alpha: 0.1),
      _ => AppColors.border,
    };
  }

  Color _statusBadgeFg() {
    return switch (_alert.stage) {
      'active' => const Color(0xFF92580E),
      'dismissed' => AppColors.textSecondary,
      'auto_resolved' => AppColors.success,
      _ => AppColors.textSecondary,
    };
  }

  Color _sourceBadgeBg() {
    return _alert.source.toUpperCase() == 'AI'
        ? AppColors.aiAnomaly.withValues(alpha: 0.06)
        : const Color(0xFFE8F0E5);
  }

  Color _sourceBadgeFg() {
    return _alert.source.toUpperCase() == 'AI'
        ? AppColors.aiAnomaly
        : AppColors.primaryDark;
  }

  String? _formatTime(AppLocalizations l10n, String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final now = DateTime.now();
      if (now.day == dt.day && now.month == dt.month) {
        return '$h:$m';
      }
      return '${dt.month}/${dt.day} $h:$m';
    } catch (_) {
      return iso;
    }
  }
}

// ── Helper widgets ──

class _MetadataField {
  const _MetadataField(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({required this.field});
  final _MetadataField field;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          field.value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: field.valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({
    required this.label,
    required this.bg,
    required this.fg,
  });
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
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

class _TimelineEntry {
  const _TimelineEntry({required this.label, required this.done});
  final String label;
  final bool done;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 50),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
