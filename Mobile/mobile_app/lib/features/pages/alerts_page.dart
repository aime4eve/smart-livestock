import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/permissions/role_permission.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/widgets/auto_refresh_listener.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_summary.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alerts_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/alerts_controller.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_batch_bar.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_card.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_detail_sheet.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_empty_state.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_summary_header.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/load_more_footer.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/refresh_hint.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key, required this.role, this.category, this.fenceId});

  final UserRole role;
  final String? category; // 'fence' | 'health' | 'device'
  final String? fenceId;

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  /// The list always shows one status server-side: ACTIVE by default ("what
  /// needs handling"), RESOLVED only through the explicit history links.
  bool _showResolved = false;

  /// Hero "Unread" filter: list shows only unread active alerts.
  String? _selectedType;

  static const _fenceTypes = {'FENCE_BREACH', 'FENCE_APPROACH', 'ZONE_APPROACH'};
  static const _healthTypes = {'TEMPERATURE_ABNORMAL', 'DIGESTIVE_ABNORMAL', 'ESTRUS', 'EPIDEMIC', 'AI_ANOMALY'};
  static const _deviceTypes = {'DEVICE_TAMPER', 'DEVICE_LOW_BATTERY'};

  Set<String> get _categoryTypes => switch (widget.category) {
    'fence' => _fenceTypes,
    'health' => _healthTypes,
    'device' => _deviceTypes,
    _ => <String>{},
  };
  bool _batchMode = false;
  bool _detailOpen = false;
  bool _loadingMore = false;
  final Set<String> _selectedIds = {};

  /// Last known category-scoped summary — keeps the header stable across
  /// silent refreshes (invalidation briefly clears the provider value).
  RanchAlertSummary? _lastScopedSummary;

  bool get _refreshPaused => _batchMode || _detailOpen;

  @override
  void initState() {
    super.initState();
    // Deep-link category/fence filters go to the API (server-side pagination
    // counts must respect them) — pushed once after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(alertsControllerProvider.notifier);
      controller.setFilterCategory(_categoryTypes);
      controller.setFilterFenceId(widget.fenceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(alertsControllerProvider);
    final summary = ref.watch(alertSummaryControllerProvider).value;
    final controller = ref.read(alertsControllerProvider.notifier);

    return Scaffold(
      key: const Key('page-alerts'),
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context, l10n, controller),
      body: AutoRefreshListener(
        interval: const Duration(seconds: 30),
        onTick: _onAutoRefreshTick,
        child: asyncData.when(
          data: (data) => _buildBody(context, data, summary, controller),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${l10n.commonLoadFailed}: $e'),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => controller.refresh(),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _batchMode
          ? _buildBatchBar(context, controller)
          : null,
    );
  }

  void _onAutoRefreshTick() {
    if (_refreshPaused) return;
    ref.read(alertsControllerProvider.notifier).silentRefresh();
    ref.invalidate(scopedAlertSummaryProvider(scopedSummaryKey(_categoryTypes)));
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    AlertsController controller,
  ) {
    if (_batchMode) {
      return AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: _exitBatchMode,
        ),
        title: Text(
          '${l10n.alertBatchTitle} (${_selectedIds.length})',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => setState(() {
              final data = ref.read(alertsControllerProvider).value;
              if (data != null) {
                final allIds = _visibleAlertIds(data);
                if (_selectedIds.length == allIds.length) {
                  _selectedIds.clear();
                } else {
                  _selectedIds
                    ..clear()
                    ..addAll(allIds);
                }
              }
            }),
            child: Text(
              l10n.alertBatchSelectAll,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Text(
        l10n.alertCenterTitle,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 18),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        TextButton(
          onPressed: () => _markAllRead(controller),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.done_all, size: 12),
              const SizedBox(width: 3),
              Text(
                l10n.alertActionMarkAllRead,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatchBar(
    BuildContext context,
    AlertsController controller,
  ) {
    final canDismiss = RolePermission.canHandleAlert(widget.role);
    return AlertBatchBar(
      selectedCount: _selectedIds.length,
      canDismiss: canDismiss,
      onBatchRead: () async {
        if (_selectedIds.isEmpty) return;
        await controller.batchRead(_selectedIds.toList());
        _exitBatchMode();
      },
      onBatchDismiss: () async {
        if (_selectedIds.isEmpty) return;
        await controller.batchDismiss(_selectedIds.toList());
        _exitBatchMode();
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AlertsListData data,
    RanchAlertSummary? summary,
    AlertsController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final items = data.items;

    // Category-scoped summary (matches the filtered list exactly); falls back
    // to the farm-wide summary, then zeros while loading.
    final typesKey = scopedSummaryKey(_categoryTypes);
    final scoped = ref.watch(scopedAlertSummaryProvider(typesKey)).value;
    if (scoped != null) _lastScopedSummary = scoped;
    final headerSummary = scoped ?? _lastScopedSummary ?? summary;

    // Status filtering is server-side: the list shows ACTIVE by default and
    // RESOLVED only through the explicit "resolved records" links.
    // Category/type-chip and fenceId filters are applied server-side too (see
    // initState / onTypeChanged) so pagination totals stay correct.
    // Severity filter comes from the API already (controller.filterSeverity);
    // kept as a client-side guard for stale responses mid-toggle.
    final finalFiltered = controller.filterSeverity == null
        ? items
        : items.where((a) => a.severity == controller.filterSeverity).toList();

    // Chip row: with a deep-link category, offer the category's full type set
    // (server-side filtering means loaded items can't be used as the source —
    // a narrowed filter would hide the other chips).
    final availableTypes = _categoryTypes.isNotEmpty
        ? (_categoryTypes.toList()..sort())
        : (items.map((a) => a.type).toSet().toList()..sort());

    return Column(
      children: [
        if (!_batchMode) ...[
          AlertSummaryHeader(
            summary: headerSummary ??
                const RanchAlertSummary(
                  activeTotal: 0, unread: 0, critical: 0, warning: 0, info: 0,
                  byGroup: GroupCounts(), byGroupUnread: GroupCounts(),
                  resolved: 0,
                ),
            selectedSeverity: controller.filterSeverity,
            // Severity cells are active-scoped: tapping one snaps the status
            // filter to Active so the list count always equals the cell count.
            onSeverityToggle: (sev) {
              _showResolved = false;
              controller.applyFilters(status: 'ACTIVE', severity: sev);
            },
          ),
          RefreshHint(
            state: _refreshPaused ? RefreshHintState.paused : RefreshHintState.ok,
          ),
        ],
        // Type chips (server-side filter via onTypeChanged)
        if (!_batchMode)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 6),
            color: AppColors.surface,
            child: SizedBox(
              height: 24,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final t in [null, ...availableTypes])
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: _TypeChip(
                        label: t == null
                            ? l10n.alertFilterAllTypes
                            : _alertTypeLabel(l10n, t),
                        selected: _selectedType == t,
                        onTap: () {
                          setState(() => _selectedType = t);
                          controller.setFilterCategory(
                              t != null ? {t} : _categoryTypes);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: finalFiltered.isEmpty
              ? (!_showResolved && _categoryTypes.isEmpty
                  ? _buildEmptyActive(context, summary, l10n)
                  : const AlertEmptyState())
              : _buildGroupedList(context, finalFiltered, l10n),
        ),
      ],
    );
  }

  String _alertTypeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'FENCE_BREACH' => l10n.alertTypeFenceBreach,
      'FENCE_APPROACH' => l10n.alertTypeFenceApproach,
      'ZONE_APPROACH' => l10n.alertTypeZoneApproach,
      'TEMPERATURE_ABNORMAL' => l10n.alertTypeTemperatureAbnormal,
      'DIGESTIVE_ABNORMAL' => l10n.alertTypeDigestiveAbnormal,
      'ESTRUS' => l10n.alertTypeEstrus,
      'EPIDEMIC' => l10n.alertTypeEpidemic,
      'AI_ANOMALY' => l10n.alertTypeAiAnomaly,
      'DEVICE_TAMPER' => l10n.alertTypeDeviceTamper,
      'DEVICE_LOW_BATTERY' => l10n.alertTypeDeviceLowBattery,
      _ => type,
    };
  }

  /// Positive-feedback empty state for the ACTIVE tab (spec 4.6).
  Widget _buildEmptyActive(
    BuildContext context,
    RanchAlertSummary? summary,
    AppLocalizations l10n,
  ) {
    final resolved = summary?.resolved ?? 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.alertEmptyTitle,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.alertEmptyDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (resolved > 0) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () {
                setState(() {
                  _showResolved = true;
                });
                ref
                    .read(alertsControllerProvider.notifier)
                    .setFilterStatus('RESOLVED');
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primarySoft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              ),
              child: Text(
                l10n.alertEmptyCta(resolved),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    List<AlertItem> items,
    AppLocalizations l10n,
  ) {
    final groups = _groupByDate(items, l10n);
    final data = ref.read(alertsControllerProvider).value;

    return CustomScrollView(
      slivers: [
        for (final entry in groups.entries)
          SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child:
                    _DateGroupHeader(label: entry.key, count: entry.value.length),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final alert = entry.value[index];
                      return AlertCard(
                        key: Key('alert-card-${alert.id}'),
                        alert: alert,
                        isBatchMode: _batchMode,
                        isSelected: _selectedIds.contains(alert.id),
                        onSelectionToggle: () => _toggleSelection(alert.id),
                        onTap: () {
                          if (_batchMode) {
                            _toggleSelection(alert.id);
                          } else {
                            _onAlertTap(alert);
                          }
                        },
                        onLongPress: () {
                          if (!_batchMode) {
                            setState(() {
                              _batchMode = true;
                              _selectedIds.add(alert.id);
                            });
                          }
                        },
                      );
                    },
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],
          ),
        // Pagination footer (true server-side total) + low-key resolved
        // history entry (replaces the former all/active/resolved tab bar).
        SliverToBoxAdapter(
          child: Column(
            children: [
              LoadMoreFooter(
                shown: items.length,
                total: data?.total ?? items.length,
                loading: _loadingMore,
                onLoadMore: () async {
                  setState(() => _loadingMore = true);
                  await ref.read(alertsControllerProvider.notifier).loadMore();
                  if (mounted) setState(() => _loadingMore = false);
                },
              ),
              TextButton(
                onPressed: () {
                  final next = !_showResolved;
                  setState(() {
                    _showResolved = next;
                  });
                  ref
                      .read(alertsControllerProvider.notifier)
                      .setFilterStatus(next ? 'RESOLVED' : 'ACTIVE');
                },
                child: Text(
                  _showResolved
                      ? l10n.alertBackToActive
                      : l10n.alertEmptyCta(
                          ref.watch(scopedAlertSummaryProvider(
                                  scopedSummaryKey(_categoryTypes)))
                              .value
                              ?.resolved ??
                              0),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Batch helpers ──

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitBatchMode() {
    setState(() {
      _batchMode = false;
      _selectedIds.clear();
    });
  }

  List<String> _visibleAlertIds(AlertsListData data) {
    // The server already scopes the list to one status; batch select-all
    // operates on the loaded page.
    return data.items.map((a) => a.id).toList();
  }

  // ── Non-batch helpers ──

  Map<String, List<AlertItem>> _groupByDate(
      List<AlertItem> items, AppLocalizations l10n) {
    final now = DateTime.now();
    final groups = <String, List<AlertItem>>{};

    for (final item in items) {
      String key;
      if (item.occurredAt != null) {
        try {
          final dt = DateTime.parse(item.occurredAt!).toLocal();
          final diff = now.difference(dt);
          if (diff.inDays == 0 && now.day == dt.day) {
            key = l10n.alertDateToday;
          } else if (diff.inDays == 1) {
            key = l10n.alertDateYesterday;
          } else {
            key = l10n.alertDateEarlier;
          }
        } catch (_) {
          key = l10n.alertDateEarlier;
        }
      } else {
        key = l10n.alertDateEarlier;
      }
      groups.putIfAbsent(key, () => []).add(item);
    }

    final orderedKeys = [
      l10n.alertDateToday,
      l10n.alertDateYesterday,
      l10n.alertDateEarlier
    ];
    final result = <String, List<AlertItem>>{};
    for (final k in orderedKeys) {
      if (groups.containsKey(k)) result[k] = groups[k]!;
    }
    return result;
  }

  Future<void> _onAlertTap(AlertItem alert) async {
    setState(() => _detailOpen = true);
    try {
      await showAlertDetailSheet(
        context,
        alert: alert,
        role: widget.role,
      );
    } finally {
      if (mounted) setState(() => _detailOpen = false);
    }
  }

  void _markAllRead(AlertsController controller) {
    final data = ref.read(alertsControllerProvider).value;
    if (data == null) return;
    final unreadIds =
        data.items.where((a) => !a.read && a.stage == 'active').map((a) => a.id).toList();
    if (unreadIds.isNotEmpty) {
      controller.batchRead(unreadIds).then((_) {
        if (mounted) {
          ref.invalidate(scopedAlertSummaryProvider(scopedSummaryKey(_categoryTypes)));
        }
      });
    }
  }
}

/// Text chip for the type filter row (server-side filtered).
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DateGroupHeader extends StatelessWidget {
  const _DateGroupHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Divider(
              height: 1,
              color: AppColors.border,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              l10n.alertDateCount(count),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
