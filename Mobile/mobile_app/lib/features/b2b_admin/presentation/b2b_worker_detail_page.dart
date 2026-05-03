import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_worker_management_controller.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/widgets/confirm_dialog.dart';

class B2bWorkerDetailPage extends ConsumerStatefulWidget {
  const B2bWorkerDetailPage({super.key, required this.farmId});

  final String farmId;

  @override
  ConsumerState<B2bWorkerDetailPage> createState() =>
      _B2bWorkerDetailPageState();
}

class _B2bWorkerDetailPageState extends ConsumerState<B2bWorkerDetailPage> {
  List<B2bSubFarmWorker> _workers = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  void _loadWorkers() {
    final workers = ref
        .read(b2bWorkerManagementControllerProvider.notifier)
        .getSubFarmWorkers(widget.farmId);
    if (mounted) {
      setState(() {
        _workers = workers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider so page rebuilds when data changes
    ref.watch(b2bWorkerManagementControllerProvider);
    final data = ref.read(b2bWorkerManagementControllerProvider);
    // Reload workers from latest controller state on every rebuild
    final latestWorkers = ref
        .read(b2bWorkerManagementControllerProvider.notifier)
        .getSubFarmWorkers(widget.farmId);
    if (_workers.isNotEmpty && _workers.length != latestWorkers.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _workers = latestWorkers);
      });
    } else if (_workers.isEmpty && latestWorkers.isNotEmpty) {
      _workers = latestWorkers;
    }

    // Find farm info
    final farm = data.subFarms.where((f) => f.id == widget.farmId).firstOrNull;

    return switch (data.viewState) {
      ViewState.loading => const Scaffold(
          body: Center(
            key: Key('b2b-worker-detail-loading'),
            child: CircularProgressIndicator(),
          ),
        ),
      ViewState.error => Scaffold(
          body: _ErrorView(
            key: const Key('b2b-worker-detail-error'),
            message: data.message ?? '加载失败',
          ),
        ),
      ViewState.empty => const Scaffold(
          body: _DetailEmptyView(
            key: Key('b2b-worker-detail-empty'),
          ),
        ),
      ViewState.forbidden => const Scaffold(
          body: _ForbiddenView(
            key: Key('b2b-worker-detail-forbidden'),
          ),
        ),
      ViewState.offline => const Scaffold(
          body: _OfflineView(
            key: Key('b2b-worker-detail-offline'),
          ),
        ),
      ViewState.normal => farm == null
          ? const Scaffold(
              body: _DetailEmptyView(
                key: Key('b2b-worker-detail-not-found'),
              ),
            )
          : _buildContent(context, farm),
    };
  }

