import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/revenue/presentation/revenue_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class RevenuePage extends ConsumerWidget {
  const RevenuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(revenueControllerProvider);
    final controller = ref.read(revenueControllerProvider.notifier);

    return asyncData.when(
      data: (data) => SingleChildScrollView(
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
            if (data.periods.isNotEmpty)
              ...data.periods.map((period) {
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
                              period.platformConfirmed
                                  ? Icons.check_circle
                                  : Icons.pending_outlined,
                              color: period.platformConfirmed
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
                        Text(
                          '状态: ${period.platformConfirmed ? "已确认" : "待确认"}',
                        ),
                        if (period.isPending)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              key: Key('confirm-${period.id}'),
                              onPressed: () =>
                                  controller.confirmPeriod(period.id),
                              icon: const Icon(Icons.check, size: 16),
                              label: Text(l10n.b2bRevenueDetailConfirmButton),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            if (data.isEmpty)
              SizedBox(
                height: 200,
                child: Center(child: Text(l10n.adminRevenueNoData)),
              ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
