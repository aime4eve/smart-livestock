import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/tile_admin/domain/tile_admin_models.dart';
import 'package:hkt_livestock_agentic/features/admin/tile_admin/presentation/tile_admin_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class TileAdminPage extends ConsumerWidget {
  const TileAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      itemBuilder: (context, index) {
        final t = tasks[index];
        final statusColor = switch (t.status) {
          'COMPLETED' => AppColors.success,
          'FAILED' => AppColors.danger,
          'PROCESSING' => AppColors.warning,
          _ => AppColors.textSecondary,
        };
        return ListTile(
          leading: Icon(Icons.task_outlined, color: statusColor),
          title: Text(t.regionName ?? 'Task #${t.id}'),
          subtitle: Text('${l10n.tileAdminStatusInfo(t.status ?? '-', t.tileCount.toString(), t.fileSizeMb.toStringAsFixed(1))}'
            '${t.errorMessage != null ? "\nError: ${t.errorMessage}" : ""}'),
          trailing: Chip(label: Text(t.status ?? '-', style: TextStyle(color: statusColor, fontSize: 11))),
        );
      },
    );
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
