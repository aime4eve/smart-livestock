import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/contract_management/domain/contract_management_repository.dart';
import 'package:hkt_livestock_agentic/features/contract_management/presentation/contract_management_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class ContractsPage extends ConsumerStatefulWidget {
  const ContractsPage({super.key});

  @override
  ConsumerState<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends ConsumerState<ContractsPage> {
  String _statusFilter = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(contractManagementControllerProvider);
    final controller =
        ref.read(contractManagementControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(AppRoute.platformContracts.label)),
      body: asyncData.when(
      data: (data) {
        final filtered = _statusFilter.isEmpty
            ? data.contracts
            : data.contracts.where((c) => c.status == _statusFilter).toList();

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
                      segments: [
                        ButtonSegment(value: '', label: Text(l10n.commonAll)),
                        ButtonSegment(value: 'active', label: Text(l10n.adminContractActive)),
                        ButtonSegment(value: 'draft', label: Text(l10n.adminContractDraft)),
                        ButtonSegment(value: 'terminated', label: Text(l10n.adminContractTerminated)),
                      ],
                      selected: {_statusFilter},
                      onSelectionChanged: (selected) {
                        setState(() => _statusFilter = selected.first);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (filtered.isNotEmpty)
                ...filtered.map((contract) =>
                    _buildContractCard(context, contract, controller)),
              if (filtered.isEmpty) _buildEmpty(context),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    ),
    );
  }

  Widget _buildContractCard(
    BuildContext context,
    ContractSummary contract,
    ContractManagementController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = switch (contract.status) {
      'active' => AppColors.success,
      'draft' => AppColors.warning,
      'terminated' => AppColors.danger,
      'suspended' => AppColors.info,
      _ => AppColors.info,
    };
    final statusIcon = contract.isActive
        ? Icons.check_circle_outline
        : contract.isDraft
            ? Icons.pending_outlined
            : Icons.cancel_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiCard(
        key: Key('contract-${contract.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  contract.contractNumber ?? contract.id,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                HighfiStatusChip(
                  label: contract.statusLabel,
                  color: statusColor,
                  icon: statusIcon,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (contract.revenueShareRatio != null)
              Text('分润比例: ${(contract.revenueShareRatio! * 100).toInt()}%'),
            if (contract.startedAt != null)
              Text('生效: ${contract.startedAt}'),
            if (contract.expiresAt != null)
              Text('到期: ${contract.expiresAt}'),
            if (contract.isActive)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: Key('terminate-${contract.id}'),
                  onPressed: () => controller
                      .updateContractStatus(contract.id, 'TERMINATED'),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: Text(l10n.adminContractTerminate),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 200,
      child: Center(child: Text(l10n.adminContractNoData)),
    );
  }
}
