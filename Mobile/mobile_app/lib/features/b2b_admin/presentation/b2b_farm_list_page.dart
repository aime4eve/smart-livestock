import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
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

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final regionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                TextFormField(
                  key: const Key('b2b-farm-owner-input'),
                  controller: ownerCtrl,
                  decoration: const InputDecoration(
                    labelText: '负责人',
                    hintText: '可选',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('b2b-farm-phone-input'),
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: '联系电话',
                    hintText: '可选',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('b2b-farm-region-input'),
                  controller: regionCtrl,
                  decoration: const InputDecoration(
                    labelText: '所在地区',
                    hintText: '可选',
                  ),
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
                : () => _handleCreate(
                      ctx,
                      formKey,
                      nameCtrl,
                      ownerCtrl,
                      phoneCtrl,
                      regionCtrl,
                    ),
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
      ),
    );
  }

  Future<void> _handleCreate(
    BuildContext dialogCtx,
    GlobalKey<FormState> formKey,
    TextEditingController nameCtrl,
    TextEditingController ownerCtrl,
    TextEditingController phoneCtrl,
    TextEditingController regionCtrl,
  ) async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _creating = true);

    final ok = await ref
        .read(b2bDashboardControllerProvider.notifier)
        .createFarm(
          nameCtrl.text.trim(),
          ownerName:
              ownerCtrl.text.trim().isEmpty ? null : ownerCtrl.text.trim(),
          contactPhone:
              phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
          region:
              regionCtrl.text.trim().isEmpty ? null : regionCtrl.text.trim(),
        );

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
}
