import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class UsageProgressBar extends ConsumerWidget {
  final int current;
  final int limit;
  final String label;

  const UsageProgressBar({
    super.key,
    required this.current,
    required this.limit,
    required this.label,
  });

  Color _progressColor() {
    if (limit <= 0) return AppColors.success;
    final ratio = current / limit;
    if (ratio >= 0.9) return AppColors.danger;
    if (ratio >= 0.7) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnlimited = limit <= 0;
    final ratio = isUnlimited ? 0.0 : (current / limit).clamp(0.0, 1.0);

    return Column(
      key: Key('usage-progress-$label'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              isUnlimited ? '无限制' : '$current / $limit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: isUnlimited ? 0 : ratio,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(_progressColor()),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
