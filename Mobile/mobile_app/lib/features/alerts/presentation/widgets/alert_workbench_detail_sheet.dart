import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/permissions/role_permission.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_workbench.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

Future<void> showAlertWorkbenchDetailSheet(
  BuildContext context, {
  required WorkbenchItem item,
  required UserRole role,
  required Future<void> Function(WorkbenchItem item) onMarkRead,
  required Future<void> Function(WorkbenchItem item) onDismiss,
  required void Function(String route) onNavigate,
  required void Function(WorkbenchItem item) onTrajectory,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AlertWorkbenchDetailSheet(
      item: item,
      role: role,
      onMarkRead: onMarkRead,
      onDismiss: onDismiss,
      onNavigate: onNavigate,
      onTrajectory: onTrajectory,
    ),
  );
}

class AlertWorkbenchDetailSheet extends StatelessWidget {
  const AlertWorkbenchDetailSheet({
    super.key,
    required this.item,
    required this.role,
    required this.onMarkRead,
    required this.onDismiss,
    required this.onNavigate,
    required this.onTrajectory,
  });

  final WorkbenchItem item;
  final UserRole role;
  final Future<void> Function(WorkbenchItem item) onMarkRead;
  final Future<void> Function(WorkbenchItem item) onDismiss;
  final void Function(String route) onNavigate;
  final void Function(WorkbenchItem item) onTrajectory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = _accent();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
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
          Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 7,
                right: 10,
                child: _CloseButton(onTap: () => Navigator.of(context).pop()),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Hero(item: item, accent: accent),
                  const SizedBox(height: 8),
                  _Verdict(item: item),
                  const SizedBox(height: 8),
                  _Section(
                    title: l10n.workbenchKeyMetrics,
                    trailing: _time(item.occurredAt),
                    child: _Metrics(item: item),
                  ),
                  const SizedBox(height: 8),
                  _Section(
                    title: l10n.workbenchEvidence,
                    count: item.reasons.length,
                    trailing: l10n.workbenchTechnicalEvidence,
                    child: Column(
                      children: [
                        for (var i = 0; i < item.reasons.length; i++)
                          _EvidenceRow(
                            reason: item.reasons[i],
                            showTopBorder: i > 0,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Section(
                    title: l10n.workbenchLifecycle,
                    child: _Lifecycle(item: item),
                  ),
                ],
              ),
            ),
          ),
          _ActionBar(
            item: item,
            role: role,
            onMarkRead: (target) async {
              await onMarkRead(item);
              if (context.mounted) Navigator.of(context).pop();
            },
            onDismiss: (target) async {
              await onDismiss(item);
              if (context.mounted) Navigator.of(context).pop();
            },
            onNavigate: onNavigate,
            onTrajectory: onTrajectory,
          ),
        ],
      ),
    );
  }

  Color _accent() => switch (item.bucket) {
    'immediate' => AppColors.danger,
    'field' => AppColors.warning,
    'observe' => AppColors.info,
    _ => AppColors.success,
  };

  String _time(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: Icon(Icons.close, size: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.item, required this.accent});

  final WorkbenchItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 30, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_icon, size: 16, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _kindLabel(l10n),
                      style: const TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.asset.name}${item.asset.subtitle.isEmpty ? '' : ' · ${item.asset.subtitle}'}',
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _bucketLabel(l10n),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.unread ? l10n.workbenchUnread : item.severity,
                    style: const TextStyle(
                      fontSize: 7.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.workbenchNow,
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.reasons.firstOrNull?.message ?? item.title,
                    style: const TextStyle(
                      fontSize: 9,
                      height: 1.35,
                      color: AppColors.textPrimary,
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

  IconData get _icon => switch (item.asset.kind) {
    'fence' => Icons.fence,
    'device' => Icons.sensors,
    'herd' => Icons.shield_outlined,
    'livestock' => Icons.pets,
    _ => Icons.notifications,
  };

  String _kindLabel(AppLocalizations l10n) => switch (item.asset.kind) {
    'fence' => l10n.workbenchFence,
    'device' => l10n.workbenchDevice,
    'herd' => l10n.workbenchHerd,
    _ => l10n.workbenchLivestock,
  };

  String _bucketLabel(AppLocalizations l10n) => switch (item.bucket) {
    'immediate' => l10n.workbenchImmediate,
    'field' => l10n.workbenchField,
    'observe' => l10n.workbenchObserve,
    _ => l10n.workbenchResolved,
  };
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.item});

  final WorkbenchItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(36, 79, 45, 0.16),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.workbenchNextStep,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _recommendation(l10n),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.reasons.firstOrNull?.message ?? item.subtitle,
            style: TextStyle(
              fontSize: 8.5,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }

  String _recommendation(AppLocalizations l10n) {
    if (item.bucket == 'resolved') return l10n.workbenchRecommendResolved;
    return switch (item.asset.kind) {
      'fence' => l10n.workbenchRecommendFence,
      'device' => l10n.workbenchRecommendDevice,
      'herd' => l10n.workbenchRecommendHerd,
      _ => l10n.workbenchRecommendLivestock,
    };
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.count,
    this.trailing,
  });

  final String title;
  final Widget child;
  final int? count;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const Spacer(),
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 7.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.item});

  final WorkbenchItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = [
      (
        l10n.workbenchAffected,
        item.reasons.length.toString(),
        '',
        item.bucket == 'immediate' ? AppColors.danger : AppColors.textPrimary,
      ),
      (
        l10n.workbenchSeverity,
        item.severity,
        '',
        item.severity == 'CRITICAL'
            ? AppColors.danger
            : item.severity == 'WARNING'
            ? AppColors.warning
            : AppColors.textPrimary,
      ),
      (
        item.ai == null ? l10n.workbenchFirstReport : l10n.workbenchAiScore,
        item.ai == null
            ? _date(item.occurredAt)
            : item.ai!.score.toStringAsFixed(2),
        '',
        item.ai == null ? AppColors.textPrimary : AppColors.info,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metrics[i].$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metrics[i].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: metrics[i].$4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    return '${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.reason, required this.showTopBorder});

  final WorkbenchReason reason;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final color = switch (reason.severity) {
      'CRITICAL' => AppColors.danger,
      'WARNING' => AppColors.warning,
      _ => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: showTopBorder
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0ECE1))),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reason.message,
              style: const TextStyle(
                fontSize: 9,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (reason.occurredAt != null)
            Text(
              _time(reason.occurredAt!),
              style: const TextStyle(
                fontSize: 7.5,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _Lifecycle extends StatelessWidget {
  const _Lifecycle({required this.item});

  final WorkbenchItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = item.isResolved
        ? (item.resolvedType ?? l10n.ranchAlertStatusAutoResolved)
        : l10n.ranchAlertStatusActive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _step(
          l10n.alertDetailTimelineTriggered,
          _date(item.occurredAt),
          AppColors.info,
        ),
        _step(
          current,
          '',
          item.isResolved ? AppColors.success : AppColors.danger,
          currentStep: true,
        ),
        if (item.resolvedAt != null)
          _step(
            l10n.workbenchResolvedAt,
            _date(item.resolvedAt),
            AppColors.success,
          ),
      ],
    );
  }

  Widget _step(
    String title,
    String time,
    Color color, {
    bool currentStep = false,
  }) {
    return Container(
      margin: currentStep ? const EdgeInsets.only(left: -6) : EdgeInsets.zero,
      padding: EdgeInsets.symmetric(
        vertical: 5,
        horizontal: currentStep ? 6 : 0,
      ),
      decoration: currentStep
          ? BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(7),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: currentStep ? color : AppColors.textPrimary,
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 7.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    return '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.item,
    required this.role,
    required this.onMarkRead,
    required this.onDismiss,
    required this.onNavigate,
    required this.onTrajectory,
  });

  final WorkbenchItem item;
  final UserRole role;
  final Future<void> Function(WorkbenchItem item) onMarkRead;
  final Future<void> Function(WorkbenchItem item) onDismiss;
  final void Function(String route) onNavigate;
  final void Function(WorkbenchItem item) onTrajectory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canDismiss = RolePermission.canHandleAlert(role) && !item.isResolved;
    final (primaryLabel, primaryRoute) = _primaryAction(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _button(
              context,
              label: primaryLabel,
              color: AppColors.primary,
              foreground: Colors.white,
              onTap: primaryRoute == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onNavigate(primaryRoute);
                    },
            ),
          ),
          if (_canTrajectory) ...[
            const SizedBox(width: 5),
            Expanded(
              flex: 2,
              child: _button(
                context,
                label: l10n.workbenchActionTrajectory,
                color: AppColors.surfaceAlt,
                foreground: AppColors.textPrimary,
                border: true,
                onTap: () {
                  Navigator.of(context).pop();
                  onTrajectory(item);
                },
              ),
            ),
          ],
          if (!item.isResolved) ...[
            const SizedBox(width: 5),
            Expanded(
              flex: 2,
              child: _button(
                context,
                label: l10n.workbenchActionMarkRead,
                color: AppColors.surfaceAlt,
                foreground: AppColors.textPrimary,
                border: true,
                onTap: item.unread ? () => onMarkRead(item) : null,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 2,
              child: _button(
                context,
                label: l10n.workbenchActionProcess,
                color: AppColors.danger,
                foreground: Colors.white,
                onTap: canDismiss ? () => onDismiss(item) : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _button(
    BuildContext context, {
    required String label,
    required Color color,
    required Color foreground,
    required VoidCallback? onTap,
    bool border = false,
  }) {
    return SizedBox(
      height: 32,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: border
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: foreground,
          ),
        ),
      ),
    );
  }

  bool get _canTrajectory =>
      item.asset.kind == 'livestock' &&
      item.reasons.any(
        (reason) =>
            reason.type != 'DEVICE_TAMPER' &&
            reason.type != 'DEVICE_LOW_BATTERY' &&
            reason.type != 'DEVICE_OFFLINE',
      );

  (String, String?) _primaryAction(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (item.isResolved) {
      return (
        l10n.workbenchActionLivestock,
        item.asset.kind == 'livestock'
            ? '/livestock/${item.asset.id}?section=health'
            : null,
      );
    }
    return switch (item.asset.kind) {
      'fence' => (
        l10n.workbenchActionMap,
        '${AppRoute.ranch.path}?tab=fence&fenceId=${item.asset.id}',
      ),
      'device' => (
        l10n.workbenchActionDevice,
        '/devices?deviceId=${item.asset.id}',
      ),
      'herd' => (l10n.livestockListTitle, AppRoute.livestockList.path),
      _ => (
        l10n.workbenchActionLivestock,
        '/livestock/${item.asset.id}?section=health',
      ),
    };
  }
}
