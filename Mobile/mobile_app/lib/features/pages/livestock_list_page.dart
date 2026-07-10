import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class LivestockListPage extends ConsumerStatefulWidget {
  const LivestockListPage({super.key});

  @override
  ConsumerState<LivestockListPage> createState() => _LivestockListPageState();
}

class _LivestockListPageState extends ConsumerState<LivestockListPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _hasSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _hasSearch = value.trim().isNotEmpty);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(livestockListControllerProvider.notifier).search(value.trim());
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _hasSearch = false);
    ref.read(livestockListControllerProvider.notifier).search('');
  }

  void _openForm([LivestockSummary? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => LivestockFormSheet(existing: existing),
    ).then((_) => ref.read(livestockListControllerProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(livestockListControllerProvider);
    final controller = ref.read(livestockListControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.livestockListTitle),
        actions: [
          IconButton(
            key: const Key('livestock-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              key: const Key('livestock-search'),
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.livestockSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          // Search result banner
          if (_hasSearch && asyncData is AsyncData)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.livestockSearchResult(asyncData.value!.total),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const Key('livestock-show-all'),
                    onPressed: _clearSearch,
                    child: Text(l10n.livestockShowAll),
                  ),
                ],
              ),
            ),
          // List + pagination
          Expanded(
            child: asyncData.when(
              data: (data) {
                if (data.items.isEmpty) {
                  return Center(child: Text(l10n.devicesNoDevices));
                }
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final item in data.items)
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: HighfiCard(
                                  child: ListTile(
                                    key: Key('livestock-${item.id}'),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    title: Text(item.livestockCode,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                   subtitle:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(item.breed.localizedLabel(l10n)),
                                        if (item.deviceCodes.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 4),
                                            child: Wrap(
                                              spacing: 4,
                                              runSpacing: 2,
                                              children: [
                                                for (final code
                                                    in item.deviceCodes)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .primarySoft,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(4),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons
                                                                .gps_fixed,
                                                            size: 10),
                                                        const SizedBox(
                                                            width: 2),
                                                        Text(code,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelSmall),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          )
                                        else
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Text(
                                                l10n.livestockNoDeviceBound,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: AppColors
                                                            .textSecondary)),
                                          ),
                                      ],
                                    ),
                                   trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        HighfiStatusChip(
                                          label:
                                              item.health.localizedLabel(l10n),
                                          color: item.health ==
                                                  LivestockHealth.abnormal
                                              ? AppColors.danger
                                              : item.health ==
                                                      LivestockHealth.watch
                                                  ? AppColors.warning
                                                  : AppColors.success,
                                          icon: item.health ==
                                                  LivestockHealth.abnormal
                                              ? Icons.warning_amber_rounded
                                              : item.health ==
                                                      LivestockHealth.watch
                                                  ? Icons.visibility_outlined
                                                  : Icons.check_circle_outline,
                                        ),
                                        IconButton(
                                          key:
                                              Key('livestock-edit-${item.id}'),
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 20),
                                          onPressed: () => _openForm(item),
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
                    ),
                    // Pagination bar
                    _PaginationBar(
                      currentPage: controller.currentPage,
                      totalPages: controller.totalPages,
                      total: data.total,
                      onPrev: () => controller
                          .goToPage(controller.currentPage - 1),
                      onNext: () => controller
                          .goToPage(controller.currentPage + 1),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${l10n.commonLoadFailed}: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.refresh(),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.livestockPaginationInfo(currentPage, totalPages, total),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            children: [
              IconButton(
                key: const Key('livestock-prev-page'),
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1 ? onPrev : null,
              ),
              Text('$currentPage / $totalPages'),
              IconButton(
                key: const Key('livestock-next-page'),
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages ? onNext : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
