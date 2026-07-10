import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/core/l10n/l10n.dart';

/// A collapsible section showing auto-resolved alerts.
///
/// Starts collapsed. Users can expand to review historical
/// auto-resolved items.
class AutoResolvedSection extends StatefulWidget {
  const AutoResolvedSection({
    super.key,
    required this.alerts,
    this.onTapAlert,
  });

  final List<RanchAlertData> alerts;
  final ValueChanged<RanchAlertData>? onTapAlert;

  @override
  State<AutoResolvedSection> createState() => _AutoResolvedSectionState();
}

class _AutoResolvedSectionState extends State<AutoResolvedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const Key('auto-resolved-toggle'),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  L10n.instance.ranchAutoResolvedCount(widget.alerts.length.toString()),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.alerts.map((alert) => _AutoResolvedItem(
            alert: alert,
            onTap: widget.onTapAlert != null
                ? () => widget.onTapAlert!(alert)
                : null,
          )),
      ],
    );
  }
}

class _AutoResolvedItem extends StatelessWidget {
  const _AutoResolvedItem({required this.alert, this.onTap});
  final RanchAlertData alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 14, color: AppColors.success.withValues(alpha: 0.6)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                alert.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (alert.resolvedAt != null)
              Text(
                _formatTime(alert.resolvedAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      final l = L10n.instance;
      if (diff.inMinutes < 60) return l.ranchTimeMinutesAgo(diff.inMinutes);
      if (diff.inHours < 24) return l.ranchTimeHoursAgo(diff.inHours);
      return l.ranchTimeDaysAgo(diff.inDays);
    } catch (_) {
      return '';
    }
  }
}
