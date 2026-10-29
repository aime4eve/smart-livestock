import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_snooze_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/export_entitlement_card.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/feature_comparison_table.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/subscription_health_banner.dart';
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

  /// NIX-324 fidelity fix D1: the banner CTA preselects the checkout tier by
  /// state — renewal/repayment restores the paid tier kept on the
  /// subscription row (EXPIRED rows keep e.g. PREMIUM; effectiveTier is the
  /// degraded view), trial conversion recommends PREMIUM (trial rows are
  /// BASIC, prototype state 0).
  static SubscriptionTier _renewalTargetTier(
      SubscriptionTier rowTier, SubscriptionHealth health) {
    return health.healthStatus == 'TRIAL'
        ? SubscriptionTier.premium
        : rowTier;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncStatus = ref.watch(subscriptionControllerProvider);
    final asyncPlans = ref.watch(subscriptionPlansProvider);
    final planByTier = <SubscriptionTier, PlanInfo>{};
    asyncPlans.whenData(
        (plans) => planByTier.addEntries(plans.map((p) => MapEntry(p.tier, p))));

    return Scaffold(
      key: const Key('subscription-plan-page'),
      appBar: AppBar(
        title: Text(l10n.planTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surfaceAlt,
      ),
      body: asyncStatus.when(
        data: (currentStatus) {
          // NIX-334: a "remind me later" taken at the same level and period
          // end hides the banner; it lapses on its own at the next threshold
          // (14→7→3) or after a renewal moves the period end.
          final health = currentStatus.health;
          final snoozed = health != null &&
              (ref.watch(subscriptionSnoozeProvider(currentStatus.tenantId))
                          .value)
                      ?.suppresses(health, currentStatus.currentPeriodEnd) ==
                  true;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NIX-324: wall-clock health banner + export entitlement card.
                if (health != null && !snoozed) ...[
                  SubscriptionHealthBanner(
                    health: health,
                    onRenew: () => context.push(
                      AppRoute.checkout.path,
                      extra: {
                        // Restore semantics: renewal/repayment re-checks-out the
                        // paid tier the subscription row keeps; trial conversion
                        // lands on the recommended paid tier (trial rows are
                        // BASIC, prototype state 0 "转正式订阅").
                        'tier': _renewalTargetTier(currentStatus.tier, health),
                        'livestockCount': currentStatus.livestockCount,
                      },
                    ),
                    onSnooze: SubscriptionHealthBanner.showsSnooze(health)
                        ? () => ref
                            .read(subscriptionSnoozeProvider(
                                    currentStatus.tenantId)
                                .notifier)
                            .snooze(
                              level: health.level ?? 14,
                              periodEnd: currentStatus.currentPeriodEnd,
                            )
                        : null,
                  ),
                  if (health.hasExportWindow) ...[
                    const SizedBox(height: 12),
                    ExportEntitlementCard(
                      key: const Key('export-entitlement-mount'),
                      exportWindow: health.exportWindow!,
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
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
                    plan: planByTier[tier],
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
