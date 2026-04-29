import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';

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

  double get _tierFee {
    final info = SubscriptionTierInfo.all[widget.tier]!;
    return info.monthlyPrice < 0 ? 0.0 : info.monthlyPrice;
  }

  int get _excessCount {
    final info = SubscriptionTierInfo.all[widget.tier]!;
    final limit = info.livestockLimit < 0 ? _livestockCount : info.livestockLimit;
    return _livestockCount > limit ? _livestockCount - limit : 0;
  }

  double get _deviceFee {
    final info = SubscriptionTierInfo.all[widget.tier]!;
    return _excessCount * info.perUnitPrice;
  }

  double get _total => _tierFee + _deviceFee;

  @override
  Widget build(BuildContext context) {
    final tierInfo = SubscriptionTierInfo.all[widget.tier]!;
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('subscription-checkout-page'),
      appBar: AppBar(
        title: const Text('确认支付'),
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
                      '已选择套餐',
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
                          '等${tierInfo.features.length}项功能',
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
              '牲畜数量',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('livestock-count-input'),
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: '头',
                hintText: '请输入牲畜数量',
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
                      '费用明细',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _priceRow(context, '套餐费（${tierInfo.name}）', _tierFee),
                    const SizedBox(height: AppSpacing.sm),
                    _priceRow(
                      context,
                      _excessCount > 0
                          ? '超出设备费（超出$_excessCount头 × ¥${tierInfo.perUnitPrice.toStringAsFixed(0)}/头）'
                          : '超出设备费（在${tierInfo.livestockLimit < 0 ? "不限" : "${tierInfo.livestockLimit}头"}额度内）',
                      _deviceFee,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    _priceRow(context, '合计', _total, bold: true),
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
                onPressed: () {
                  ref
                      .read(subscriptionControllerProvider.notifier)
                      .checkout(widget.tier, _livestockCount);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '已成功订阅${tierInfo.name}',
                      ),
                    ),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surfaceAlt,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                ),
                child: Text(
                  '确认支付 ¥${_total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    double amount, {
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
          '¥${amount.toStringAsFixed(2)} 元',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
        ),
      ],
    );
  }
}
