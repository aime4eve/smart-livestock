import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_worker_management_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class B2bWorkerManagementPage extends ConsumerWidget {
  const B2bWorkerManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(b2bWorkerManagementControllerProvider);
    final controller =
        ref.read(b2bWorkerManagementControllerProvider.notifier);

    return SingleChildScrollView(
      key: const Key('page-b2b-worker-management'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '牧工管理',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '管理旗下各牧场的牧工',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (data.viewState == ViewState.normal)
            ...data.subFarms.map((farm) =>
                _buildSubFarmCard(context, farm, controller)),
          if (data.viewState == ViewState.empty)
            const SizedBox(
              height: 200,
              child: Center(child: Text('暂无牧场')),
            ),
          if (data.viewState == ViewState.loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSubFarmCard(
    BuildContext context,
    B2bSubFarm farm,
    B2bWorkerManagementController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HighfiCard(
        key: Key('b2b-farm-${farm.id}'),
        child: ListTile(
          key: Key('b2b-farm-tile-${farm.id}'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.agriculture,
            color: AppColors.primary,
          ),
          title: Text(
            farm.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle:
              Text('牧工 ${farm.workerCount} 人 | 牲畜 ${farm.livestockCount} 头'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final workers = controller.getSubFarmWorkers(farm.id);
            _showWorkersDialog(context, farm.name, workers);
          },
        ),
      ),
    );
  }

  void _showWorkersDialog(
    BuildContext context,
    String farmName,
    List<B2bSubFarmWorker> workers,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('b2b-workers-dialog'),
        title: Text(farmName),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('牧工总数: ${workers.length}'),
              const SizedBox(height: AppSpacing.md),
              if (workers.isEmpty)
                const Text('暂无牧工')
              else
                ...workers.map((w) {
                  final isActive = w.status == 'active';
                  return ListTile(
                    key: Key('worker-${w.name}'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.person),
                    title: Text(w.name),
                    subtitle: Text(w.role),
                    trailing: HighfiStatusChip(
                      label: isActive ? '在岗' : '离岗',
                      color: isActive ? AppColors.success : AppColors.danger,
                      icon: isActive ? Icons.check_circle : Icons.cancel,
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('b2b-workers-dialog-close'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
