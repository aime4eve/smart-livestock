import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/feature_comparison_table.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/tier_card.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final asyncStatus = ref.watch(subscriptionControllerProvider);

    return Scaffold(
      key: const Key('subscription-plan-page'),
      appBar: AppBar(
        title: Text(l10n.planTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surfaceAlt,
      ),
      body: asyncStatus.when(
        data: (currentStatus) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.subSelectPlanHint,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SizedBox(height: AppSpacing.lg),
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
              const FeatureComparisonTable(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
