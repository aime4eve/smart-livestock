import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Top summary strip with critical / warning / pending counts.
/// Tapping a count toggles the severity filter.
class AlertSummaryStrip extends StatelessWidget {
  const AlertSummaryStrip({
    super.key,
    required this.criticalCount,
    required this.warningCount,
    required this.pendingCount,
   required this.activeFilter,
   required this.onTap,
    required this.onPendingTap,
 });

 final int criticalCount;
 final int warningCount;
 final int pendingCount;
 final String? activeFilter; // null | 'CRITICAL' | 'WARNING' | null(pending=active)
 final void Function(String? severity) onTap;
 final VoidCallback onPendingTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              count: criticalCount,
              label: l10n.alertSummaryCritical,
              color: AppColors.danger,
              isSelected: activeFilter == 'CRITICAL',
              onTap: () => onTap(activeFilter == 'CRITICAL' ? null : 'CRITICAL'),
            ),
          ),
          Expanded(
            child: _SummaryItem(
              count: warningCount,
              label: l10n.alertSummaryWarning,
              color: AppColors.warning,
              isSelected: activeFilter == 'WARNING',
              onTap: () => onTap(activeFilter == 'WARNING' ? null : 'WARNING'),
            ),
          ),
          Expanded(
            child: _SummaryItem(
              count: pendingCount,
              label: l10n.alertSummaryPending,
              color: AppColors.primary,
              isSelected: false,
              onTap: onPendingTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.count,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final int count;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: isSelected ? color : (count == 0 ? AppColors.success : color),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
