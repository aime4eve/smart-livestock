import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';

class HighfiStatTile extends StatelessWidget {
  const HighfiStatTile({
    super.key,
    required this.title,
    required this.value,
    this.caption,
    this.trend,
    this.onTap,
    this.valueColor,
  });

  final String title;
  final String value;
  final String? caption;
  final String? trend;
  final VoidCallback? onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return HighfiCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style: valueColor != null
                      ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: valueColor,
                        )
                      : Theme.of(context).textTheme.headlineSmall,
                ),
                if (trend != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    trend!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
                if (caption != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(caption!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
