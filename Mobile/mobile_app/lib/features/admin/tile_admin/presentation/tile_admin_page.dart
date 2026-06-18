import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/tile_admin/domain/tile_admin_models.dart';
import 'package:hkt_livestock_agentic/features/admin/tile_admin/presentation/tile_admin_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class TileAdminPage extends ConsumerStatefulWidget {
  const TileAdminPage({super.key});

  @override
  ConsumerState<TileAdminPage> createState() => _TileAdminPageState();
}

class _TileAdminPageState extends ConsumerState<TileAdminPage> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // 有 pending/running 任务时轮询刷新，让进展实时可见
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) ref.read(tileAdminControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(tileAdminControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tileAdminTitle)),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('$e'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(tileAdminControllerProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (data) => DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: l10n.tileAdminRegionsTab),
                  Tab(text: l10n.tileAdminTasksTab),
                  Tab(text: l10n.tileAdminFarmTab),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _RegionsTab(regions: data.regions),
                    _TasksTab(tasks: data.tasks),
                    _FarmTasksTab(farmTasks: data.farmTasks),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.tileAdminCreateTask),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _CreateTaskDialog(
            onCreated: () => ref.read(tileAdminControllerProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }
}

class _RegionsTab extends ConsumerWidget {
  const _RegionsTab({required this.regions});
  final List<TileRegion> regions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.tileAdminRegionsTab, style: Theme.of(context).textTheme.titleMedium),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.tileAdminReload),
                onPressed: () => ref.read(tileAdminControllerProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        Expanded(
          child: regions.isEmpty
              ? Center(child: Text(l10n.tileAdminNoRegions))
              : ListView.separated(
                  itemCount: regions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = regions[index];
                    return ListTile(
                      leading: const Icon(Icons.map_outlined),
                      title: Text(r.name),
                      subtitle: Text('zoom ${r.minZoom}-${r.maxZoom} | ${r.fileSizeLabel} | ${r.status ?? "-"}'),
                      trailing: Text(
                          '[${r.minLon.toStringAsFixed(2)}, ${r.minLat.toStringAsFixed(2)}] ~ [${r.maxLon.toStringAsFixed(2)}, ${r.maxLat.toStringAsFixed(2)}]',
                          style: Theme.of(context).textTheme.bodySmall),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.tasks});
  final List<TileTask> tasks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (tasks.isEmpty) {
      return Center(child: Text(l10n.tileAdminNoTasks));
    }
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final TileTask task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final status = task.status ?? 'pending';
    final isRunning = status == 'running';
    final isDone = status == 'done';
    final isFailed = status == 'failed';
    final color = isDone
        ? AppColors.success
        : isFailed
            ? AppColors.danger
            : isRunning
                ? AppColors.warning
                : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRunning
                    ? Icons.sync
                    : (isDone ? Icons.check_circle : Icons.task_outlined),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(task.regionName ?? 'Task #${task.id}',
                    style: theme.textTheme.titleSmall),
              ),
              if (isRunning)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                      width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              Chip(
                label: Text(status, style: TextStyle(color: color, fontSize: 11)),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isRunning && task.progress != null) ...[
            Text(task.progress!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: task.progressValue, minHeight: 6),
          ] else if (isDone)
            Text(
              '${task.tileCount} ${l10n.tileAdminTilesUnit} · ${task.fileSizeMb.toStringAsFixed(1)} MB',
              style: theme.textTheme.bodySmall,
            )
          else if (isFailed && task.errorMessage != null)
            Text('${l10n.tileAdminErrorPrefix}${task.errorMessage}',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger))
          else if (status == 'pending')
            Text(l10n.tileAdminTaskPending, style: theme.textTheme.bodySmall),
          if (task.startedAt != null) ...[
            const SizedBox(height: 4),
            Text(_elapsedLabel(l10n),
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  String _elapsedLabel(AppLocalizations l10n) {
    final start = DateTime.tryParse(task.startedAt ?? '');
    if (start == null) return '';
    final end = DateTime.tryParse(task.finishedAt ?? '') ?? DateTime.now().toUtc();
    final d = end.difference(start);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final dur = h > 0 ? '${h}h${m}m' : (m > 0 ? '${m}m${s}s' : '${s}s');
    return task.finishedAt != null ? l10n.tileAdminDuration(dur) : l10n.tileAdminRunningFor(dur);
  }
}

class _FarmTasksTab extends StatelessWidget {
  const _FarmTasksTab({required this.farmTasks});
  final List<FarmTileStatus> farmTasks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (farmTasks.isEmpty) {
      return Center(child: Text(l10n.tileAdminNoFarmTiles));
    }
    return ListView.separated(
      itemCount: farmTasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final f = farmTasks[index];
        return ListTile(
          leading: const Icon(Icons.agriculture_outlined),
          title: Text(f.farmName),
          subtitle: Text('${l10n.tileAdminRegionInfo(f.regionName ?? '-', f.tileStatus ?? '-')}'
            '${f.lastDownloadAt != null ? "\nLast download: ${f.lastDownloadAt}" : ""}'),
        );
      },
    );
  }
}

class _CreateTaskDialog extends ConsumerStatefulWidget {
  const _CreateTaskDialog({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<_CreateTaskDialog> {
  final _regionName = TextEditingController();
  final _minLon = TextEditingController(text: '112.80');
  final _minLat = TextEditingController(text: '28.10');
  final _maxLon = TextEditingController(text: '113.10');
  final _maxLat = TextEditingController(text: '28.40');
  final _minZoom = TextEditingController(text: '11');
  final _maxZoom = TextEditingController(text: '15');
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_regionName, _minLon, _minLat, _maxLon, _maxLat, _minZoom, _maxZoom]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _regionName.text.trim();
    final minLon = double.tryParse(_minLon.text);
    final minLat = double.tryParse(_minLat.text);
    final maxLon = double.tryParse(_maxLon.text);
    final maxLat = double.tryParse(_maxLat.text);
    if (name.isEmpty || [minLon, minLat, maxLon, maxLat].any((v) => v == null)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tileAdminCreateFailed)));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(tileAdminRepositoryProvider).createTask({
        'regionName': name,
        'minLon': minLon,
        'minLat': minLat,
        'maxLon': maxLon,
        'maxLat': maxLat,
        'minZoom': int.tryParse(_minZoom.text) ?? 11,
        'maxZoom': int.tryParse(_maxZoom.text) ?? 15,
        'isCustomRegion': true,
      });
      widget.onCreated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tileAdminCreateSuccess)));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tileAdminCreateFailed)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _numField(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextField(
          controller: c,
          decoration: InputDecoration(labelText: label, isDense: true),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.tileAdminCreateTask),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _regionName,
                decoration: InputDecoration(labelText: l10n.tileAdminRegionNameLabel, isDense: true),
              ),
              const SizedBox(height: 8),
              Text(l10n.tileAdminBoundsHint, style: Theme.of(context).textTheme.bodySmall),
              _numField(_minLon, 'minLon'),
              _numField(_minLat, 'minLat'),
              _numField(_maxLon, 'maxLon'),
              _numField(_maxLat, 'maxLat'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _numField(_minZoom, l10n.tileAdminMinZoomLabel)),
                  const SizedBox(width: 8),
                  Expanded(child: _numField(_maxZoom, l10n.tileAdminMaxZoomLabel)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
        FilledButton(onPressed: _submitting ? null : _submit, child: Text(l10n.commonSubmit)),
      ],
    );
  }
}
