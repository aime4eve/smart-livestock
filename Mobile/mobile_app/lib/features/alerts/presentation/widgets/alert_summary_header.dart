import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_summary.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Summary header for the alert center: the three severity cells plus the
/// reconcile line. Server-side invariant: critical+warning+info == total,
/// and the reconcile line makes that visible to the user.
class AlertSummaryHeader extends StatelessWidget {
  const AlertSummaryHeader({
    super.key,
    required this.summary,
    required this.selectedSeverity,
    required this.onSeverityToggle,
  });

  final RanchAlertSummary summary;

  /// null = no severity filter; 'CRITICAL' | 'WARNING' | 'INFO' otherwise.
  final String? selectedSeverity;
  final void Function(String? severity) onSeverityToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.surfaceAlt,
      child: Column(
        children: [
          // Severity cells (tap = filter toggle)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: _SeverityCell(
                    count: summary.critical,
                    label: l10n.alertSummaryCritical,
                    dotColor: AppColors.danger,
                    selected: selectedSeverity == 'CRITICAL',
                    onTap: () => onSeverityToggle(
                        selectedSeverity == 'CRITICAL' ? null : 'CRITICAL'),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _SeverityCell(
                    count: summary.warning,
                    label: l10n.alertSummaryWarning,
                    dotColor: AppColors.warning,
                    selected: selectedSeverity == 'WARNING',
                    onTap: () => onSeverityToggle(
                        selectedSeverity == 'WARNING' ? null : 'WARNING'),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _SeverityCell(
                    count: summary.info,
                    label: l10n.alertSumInfo,
                    dotColor: AppColors.info,
                    selected: selectedSeverity == 'INFO',
                    onTap: () =>
                        onSeverityToggle(selectedSeverity == 'INFO' ? null : 'INFO'),
                  ),
                ),
              ],
            ),
          ),
          // Reconcile line: proves the numbers add up
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 5),
            child: Text(
              l10n.alertSumReconcile(
                  summary.critical, summary.warning, summary.info, summary.activeTotal),
              style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityCell extends StatelessWidget {
  const _SeverityCell({
    required this.count,
    required this.label,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final String label;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 26,
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text('$count',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: dotColor)),
            const SizedBox(width: 3),
            Text(label,
                style:
                    const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
