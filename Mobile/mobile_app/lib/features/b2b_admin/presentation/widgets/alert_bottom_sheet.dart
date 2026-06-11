import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class B2bAlertBottomSheet extends StatelessWidget {
  const B2bAlertBottomSheet({
    super.key,
    required this.alerts,
    required this.totalCount,
  });

  final List<Map<String, dynamic>> alerts;
  final int totalCount;

  static void show(
    BuildContext context,
    List<Map<String, dynamic>> alerts,
    int totalCount,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => B2bAlertBottomSheet(alerts: alerts, totalCount: totalCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.alertSummaryTitle, style: Theme.of(context).textTheme.titleMedium),
              Text(l10n.alertSummaryCount(totalCount.toString()), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...alerts.map((alert) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              Icons.warning_amber,
              color: (alert['type'] == 'critical')
                  ? Theme.of(context).colorScheme.error
                  : Colors.orange,
              size: 20,
            ),
            title: Text(alert['message'] as String? ?? ''),
            subtitle: Text(
              '${alert['farmName'] ?? ''} · ${alert['createdAt'] ?? ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(l10n.alertsNoAlerts)),
            ),
        ],
      ),
    );
  }
}
