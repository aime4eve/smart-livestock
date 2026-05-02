import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/contract_management/presentation/contract_management_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class ContractsPage extends ConsumerWidget {
  const ContractsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(contractManagementControllerProvider);
    final controller =
        ref.read(contractManagementControllerProvider.notifier);

    return SingleChildScrollView(
      key: const Key('page-contracts'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '合同管理',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '管理平台与牧场之间的合作协议',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '', label: Text('全部')),
                    ButtonSegment(value: 'active', label: Text('生效中')),
                    ButtonSegment(value: 'pending', label: Text('待签署')),
                    ButtonSegment(value: 'terminated', label: Text('已终止')),
                  ],
                  selected: const {''},
                  onSelectionChanged: (selected) {
                    final s = selected.first;
                    controller.filter(status: s.isEmpty ? null : s);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.viewState == ViewState.normal)
            ...data.contracts.map((contract) => _buildContractCard(context, contract, controller)),
          if (data.viewState == ViewState.empty)
            _buildEmpty(context),
          if (data.viewState == ViewState.loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildContractCard(
    BuildContext context,
    Map<String, dynamic> contract,
    ContractManagementController controller,
  ) {
    final status = contract['status'] as String? ?? '';
    final statusColor = switch (status) {
      'active' => AppColors.success,
      'pending' => AppColors.warning,
      'terminated' => AppColors.danger,
      _ => AppColors.info,
    };
    final statusLabel = switch (status) {
      'active' => '生效中',
      'pending' => '待签署',
      'terminated' => '已终止',
      _ => status,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiCard(
        key: Key('contract-${contract['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  contract['partnerName'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                HighfiStatusChip(
                  label: statusLabel,
                  color: statusColor,
                  icon: status == 'active'
                      ? Icons.check_circle_outline
                      : status == 'pending'
                          ? Icons.pending_outlined
                          : Icons.cancel_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('分润比例: ${contract['revenueShare']}%'),
            if (contract['startDate'] != null)
              Text('期限: ${contract['startDate']} ~ ${contract['endDate']}'),
            if (status == 'active')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: Key('terminate-${contract['id']}'),
                  onPressed: () =>
                      controller.terminateContract(contract['id'] as String),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('终止合同'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(child: Text('暂无合同')),
    );
  }
}
