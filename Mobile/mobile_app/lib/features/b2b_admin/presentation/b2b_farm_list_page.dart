import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
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
          // ── Header row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('旗下牧场', style: theme.textTheme.titleLarge),
              FilledButton.icon(
                key: const Key('b2b-create-farm'),
                onPressed: _creating ? null : _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新建牧场'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Summary strip ──
          _SummaryStrip(data: data, totalWorkers: data.farms.fold<int>(0, (s, f) => s + f.workerCount)),
          const SizedBox(height: AppSpacing.lg),

          // ── Farm list ──
          if (data.farms.isEmpty)
            _EmptyState(onCreate: _creating ? null : _showCreateDialog)
          else
            ...data.farms.map((farm) => _FarmCard(
              farm: farm,
              onTap: () => context.go(
                '${AppRoute.b2bAdmin.path}/workers/${farm.id}',
              ),
              onChangeOwner: () => _showChangeOwnerDialog(farm),
              onEditName: () => _showEditNameDialog(farm),
            )),
        ],
      ),
    );
  }

  // ── Create dialog (P2: enhanced with optional fields) ───────

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
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
                            hintText: '选择 owner 用户（可选）',
                          ),
                          items: [
                            const DropdownMenuItem<B2bUserSummary?>(
                              value: null,
                              child: Text('— 暂不指定 —'),
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
                      const SizedBox(height: 8),

                      // ── Optional fields divider ──
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('以下选填', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: latCtrl,
                              decoration: const InputDecoration(
                                labelText: '纬度',
                                hintText: '例 28.2458',
                                isDense: true,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: lngCtrl,
                              decoration: const InputDecoration(
                                labelText: '经度',
                                hintText: '例 112.8519',
                                isDense: true,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: areaCtrl,
                        decoration: const InputDecoration(
                          labelText: '面积（公顷）',
                          hintText: '例 100',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: _creating
                      ? null
                      : () => _handleCreate(ctx, formKey, nameCtrl, latCtrl, lngCtrl, areaCtrl, selectedOwner),
                  child: _creating
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
    TextEditingController latCtrl,
    TextEditingController lngCtrl,
    TextEditingController areaCtrl,
    B2bUserSummary? selectedOwner,
  ) async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _creating = true);

    final navigator = Navigator.of(dialogCtx);
    final messenger = ScaffoldMessenger.of(context);

    final body = <String, dynamic>{
      'name': nameCtrl.text.trim(),
      if (selectedOwner != null) 'ownerId': selectedOwner.id,
      if (latCtrl.text.isNotEmpty) 'latitude': double.tryParse(latCtrl.text),
      if (lngCtrl.text.isNotEmpty) 'longitude': double.tryParse(lngCtrl.text),
      if (areaCtrl.text.isNotEmpty) 'areaHectares': double.tryParse(areaCtrl.text),
    };

    final ok = await ref
        .read(b2bDashboardControllerProvider.notifier)
        .createFarm(body);

    if (!mounted) return;

    navigator.pop();
    setState(() => _creating = false);

    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('牧场「${nameCtrl.text.trim()}」创建成功'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('创建失败，请重试'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  // ── Edit name dialog ───────────────────────────────────────

  void _showEditNameDialog(B2bFarmSummary farm) {
    final nameCtrl = TextEditingController(text: farm.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          key: Key('b2b-edit-name-dialog-${farm.id}'),
          title: const Text('编辑牧场名称'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '牧场名称',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '名称不能为空' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                // TODO: call rename API when PUT /farms/{id} is fully implemented
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('「${farm.name}」重命名功能开发中')),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // ── Change owner dialog ────────────────────────────────────

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
    final navigator = Navigator.of(dialogCtx);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await ref
        .read(b2bDashboardControllerProvider.notifier)
        .changeOwner(farm.id, newOwner.id);

    if (!mounted) return;

    navigator.pop();

    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('「${farm.name}」负责人已变更为 ${newOwner.name}'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('变更失败，请重试'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  Widgets
// ═══════════════════════════════════════════════════════════════

/// ── Summary strip ────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.data, required this.totalWorkers});

  final B2bDashboardData data;
  final int totalWorkers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _StatChip(label: '牧场', value: '${data.totalFarms}', icon: Icons.landscape_outlined),
          _StatChip(label: '牲畜', value: '${data.totalLivestock}', icon: Icons.pets_outlined),
          _StatChip(label: '牧工', value: '$totalWorkers', icon: Icons.groups_outlined),
          _StatChip(label: '设备', value: '${data.totalDevices}', icon: Icons.sensors_outlined),
          _StatChip(label: '告警', value: '${data.pendingAlerts}', icon: Icons.notification_important_outlined, highlight: data.pendingAlerts > 0),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: highlight ? AppColors.danger : AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: highlight ? AppColors.danger : AppColors.textPrimary,
          )),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// ── Farm card (P2: PopupMenuButton) ─────────────────────────
class _FarmCard extends StatelessWidget {
  const _FarmCard({
    required this.farm,
    required this.onTap,
    required this.onChangeOwner,
    required this.onEditName,
  });

  final B2bFarmSummary farm;
  final VoidCallback onTap;
  final VoidCallback onChangeOwner;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: Key('b2b-farm-${farm.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.agriculture_outlined, size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(farm.name,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('负责人: ${farm.ownerName.isEmpty ? "未指定" : farm.ownerName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _MetricChip(icon: Icons.pets_outlined, value: '${farm.livestockCount}', label: '牲畜'),
                          const SizedBox(width: AppSpacing.md),
                          _MetricChip(icon: Icons.groups_outlined, value: '${farm.workerCount}', label: '牧工'),
                          const SizedBox(width: AppSpacing.md),
                          _MetricChip(icon: Icons.sensors_outlined, value: '${farm.deviceCount}', label: '设备'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status + Menu
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('正常', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.success)),
                    ),
                    // PopupMenuButton
                    PopupMenuButton<String>(
                      key: Key('b2b-farm-menu-${farm.id}'),
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onSelected: (action) {
                        switch (action) {
                          case 'change_owner':
                            onChangeOwner();
                            break;
                          case 'edit_name':
                            onEditName();
                            break;
                          case 'view_workers':
                            onTap();
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'view_workers',
                          child: Row(
                            children: [
                              Icon(Icons.groups_outlined, size: 18, color: AppColors.textSecondary),
                              SizedBox(width: 8),
                              Text('查看牧工'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'change_owner',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz, size: 18, color: AppColors.textSecondary),
                              SizedBox(width: 8),
                              Text('变更负责人'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit_name',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                              SizedBox(width: 8),
                              Text('编辑名称'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Text('$value$label', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// ── Empty state ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.agriculture_outlined, size: 64, color: AppColors.border),
            const SizedBox(height: AppSpacing.lg),
            Text('暂无旗下牧场', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text('点击右上角「新建牧场」开始', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新建牧场'),
            ),
          ],
        ),
      ),
    );
  }
}
