import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

/// A dashboard summary card for a category (fence or health).
///
/// Shows an icon, title, alert count, and a subtitle metric.
/// When [alertCount] is 0 the card still renders but with a muted style.
class StatusDashboardCard extends StatelessWidget {
  const StatusDashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.alertCount,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int alertCount;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAlert = alertCount > 0;

    return Material(
      color: hasAlert
          ? accentColor.withValues(alpha: 0.06)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('dashboard-card-$title'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasAlert
                  ? accentColor.withValues(alpha: 0.4)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const Spacer(),
                  if (hasAlert)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$alertCount',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: hasAlert ? accentColor : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
