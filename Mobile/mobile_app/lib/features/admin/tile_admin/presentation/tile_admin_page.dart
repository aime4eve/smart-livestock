import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/admin/tile_admin/domain/tile_admin_models.dart';
import 'package:smart_livestock_demo/features/admin/tile_admin/presentation/tile_admin_controller.dart';

class TileAdminPage extends ConsumerWidget {
  const TileAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(tileAdminControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('瓦片管理')),
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
                label: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (data) => DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: '区域管理'),
                  Tab(text: '任务管理'),
                  Tab(text: '牧场分配'),
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
    );
  }
}

class _RegionsTab extends StatelessWidget {
  const _RegionsTab({required this.regions});
  final List<TileRegion> regions;

  @override
  Widget build(BuildContext context) {
    if (regions.isEmpty) {
      return const Center(child: Text('暂无瓦片区域'));
    }
    return ListView.separated(
      itemCount: regions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = regions[index];
        return ListTile(
          leading: const Icon(Icons.map_outlined),
          title: Text(r.name),
          subtitle: Text('zoom ${r.minZoom}-${r.maxZoom} | ${r.fileSizeLabel} | ${r.status ?? "-"}'),
          trailing: Text('[${r.minLon.toStringAsFixed(2)}, ${r.minLat.toStringAsFixed(2)}] ~ [${r.maxLon.toStringAsFixed(2)}, ${r.maxLat.toStringAsFixed(2)}]',
            style: Theme.of(context).textTheme.bodySmall),
        );
      },
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.tasks});
  final List<TileTask> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('暂无瓦片任务'));
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
          subtitle: Text('状态: ${t.status ?? "-"} | 瓦片: ${t.tileCount} | ${t.fileSizeMb.toStringAsFixed(1)}MB'
            '${t.errorMessage != null ? "\n错误: ${t.errorMessage}" : ""}'),
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
    if (farmTasks.isEmpty) {
      return const Center(child: Text('暂无牧场瓦片分配'));
    }
    return ListView.separated(
      itemCount: farmTasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final f = farmTasks[index];
        return ListTile(
          leading: const Icon(Icons.agriculture_outlined),
          title: Text(f.farmName),
          subtitle: Text('区域: ${f.regionName ?? "-"} | 状态: ${f.tileStatus ?? "-"}'
            '${f.lastDownloadAt != null ? "\n最后下载: ${f.lastDownloadAt}" : ""}'),
        );
      },
    );
  }
}
