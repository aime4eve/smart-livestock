import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/permissions/role_permission.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alerts_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/alerts_controller.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_batch_bar.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_card.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_detail_sheet.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_empty_state.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_filter_bar.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_summary_strip.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  AlertFilterTab _activeTab = AlertFilterTab.all;
  String? _selectedType;
  bool _batchMode = false;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(alertsControllerProvider);
    final controller = ref.read(alertsControllerProvider.notifier);

    return Scaffold(
      key: const Key('page-alerts'),
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context, l10n, controller),
      body: asyncData.when(
        data: (data) => _buildBody(context, data, controller),
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
      bottomNavigationBar: _batchMode
          ? _buildBatchBar(context, controller)
          : null,
    );
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
    AlertsController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final items = data.items;

    // Compute summary counts from all items (not filtered)
    final criticalCount = items
        .where((a) => a.severity == 'CRITICAL' && a.stage == 'active')
        .length;
    final warningCount = items
        .where((a) => a.severity == 'WARNING' && a.stage == 'active')
        .length;
    final pendingCount = items.where((a) => a.stage == 'active').length;
    final unreadCount =
        items.where((a) => !a.read && a.stage == 'active').length;

    // Apply status filter from active tab
    final statusFiltered = switch (_activeTab) {
      AlertFilterTab.all => items,
      AlertFilterTab.active =>
        items.where((a) => a.stage == 'active').toList(),
      AlertFilterTab.resolved =>
        items.where((a) => a.stage != 'active').toList(),
    };

    // Apply type filter
    final typeFiltered = _selectedType == null
        ? statusFiltered
        : statusFiltered.where((a) => a.type == _selectedType).toList();

    // Apply controller's severity filter (from summary strip tap)
    final severityFiltered = controller.filterSeverity == null
        ? typeFiltered
        : typeFiltered
            .where((a) => a.severity == controller.filterSeverity)
            .toList();

    // Build available types from data
    final availableTypes = items.map((a) => a.type).toSet().toList()..sort();

    return Column(
      children: [
        if (!_batchMode)
          AlertSummaryStrip(
            criticalCount: criticalCount,
            warningCount: warningCount,
            pendingCount: pendingCount,
            activeFilter: controller.filterSeverity,
            onTap: (severity) => controller.setFilterSeverity(severity),
            onPendingTap: () {
              setState(() => _activeTab = AlertFilterTab.active);
              controller.setFilterStatus('ACTIVE');
            },
          ),
        if (!_batchMode)
          AlertFilterBar(
            activeTab: _activeTab,
            unreadCount: unreadCount,
            onTabChanged: (tab) {
              setState(() => _activeTab = tab);
              final statusParam = switch (tab) {
                AlertFilterTab.all => null,
                AlertFilterTab.active => 'ACTIVE',
                AlertFilterTab.resolved => null,
              };
              controller.setFilterStatus(statusParam);
            },
            availableTypes: availableTypes,
            selectedType: _selectedType,
            onTypeChanged: (type) => setState(() => _selectedType = type),
          ),
        Expanded(
          child: severityFiltered.isEmpty
              ? const AlertEmptyState()
              : _buildGroupedList(context, severityFiltered, l10n),
        ),
      ],
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    List<AlertItem> items,
    AppLocalizations l10n,
  ) {
    final groups = _groupByDate(items, l10n);

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
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xxl)),
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
    final items = data.items;
    final statusFiltered = switch (_activeTab) {
      AlertFilterTab.all => items,
      AlertFilterTab.active =>
        items.where((a) => a.stage == 'active').toList(),
      AlertFilterTab.resolved =>
        items.where((a) => a.stage != 'active').toList(),
    };
    return statusFiltered.map((a) => a.id).toList();
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

  void _onAlertTap(AlertItem alert) {
    showAlertDetailSheet(
      context,
      alert: alert,
      role: widget.role,
    );
  }

  void _markAllRead(AlertsController controller) {
    final data = ref.read(alertsControllerProvider).value;
    if (data == null) return;
    final unreadIds =
        data.items.where((a) => !a.read).map((a) => a.id).toList();
    if (unreadIds.isNotEmpty) {
      controller.batchRead(unreadIds);
    }
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
