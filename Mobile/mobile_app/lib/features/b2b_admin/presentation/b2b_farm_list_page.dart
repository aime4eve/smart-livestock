import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';

class B2bFarmListPage extends ConsumerWidget {
  const B2bFarmListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(b2bDashboardControllerProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('旗下牧场', style: theme.textTheme.titleLarge),
              FilledButton.icon(
                key: const Key('b2b-create-farm'),
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('新建牧场'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (data.farms.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('暂无旗下牧场'),
              ),
            )
          else
            ...data.farms.map((farm) => Card(
                  child: ListTile(
                    key: Key('b2b-farm-${farm.id}'),
                    title: Text(farm.name),
                    subtitle: Text(
                      '负责人: ${farm.ownerName}\n${farm.region} · 牲畜: ${farm.livestockCount}',
                    ),
                    isThreeLine: true,
                    trailing: Chip(label: Text(farm.status)),
                  ),
                )),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建牧场'),
        content: TextField(
          key: const Key('b2b-farm-name-input'),
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '牧场名称',
            hintText: '请输入牧场名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已创建: ${nameController.text}')),
              );
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}
