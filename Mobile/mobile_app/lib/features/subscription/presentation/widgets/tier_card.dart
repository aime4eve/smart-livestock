import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class TierCard extends ConsumerWidget {
  final SubscriptionTier tier;
  final bool isCurrentPlan;
  final VoidCallback onSelect;

  const TierCard({
    super.key,
    required this.tier,
    required this.isCurrentPlan,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = SubscriptionTierInfo.all[tier]!;
    final isEnterprise = tier == SubscriptionTier.enterprise;

    return Card(
      key: Key('tier-card-${tier.name}'),
      elevation: isCurrentPlan ? 3 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: isCurrentPlan
            ? const BorderSide(color: AppColors.primary, width: 2)
            : const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  info.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (isCurrentPlan) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    key: const Key('current-plan-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: const Text(
                      '当前套餐',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isEnterprise ? '按需定价' : '¥${info.monthlyPrice.toStringAsFixed(0)}/月',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isEnterprise ? '不限牲畜数量' : '最多${info.livestockLimit}头牲畜',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (info.perUnitPrice > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '超出部分 ¥${info.perUnitPrice.toStringAsFixed(0)}/头/月',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            ...info.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        f,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: isCurrentPlan
                  ? const OutlinedButton(
                      onPressed: null,
                      child: Text('当前套餐'),
                    )
                  : ElevatedButton(
                      key: Key('select-tier-${tier.name}'),
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surfaceAlt,
                      ),
                      child: const Text('选择此套餐'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
