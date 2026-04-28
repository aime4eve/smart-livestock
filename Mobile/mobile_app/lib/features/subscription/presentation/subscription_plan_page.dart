import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/widgets/feature_comparison_table.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/widgets/tier_card.dart';

class SubscriptionPlanPage extends ConsumerWidget {
  const SubscriptionPlanPage({super.key});

  static const _tiers = [
    SubscriptionTier.basic,
    SubscriptionTier.standard,
    SubscriptionTier.premium,
    SubscriptionTier.enterprise,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = ref.watch(subscriptionControllerProvider);

    return Scaffold(
      key: const Key('subscription-plan-page'),
      appBar: AppBar(
        title: const Text('选择套餐'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surfaceAlt,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page description
            Text(
              '选择适合您牧场的套餐方案',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Subscription renewal banner
            const SizedBox(height: AppSpacing.lg),

            // Tier cards
            ...List.generate(_tiers.length, (i) {
              final tier = _tiers[i];
              final isCurrent = tier == currentStatus.tier;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < _tiers.length - 1 ? AppSpacing.md : 0,
                ),
                child: TierCard(
                  tier: tier,
                  isCurrentPlan: isCurrent,
                  onSelect: () {
                    if (!isCurrent) {
                      context.push(
                        AppRoute.checkout.path,
                        extra: {
                          'tier': tier,
                          'livestockCount': currentStatus.livestockCount,
                        },
                      );
                    }
                  },
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xl),

            // Feature comparison table
            const FeatureComparisonTable(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
