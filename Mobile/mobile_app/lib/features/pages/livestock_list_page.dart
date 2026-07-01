import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/l10n/enum_labels.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/widgets/livestock_form_sheet.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class LivestockListPage extends ConsumerWidget {
  const LivestockListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(livestockListControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.livestockListTitle)),
      floatingActionButton: FloatingActionButton(
        key: const Key('livestock-add-fab'),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => const LivestockFormSheet(),
          ).then((_) => ref.read(livestockListControllerProvider.notifier).refresh());
        },
        child: const Icon(Icons.add),
      ),
      body: asyncData.when(
        data: (data) => data.items.isEmpty
            ? Center(child: Text(l10n.devicesNoDevices))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in data.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: HighfiCard(
                          child: ListTile(
                            key: Key('livestock-${item.id}'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            title: Text(item.earTag,
                                style: Theme.of(context).textTheme.titleMedium),
                            subtitle: Text(item.breed),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HighfiStatusChip(
                                  label: item.health.localizedLabel(l10n),
                                  color: item.health == LivestockHealth.abnormal
                                      ? AppColors.danger
                                      : item.health == LivestockHealth.watch
                                          ? AppColors.warning
                                          : AppColors.success,
                                  icon: item.health == LivestockHealth.abnormal
                                      ? Icons.warning_amber_rounded
                                      : item.health == LivestockHealth.watch
                                          ? Icons.visibility_outlined
                                          : Icons.check_circle_outline,
                                ),
                                IconButton(
                                  key: Key('livestock-edit-${item.id}'),
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (ctx) =>
                                          LivestockFormSheet(existing: item),
                                    ).then((_) => ref
                                        .read(livestockListControllerProvider.notifier)
                                        .refresh());
                                  },
                                ),
                              ],
                            ),
                            onTap: () =>
                                context.go('/livestock/${item.id}'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.commonLoadFailed}: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(livestockListControllerProvider.notifier).refresh(),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
