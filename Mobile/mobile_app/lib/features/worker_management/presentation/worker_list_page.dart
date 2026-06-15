import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:hkt_livestock_agentic/features/worker_management/domain/worker_repository.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/features/worker_management/presentation/worker_controller.dart';

class WorkerListPage extends ConsumerStatefulWidget {
  const WorkerListPage({super.key});

  @override
  ConsumerState<WorkerListPage> createState() => _WorkerListPageState();
}

class _WorkerListPageState extends ConsumerState<WorkerListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActiveFarm());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<String?>(
      farmSwitcherControllerProvider.select((state) => state.activeFarmId),
      (previous, next) {
        if (next != null && next != previous) {
          ref.read(workerControllerProvider.notifier).loadWorkers(next);
        }
      },
    );

    final farmState = ref.watch(farmSwitcherControllerProvider);
    final asyncData = ref.watch(workerControllerProvider);

    return Scaffold(
      key: const Key('page-worker-management'),
      appBar: AppBar(
        title: Text(l10n.mineWorkerTitle),
        leading: BackButton(
          key: const Key('worker-management-back'),
          onPressed: () => context.go(AppRoute.mine.path),
        ),
        actions: [
          if (farmState.activeFarmId != null)
            IconButton(
              key: const Key('worker-add-btn'),
              icon: const Icon(Icons.person_add),
              tooltip: l10n.workerAddWorker,
              onPressed: () => _showCreateDialog(context, ref, farmState.activeFarmId!),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: farmState.activeFarmId == null
            ? HighfiEmptyErrorState(
                key: const Key('worker-empty-state'),
                title: l10n.workerNoFarm,
                description: l10n.workerNoFarmDesc,
                icon: Icons.agriculture_outlined,
              )
            : asyncData.when(
                data: (workers) => workers.isEmpty
                    ? HighfiEmptyErrorState(
                        key: const Key('worker-empty-state'),
                        title: l10n.workerNoWorkers,
                        description: l10n.workerNoWorkersDesc,
                        icon: Icons.people_outline,
                        actionLabel: l10n.workerAddWorker,
                        onAction: () => _showCreateDialog(context, ref, farmState.activeFarmId!),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(workerControllerProvider.notifier).loadWorkers(farmState.activeFarmId!),
                        child: ListView.separated(
                          key: const Key('worker-list'),
                          itemCount: workers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) => _WorkerCard(
                            assignment: workers[index],
                            farmId: farmState.activeFarmId!,
                          ),
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => HighfiEmptyErrorState(
                  key: const Key('worker-error-state'),
                  title: l10n.workerLoadFailed,
                  description: e.toString(),
                  icon: Icons.error_outline,
                ),
              ),
      ),
    );
  }

  void _loadActiveFarm() {
    if (!mounted) return;
    final farmId = ref.read(farmSwitcherControllerProvider).activeFarmId;
    if (farmId == null) return;
    ref.read(workerControllerProvider.notifier).loadWorkers(farmId);
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, String farmId) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workerNewWorker),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.workerName, isDense: true, border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.workerNameRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(labelText: l10n.authPhoneLabel, isDense: true, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.workerPhoneRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pwdCtrl,
                  decoration: InputDecoration(labelText: l10n.workerInitPassword, isDense: true, border: const OutlineInputBorder()),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 3) ? l10n.workerPasswordMinLength : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
          ElevatedButton(
            key: const Key('worker-create-submit'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await ref.read(workerControllerProvider.notifier).createWorker(
                  farmId,
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  password: pwdCtrl.text,
                );
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.workerCreateSuccess)));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.workerCreateFailed(e.toString()))));
              }
            },
            child: Text(l10n.adminApiAuthCreate),
          ),
        ],
      ),
    );
  }
}

class _WorkerCard extends ConsumerWidget {
  const _WorkerCard({required this.assignment, required this.farmId});

  final WorkerAssignment assignment;
  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = assignment.status.toLowerCase() == 'active';
    final isOwner = assignment.role.toUpperCase() == 'OWNER';

    return HighfiCard(
      key: Key('worker-${assignment.userId}'),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              child: Text(assignment.userName.isNotEmpty ? assignment.userName[0] : '?'),
            ),
            title: Text(assignment.userName),
            subtitle: Text(_subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? '在岗' : '停用',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? AppColors.success : AppColors.warning),
                  ),
                ),
                if (!isOwner) IconButton(
                  key: Key('worker-more-${assignment.userId}'),
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showActions(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[];
    if (assignment.phone != null) parts.add(assignment.phone!);
    parts.add(isOwner ? '负责人' : '牧工');
    return parts.join(' · ');
  }

  bool get isOwner => assignment.role.toUpperCase() == 'OWNER';

  void _showActions(BuildContext context, WidgetRef ref) {
    final isActive = assignment.status.toLowerCase() == 'active';
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑信息'),
              onTap: () { Navigator.pop(ctx); _showEditDialog(context, ref); },
            ),
            ListTile(
              leading: Icon(isActive ? Icons.pause_circle_outline : Icons.play_circle_outline),
              title: Text(isActive ? '停用账号' : '启用账号'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(workerControllerProvider.notifier).toggleStatus(
                    farmId, assignment.userId, isActive ? 'disabled' : 'active',
                  );
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isActive ? '已停用' : '已启用')));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('重置密码'),
              onTap: () { Navigator.pop(ctx); _showResetPasswordDialog(context, ref); },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_remove_alt_1_outlined, color: AppColors.danger),
              title: const Text('移除牧工', style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('确认移除'),
                    content: Text('确定要将 ${assignment.userName} 从牧场移除吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('取消')),
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('移除', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await ref.read(workerControllerProvider.notifier).removeWorker(farmId, assignment.userId);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已移除')));
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('移除失败: $e')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: assignment.userName);
    final phoneCtrl = TextEditingController(text: assignment.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑牧工'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '姓名', isDense: true, border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? '姓名不能为空' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: '手机号', isDense: true, border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await ref.read(workerControllerProvider.notifier).updateWorker(
                  farmId, assignment.userId,
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已更新')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失败: $e')));
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, WidgetRef ref) {
    final pwdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置密码'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('为 ${assignment.userName} 设置新密码'),
              const SizedBox(height: 12),
              TextFormField(
                controller: pwdCtrl,
                decoration: const InputDecoration(labelText: '新密码', isDense: true, border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => (v == null || v.length < 3) ? '密码至少3位' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await ref.read(workerControllerProvider.notifier).resetPassword(farmId, assignment.userId, pwdCtrl.text);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码已重置')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重置失败: $e')));
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