  Widget _buildContent(BuildContext context, B2bSubFarm farm) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        key: const Key('page-b2b-worker-detail'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Breadcrumb ---
            _BreadcrumbBar(
              key: const Key('b2b-worker-detail-breadcrumb'),
              farmName: farm.name,
              onBack: () => context.pop(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Farm info bar ---
            _FarmInfoBar(
              key: const Key('b2b-worker-detail-info-bar'),
              farm: farm,
              isBusy: _busy,
              onAssign: _busy ? null : () => _handleAssign(farm),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Worker list label ---
            Text(
              '牧工列表',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),

            // --- Worker list ---
            if (_workers.isEmpty)
              const _EmptyWorkerState(
                key: Key('b2b-worker-detail-empty-workers'),
              )
            else
              ..._workers.map((worker) => _WorkerCard(
                    key: Key('b2b-worker-${worker.id}'),
                    worker: worker,
                    farmName: farm.name,
                    isBusy: _busy,
                    onRemove: _busy ? null : () => _handleRemove(worker, farm),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAssign(B2bSubFarm farm) async {
    if (_busy) return;
    setState(() => _busy = true);

    final available = ref
        .read(b2bWorkerManagementControllerProvider.notifier)
        .getAvailableWorkers();

    if (!mounted) return;

    if (available.isEmpty) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('所有牧工已分配到各牧场'),
          backgroundColor: Color(0xFF607D8B),
        ),
      );
      return;
    }

    // Show multi-select dialog
    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          key: const Key('b2b-assign-worker-dialog'),
          title: const Text('分配牧工'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: available.map((w) {
                final isSelected = selected.contains(w.id);
                return CheckboxListTile(
                  key: Key('b2b-assign-cb-${w.id}'),
                  value: isSelected,
                  title: Text(w.name),
                  subtitle: Text(w.role),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    setDialogState(() {
                      if (v == true) {
                        selected.add(w.id);
                      } else {
                        selected.remove(w.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('b2b-assign-confirm-btn'),
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: const Text('确认分配'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // Assign each selected worker
    var successCount = 0;
    for (final workerId in selected) {
      final ok = await ref
          .read(b2bWorkerManagementControllerProvider.notifier)
          .assignWorker(widget.farmId, workerId);
      if (ok) successCount++;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已分配 $successCount 名牧工到 ${farm.name}'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );

    setState(() => _busy = false);
    _loadWorkers();
    ref.invalidate(b2bWorkerManagementControllerProvider);
  }

  Future<void> _handleRemove(
    B2bSubFarmWorker worker,
    B2bSubFarm farm,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);

    final confirmed = await B2bConfirmDialog.show(
      context,
      title: '移除牧工',
      subtitle: '确认将 ${worker.name} 从 ${farm.name} 移除？',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) {
      setState(() => _busy = false);
      return;
    }

    final ok = await ref
        .read(b2bWorkerManagementControllerProvider.notifier)
        .removeWorker(widget.farmId, worker.id);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已将 ${worker.name} 从 ${farm.name} 移除'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      setState(() => _busy = false);
      _loadWorkers();
      ref.invalidate(b2bWorkerManagementControllerProvider);
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('移除失败，请重试'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({
    super.key,
    required this.farmName,
    required this.onBack,
  });

  final String farmName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          key: const Key('b2b-worker-detail-back'),
          onTap: onBack,
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios, size: 14,
                  color: Theme.of(context).hintColor),
              Text('牧工管理',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 14,
                  )),
            ],
          ),
        ),
        Text(' > $farmName',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _FarmInfoBar extends StatelessWidget {
  const _FarmInfoBar({
    super.key,
    required this.farm,
    this.isBusy = false,
    required this.onAssign,
  });

  final B2bSubFarm farm;
  final bool isBusy;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Stats chips
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _InfoChip(
                  icon: Icons.groups_outlined,
                  label: '牧工 ${farm.workerCount} 人',
                ),
                _InfoChip(
                  icon: Icons.pets_outlined,
                  label: '牲畜 ${farm.livestockCount} 头',
                ),
                _InfoChip(
                  icon: Icons.sensors_outlined,
                  label: '设备 ${farm.deviceCount} 台',
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Assign button
          FilledButton(
            key: const Key('b2b-assign-worker-btn'),
            onPressed: isBusy ? null : onAssign,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF546E7A),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('分配牧工', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).hintColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    super.key,
    required this.worker,
    required this.farmName,
    this.isBusy = false,
    required this.onRemove,
  });

  final B2bSubFarmWorker worker;
  final String farmName;
  final bool isBusy;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isActive = worker.status == 'active';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                size: 22,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '牧工${worker.assignedAt != null ? ' · 入职 ${worker.assignedAt}' : ''}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            // Status tag
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    size: 14,
                    color: isActive
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? '在岗' : '离岗',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Remove button
            OutlinedButton(
              key: Key('b2b-remove-worker-${worker.id}'),
              onPressed: isBusy ? null : onRemove,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC2564B),
                side: const BorderSide(color: Color(0xFFC2564B)),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('移除', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWorkerState extends StatelessWidget {
  const _EmptyWorkerState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_add_outlined, size: 48, color: theme.disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            '暂无牧工，可通过上方按钮分配',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ViewState fallback views
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: AppSpacing.md),
          Text('加载失败',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.error)),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(message, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _DetailEmptyView extends StatelessWidget {
  const _DetailEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: theme.disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text('暂无数据', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ForbiddenView extends StatelessWidget {
  const _ForbiddenView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 48, color: theme.disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text('无权限访问', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: theme.disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text('网络不可用', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
