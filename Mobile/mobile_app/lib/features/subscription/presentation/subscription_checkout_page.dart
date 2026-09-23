import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/utils/currency_formatter.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';

class SubscriptionCheckoutPage extends ConsumerStatefulWidget {
  final SubscriptionTier tier;
  final int livestockCount;

  const SubscriptionCheckoutPage({
    super.key,
    required this.tier,
    required this.livestockCount,
  });

  @override
  ConsumerState<SubscriptionCheckoutPage> createState() =>
      _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState
    extends ConsumerState<SubscriptionCheckoutPage> {
  late int _livestockCount;
  final _countController = TextEditingController();
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _livestockCount = widget.livestockCount;
    _countController.text = _livestockCount.toString();
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tierInfo = SubscriptionTierInfo.all[widget.tier]!;
    final theme = Theme.of(context);
    final plan = ref
        .watch(subscriptionPlansProvider)
        .whenData((plans) => plans.where((p) => p.tier == widget.tier).firstOrNull);
    final feeCents = plan.value?.monthlyFeeUsdCents(_livestockCount);

    return Scaffold(
      key: const Key('subscription-checkout-page'),
      appBar: AppBar(
        title: Text(l10n.checkoutTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surfaceAlt,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected tier info
            Card(
              key: const Key('checkout-tier-card'),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                side: const BorderSide(color: AppColors.primary, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.subSelectedPlan,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      tierInfo.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...tierInfo.features.take(5).map(
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
                                Text(
                                  f,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (tierInfo.features.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          l10n.subFeatureCountSuffix('${tierInfo.features.length}'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Livestock count input
            Text(
              l10n.subLivestockCountLabel,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('livestock-count-input'),
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixText: l10n.checkoutHeadUnit,
                hintText: l10n.checkoutLivestockCount,
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0) {
                  setState(() => _livestockCount = parsed);
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Price breakdown
            Card(
              key: const Key('checkout-price-card'),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.subFeeBreakdown,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (plan.value == null || plan.value!.customPricing) ...[
                      Text(
                        l10n.subCustomPricing,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ] else ...[
                      _priceRow(
                        context,
                        l10n.subUnitPriceLabel,
                        l10n.subPerHeadMonth(
                            formatUsdCents(plan.value!.bandFor(_livestockCount).unitPriceUsdCents)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _priceRow(
                        context,
                        l10n.subMonthlyFeeRow(
                          '$_livestockCount',
                          formatUsdCents(plan.value!.bandFor(_livestockCount).unitPriceUsdCents),
                        ),
                        feeCents == null ? '—' : formatUsdCents(feeCents),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      _priceRow(
                        context,
                        l10n.subTotal,
                        feeCents == null ? '—' : formatUsdCents(feeCents),
                        bold: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const Key('pay-button'),
                onPressed: _paying ? null : () async {
                  setState(() => _paying = true);
                  final ok = await ref
                      .read(subscriptionControllerProvider.notifier)
                      .checkout(
                        tier: widget.tier.name,
                        livestockCount: _livestockCount,
                      );
                  if (!mounted || !context.mounted) return;
                  setState(() => _paying = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? l10n.subSubscribeSuccess(
                                localizedTierName(tierInfo.tier))
                            : l10n.subSubscribeFailed,
                      ),
                    ),
                  );
                  // 订购成功后清栈回到"我的"，避免用户停在套餐页找不到返回路径
                  if (ok) context.go(AppRoute.mine.path);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surfaceAlt,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                ),
                child: _paying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.surfaceAlt),
                      )
                    : Text(
                        l10n.subConfirmPay(feeCents == null
                            ? l10n.subCustomPricing
                            : formatUsdCents(feeCents)),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
        ),
      ],
    );
  }
}
