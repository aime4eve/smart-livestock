import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/utils/currency_formatter.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class TierCard extends ConsumerWidget {
  final SubscriptionTier tier;
  final PlanInfo? plan;
  final bool isCurrentPlan;
  final VoidCallback onSelect;

  const TierCard({
    super.key,
    required this.tier,
    required this.isCurrentPlan,
    required this.onSelect,
    this.plan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final info = SubscriptionTierInfo.all[tier]!;
    final plan = this.plan;

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
                  localizedTierName(tier),
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
                    child: Text(
                      l10n.subCurrentTier,
                      style: const TextStyle(
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
              _headlinePrice(l10n, plan),
              key: const Key('tier-card-price'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _secondaryLine(l10n, plan),
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
                        localizedFeatureLabel(f),
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
                  ? OutlinedButton(
                      onPressed: null,
                      child: Text(l10n.subscriptionCurrentTier),
                    )
                  : ElevatedButton(
                      key: Key('select-tier-${tier.name}'),
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surfaceAlt,
                      ),
                      child: Text(l10n.subscriptionSelectTier),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Headline: custom pricing for ENTERPRISE, free for BASIC's zero band,
  /// otherwise the mainstream (middle) band unit price per head per month.
  String _headlinePrice(AppLocalizations l10n, PlanInfo? plan) {
    if (plan == null || plan.customPricing) return l10n.subCustomPricing;
    final bands = plan.priceBands;
    if (bands.isEmpty) return l10n.subCustomPricing;
    final band = bands.length > 1 ? bands[1] : bands.first;
    if (band.unitPriceUsdCents == 0) return l10n.subFreeTier;
    return l10n.subPerHeadMonth(formatUsdCents(band.unitPriceUsdCents));
  }

  /// Under the headline: herd cap for BASIC, the full band table for paid
  /// tiers, "unlimited" for ENTERPRISE.
  String _secondaryLine(AppLocalizations l10n, PlanInfo? plan) {
    if (plan == null) return '';
    if (plan.customPricing) return l10n.subLivestockUnlimited;
    if (plan.livestockCap > 0) return l10n.subHeadCapBounded('${plan.livestockCap}');
    if (plan.priceBands.length < 2) return '';
    return plan.priceBands
        .map((b) => l10n.subHerdBandEntry(
            b.rangeLabel(), formatUsdCents(b.unitPriceUsdCents)))
        .join(' · ');
  }
}
