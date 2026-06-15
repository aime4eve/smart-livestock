import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';

/// Prominent banner showing how many livestock have breached or are
/// approaching fence boundaries. Renders nothing when there are no alerts.
class FenceBreachBanner extends StatelessWidget {
  const FenceBreachBanner({
    super.key,
    required this.breachCount,
    required this.approachCount,
    required this.onTap,
  });

  final int breachCount;
  final int approachCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (breachCount + approachCount == 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Material(
      key: const Key('ranch-fence-breach-banner'),
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.danger, size: 22),
              const SizedBox(width: AppSpacing.sm),
              if (breachCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text(l10n.ranchFenceBreachCount(breachCount.toString()),
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              if (approachCount > 0)
                Text(l10n.ranchFenceApproachCount(approachCount.toString()),
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
