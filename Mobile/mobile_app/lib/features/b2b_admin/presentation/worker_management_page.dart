import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class B2bWorkerManagementPage extends ConsumerWidget {
  const B2bWorkerManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _buildSubFarmList(context),
        ],
      ),
    );
  }

  Widget _buildSubFarmList(BuildContext context) {
    final farms = [
      {
        'id': 'sf_001',
        'name': '华东示范牧场 - 一分场',
        'workerCount': 8,
        'livestockCount': 200,
      },
      {
        'id': 'sf_002',
        'name': '华东示范牧场 - 二分场',
        'workerCount': 5,
        'livestockCount': 150,
      },
      {
        'id': 'sf_003',
        'name': '华东示范牧场 - 三分场',
        'workerCount': 12,
        'livestockCount': 300,
      },
    ];

    return Column(
      children: farms.map((farm) {
        final workerCount = farm['workerCount'] as int;
        final livestockCount = farm['livestockCount'] as int;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: HighfiCard(
            key: Key('b2b-farm-${farm['id']}'),
            child: ListTile(
              key: Key('b2b-farm-tile-${farm['id']}'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.agriculture,
                color: AppColors.primary,
              ),
              title: Text(
                farm['name'] as String,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('牧工 $workerCount 人 | 牲畜 $livestockCount 头'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showWorkersDialog(context, farm['name'] as String, workerCount, livestockCount);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showWorkersDialog(
    BuildContext context,
    String farmName,
    int workerCount,
    int livestockCount,
  ) {
    final workers = [
      {'name': '张牧工', 'role': '牧工主管', 'status': 'active'},
      {'name': '李牧工', 'role': '牧工', 'status': 'active'},
      {'name': '王牧工', 'role': '牧工', 'status': 'active'},
      {'name': '赵牧工', 'role': '牧工', 'status': 'inactive'},
    ];

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
              Text('牧工总数: $workerCount | 牲畜: $livestockCount 头'),
              const SizedBox(height: AppSpacing.md),
              ...workers.take(workerCount.clamp(0, workers.length)).map((w) {
                final isActive = w['status'] == 'active';
                return ListTile(
                  key: Key('worker-${w['name']}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.person),
                  title: Text(w['name'] as String),
                  subtitle: Text(w['role'] as String),
                  trailing: HighfiStatusChip(
                    label: isActive ? '在岗' : '离岗',
                    color: isActive ? AppColors.success : AppColors.danger,
                    icon:
                        isActive ? Icons.check_circle : Icons.cancel,
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
