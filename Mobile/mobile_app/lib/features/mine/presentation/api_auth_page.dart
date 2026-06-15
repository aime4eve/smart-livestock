import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/api_authorization/domain/api_authorization_repository.dart';
import 'package:hkt_livestock_agentic/features/api_authorization/presentation/api_authorization_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class MineApiAuthPage extends ConsumerWidget {
  const MineApiAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(apiAuthorizationControllerProvider);

    return asyncData.when(
      data: (data) => SingleChildScrollView(
        key: const Key('page-mine-api-auth'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.mineApiAuthTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.mineApiAuthManagementDesc, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            if (data.isEmpty)
              SizedBox(height: 200, child: Center(child: Text(l10n.adminApiAuthNoKeys)))
            else
              ...data.items.map((key) => _MineApiKeyCard(keyItem: key)),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
    );
  }
}

class _MineApiKeyCard extends StatelessWidget {
  const _MineApiKeyCard({required this.keyItem});

  final ApiKeyItem keyItem;

  bool get _isActive =>
      keyItem.status == 'active' || keyItem.status == 'ACTIVE';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _isActive ? AppColors.success : AppColors.danger;
    final statusLabel = _isActive ? l10n.adminContractActive : (keyItem.status ?? '未知');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiCard(
        key: Key('apikey-${keyItem.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    keyItem.name ?? keyItem.prefix ?? 'API Key',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                HighfiStatusChip(
                  label: statusLabel,
                  color: statusColor,
                  icon: _isActive
                      ? Icons.check_circle_outline
                      : Icons.pending_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (keyItem.prefix != null) Text('${l10n.adminApiAuthPrefixLabel}: ${keyItem.prefix}'),
            if (keyItem.scopeList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: keyItem.scopeList.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
