import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/revenue/presentation/revenue_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';

class RevenuePage extends ConsumerWidget {
  const RevenuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(revenueControllerProvider);
    final controller = ref.read(revenueControllerProvider.notifier);

    return SingleChildScrollView(
      key: const Key('page-revenue'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '对账看板',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '查看各周期分润对账数据',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (data.viewState == ViewState.normal)
            ...data.periods.map((period) {
              final isConfirmed = period.status == 'confirmed';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: HighfiCard(
                  key: Key('period-${period.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            period.periodLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Icon(
                            isConfirmed
                                ? Icons.check_circle
                                : Icons.pending_outlined,
                            color: isConfirmed
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('总收入: ${period.totalRevenue.toStringAsFixed(2)}'),
                      Text(
                        '平台分润: ${period.platformShare.toStringAsFixed(2)}',
                      ),
                      Text(
                        '合作方分润: ${period.partnerShare.toStringAsFixed(2)}',
                      ),
                      Text('状态: ${isConfirmed ? "已确认" : "待确认"}'),
                      if (!isConfirmed)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: Key('confirm-${period.id}'),
                            onPressed: () =>
                                controller.confirmPeriod(period.id),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('确认对账'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          if (data.viewState == ViewState.empty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('暂无对账周期')),
            ),
          if (data.viewState == ViewState.loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
