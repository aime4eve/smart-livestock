import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/permissions/role_permission.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/core/widgets/auto_refresh_listener.dart';
import 'package:hkt_livestock_agentic/features/alerts/data/alerts_api_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_workbench.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/alert_workbench_controller.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_batch_bar.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_workbench_detail_sheet.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/widgets/alert_workbench_view.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/widgets/trajectory_sheet.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({
    super.key,
    required this.role,
    this.bucket,
    this.asset,
    this.category,
    this.fenceId,
    this.source,
  });

  final UserRole role;
  final String? bucket;
  final String? asset;
  final String? category;
  final String? fenceId;
  final String? source;

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  bool _batchMode = false;
  bool _detailOpen = false;
  bool _loadingMore = false;
  final Set<String> _selectedItemIds = {};

  bool get _refreshPaused => _batchMode || _detailOpen;

  Set<String> get _initialAsset {
    if (widget.asset == 'health') return {'livestock', 'herd'};
    if (widget.asset != null && widget.asset!.isNotEmpty) {
      return {widget.asset!};
    }
    final mapped = switch (widget.category) {
      'fence' => {'fence'},
      'health' => {'livestock', 'herd'},
      'device' => {'device'},
      _ => <String>{},
    };
    return mapped.isEmpty ? {'all'} : mapped;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(alertWorkbenchControllerProvider.notifier)
          .setFilters(
            bucket: widget.bucket ?? 'all',
            asset: _initialAsset,
            fenceId: widget.fenceId,
          );
    });
  }

  @override
  void didUpdateWidget(covariant AlertsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bucket != widget.bucket ||
        oldWidget.asset != widget.asset ||
        oldWidget.category != widget.category ||
        oldWidget.fenceId != widget.fenceId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(alertWorkbenchControllerProvider.notifier)
            .setFilters(
              bucket: widget.bucket ?? 'all',
              asset: _initialAsset,
              fenceId: widget.fenceId,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(alertWorkbenchControllerProvider);
    final controller = ref.read(alertWorkbenchControllerProvider.notifier);

    return Scaffold(
      key: const Key('page-alerts'),
      backgroundColor: AppColors.surface,
      appBar: _appBar(context, l10n),
      body: AutoRefreshListener(
        interval: const Duration(seconds: 30),
        onTick: () {
          if (_refreshPaused) return;
          ref.read(alertWorkbenchControllerProvider.notifier).silentRefresh();
        },
        child: asyncData.when(
          data: (data) => RefreshIndicator(
            onRefresh: controller.refresh,
            child: AlertWorkbenchView(
              data: data,
              selectedBucket: controller.bucket,
              selectedAsset: controller.asset,
              onBucket: (bucket) => controller.setFilters(
                bucket: bucket,
                asset: controller.asset,
                fenceId: controller.fenceId,
              ),
              onAsset: (asset) => controller.setFilters(
                bucket: controller.bucket,
                asset: asset,
                fenceId: controller.fenceId,
              ),
              onItem: (item) => _openDetail(context, item),
              onLoadMore: _loadMore,
              onRanking: () => showAiRankingSheet(context, data.items),
              loadingMore: _loadingMore,
              batchMode: _batchMode,
              selectedAlertIds: _selectedItemIds,
              onToggleSelection: _toggleSelection,
              source: widget.source,
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '${l10n.commonLoadFailed}: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: controller.refresh,
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _batchMode ? _batchBar(context) : null,
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, AppLocalizations l10n) {
    if (_batchMode) {
      final allIds =
          ref
              .read(alertWorkbenchControllerProvider)
              .value
              ?.items
              .map((item) => item.id)
              .toSet() ??
          <String>{};
      return AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: _exitBatchMode,
        ),
        title: Text(
          '${l10n.alertBatchTitle} (${_selectedItemIds.length})',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              if (_selectedItemIds.length == allIds.length) {
                _selectedItemIds.clear();
              } else {
                _selectedItemIds
                  ..clear()
                  ..addAll(allIds);
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
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 18),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        l10n.alertCenterTitle,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      actions: [
        TextButton(
          onPressed: _markAllLoadedRead,
          child: Text(
            l10n.alertActionMarkAllRead,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _batchMode = true),
          child: Text(
            l10n.alertBatchTitle,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _batchBar(BuildContext context) {
    return AlertBatchBar(
      selectedCount: _selectedItemIds.length,
      canDismiss: RolePermission.canHandleAlert(widget.role),
      onBatchRead: () async {
        await _batchAction(markRead: true);
        if (mounted) _exitBatchMode();
      },
      onBatchDismiss: () async {
        await _batchAction(markRead: false);
        if (mounted) _exitBatchMode();
      },
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
      } else {
        _selectedItemIds.add(id);
      }
    });
  }

  void _exitBatchMode() {
    setState(() {
      _batchMode = false;
      _selectedItemIds.clear();
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    await ref.read(alertWorkbenchControllerProvider.notifier).loadMore();
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _markAllLoadedRead() async {
    final data = ref.read(alertWorkbenchControllerProvider).value;
    if (data == null) return;
    final ids = data.items
        .expand((item) => item.reasons)
        .where((reason) => !reason.read)
        .map((reason) => reason.alertId)
        .toSet();
    if (ids.isEmpty) return;
    await const AlertsApiRepository().batchRead(ids.toList());
    await ref.read(alertWorkbenchControllerProvider.notifier).silentRefresh();
  }

  Future<void> _batchAction({required bool markRead}) async {
    final data = ref.read(alertWorkbenchControllerProvider).value;
    if (data == null) return;
    final selected = data.items
        .where((item) => _selectedItemIds.contains(item.id))
        .toList();
    const repo = AlertsApiRepository();
    if (markRead) {
      final ids = selected
          .expand((item) => item.reasons)
          .map((reason) => reason.alertId)
          .toSet();
      if (ids.isNotEmpty) await repo.batchRead(ids.toList());
    } else {
      for (final item in selected) {
        for (final reason in item.reasons) {
          await repo.dismiss(reason.alertId);
        }
      }
    }
    await ref.read(alertWorkbenchControllerProvider.notifier).refresh();
  }

  Future<void> _openDetail(BuildContext context, WorkbenchItem item) async {
    setState(() => _detailOpen = true);
    try {
      await showAlertWorkbenchDetailSheet(
        context,
        item: item,
        role: widget.role,
        onMarkRead: (detail) => ref
            .read(alertWorkbenchControllerProvider.notifier)
            .markRead(detail),
        onDismiss: (detail) =>
            ref.read(alertWorkbenchControllerProvider.notifier).dismiss(detail),
        onNavigate: (route) => context.push(route),
        onTrajectory: (detail) => showTrajectorySheet(
          context,
          detail.asset.id,
          livestockCode: detail.asset.name,
        ),
      );
    } finally {
      if (mounted) setState(() => _detailOpen = false);
    }
  }
}
