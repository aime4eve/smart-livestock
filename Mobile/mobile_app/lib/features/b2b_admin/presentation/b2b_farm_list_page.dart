import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';

class B2bFarmListPage extends ConsumerStatefulWidget {
  const B2bFarmListPage({super.key});

  @override
  ConsumerState<B2bFarmListPage> createState() => _B2bFarmListPageState();
}

class _B2bFarmListPageState extends ConsumerState<B2bFarmListPage> {
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(b2bDashboardControllerProvider);

    return asyncData.when(
      data: (data) => _buildContent(context, data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('加载失败', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, B2bDashboardData data) {
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
                onPressed: _creating ? null : _showCreateDialog,
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
                      '负责人: ${farm.ownerName.isEmpty ? "未指定" : farm.ownerName}\n牲畜: ${farm.livestockCount}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('b2b-change-owner-${farm.id}'),
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: '变更负责人',
                          onPressed: () => _showChangeOwnerDialog(farm),
                        ),
                        Chip(label: Text(farm.status)),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    B2bUserSummary? selectedOwner;

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final ownerUsers = ref.watch(b2bOwnerUsersProvider);
            return AlertDialog(
              key: const Key('b2b-create-farm-dialog'),
              title: const Text('新建牧场'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        key: const Key('b2b-farm-name-input'),
                        controller: nameCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: '牧场名称 *',
                          hintText: '请输入牧场名称',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '牧场名称不能为空' : null,
                      ),
                      const SizedBox(height: 12),
                      ownerUsers.when(
                        data: (users) => DropdownButtonFormField<B2bUserSummary?>(
                          key: const Key('b2b-farm-owner-select'),
                          decoration: const InputDecoration(
                            labelText: '负责人',
                            hintText: '可选，从列表选择',
                          ),
                          items: [
                            const DropdownMenuItem<B2bUserSummary?>(
                              value: null,
                              child: Text('不指定'),
                            ),
                            ...users.map((u) => DropdownMenuItem<B2bUserSummary?>(
                              value: u,
                              child: Text('${u.name} (${u.phone})'),
                            )),
                          ],
                          onChanged: (v) => selectedOwner = v,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('加载用户列表失败'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _creating ? null : () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  key: const Key('b2b-create-farm-confirm-btn'),
                  onPressed: _creating
                      ? null
                      : () => _handleCreate(ctx, formKey, nameCtrl, selectedOwner),
                  child: _creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCreate(
    BuildContext dialogCtx,
    GlobalKey<FormState> formKey,
    TextEditingController nameCtrl,
    B2bUserSummary? selectedOwner,
  ) async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _creating = true);

    final body = <String, dynamic>{
      'name': nameCtrl.text.trim(),
      if (selectedOwner != null) 'ownerId': selectedOwner.id,
    };

    final ok = await ref
        .read(b2bDashboardControllerProvider.notifier)
        .createFarm(body);

    if (!mounted) return;

    Navigator.pop(dialogCtx);
    setState(() => _creating = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('牧场「${nameCtrl.text.trim()}」创建成功'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('创建失败，请重试'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  void _showChangeOwnerDialog(B2bFarmSummary farm) {
    B2bUserSummary? selectedOwner;

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final ownerUsers = ref.watch(b2bOwnerUsersProvider);
            return StatefulBuilder(
              builder: (context, dialogSetState) {
                return AlertDialog(
                  key: Key('b2b-change-owner-dialog-${farm.id}'),
                  title: Text('变更「${farm.name}」负责人'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('当前负责人: ${farm.ownerName.isEmpty ? "未指定" : farm.ownerName}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        ownerUsers.when(
                          data: (users) {
                            if (users.isEmpty) {
                              return const Text('当前租户无可用 owner 用户');
                            }
                            return DropdownButtonFormField<B2bUserSummary?>(
                              key: Key('b2b-owner-select-${farm.id}'),
                              decoration: const InputDecoration(
                                labelText: '新负责人',
                                hintText: '选择 owner 用户',
                              ),
                              items: users.map((u) => DropdownMenuItem<B2bUserSummary?>(
                                value: u,
                                child: Text('${u.name} (${u.phone})'),
                              )).toList(),
                              onChanged: (v) => dialogSetState(() => selectedOwner = v),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('加载用户列表失败'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      key: Key('b2b-change-owner-confirm-${farm.id}'),
                      onPressed: selectedOwner == null
                          ? null
                          : () => _handleChangeOwner(ctx, farm, selectedOwner!),
                      child: const Text('确认变更'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleChangeOwner(
    BuildContext dialogCtx,
    B2bFarmSummary farm,
    B2bUserSummary newOwner,
  ) async {
    final ok = await ref
        .read(b2bDashboardControllerProvider.notifier)
        .changeOwner(farm.id, newOwner.id);

    if (!mounted) return;

    Navigator.pop(dialogCtx);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${farm.name}」负责人已变更为 ${newOwner.name}'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('变更失败，请重试'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }
}
