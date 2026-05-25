import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/worker_management/domain/worker_repository.dart';
import 'package:smart_livestock_demo/features/worker_management/presentation/worker_controller.dart';

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
        title: const Text('牧工管理'),
        leading: BackButton(
          key: const Key('worker-management-back'),
          onPressed: () => context.go(AppRoute.mine.path),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: farmState.activeFarmId == null
            ? const HighfiEmptyErrorState(
                key: Key('worker-empty-state'),
                title: '暂无可管理牧场',
                description: '当前账号尚未选择牧场。',
                icon: Icons.agriculture_outlined,
              )
            : asyncData.when(
                data: (workers) => workers.isEmpty
                    ? const HighfiEmptyErrorState(
                        key: Key('worker-empty-state'),
                        title: '暂无牧工',
                        description: '当前牧场还没有分配牧工。',
                        icon: Icons.people_outline,
                      )
                    : ListView.separated(
                        key: const Key('worker-list'),
                        itemCount: workers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          return _WorkerListItem(
                            assignment: workers[index],
                            farmId: farmState.activeFarmId!,
                          );
                        },
                      ),
                loading: () => const Center(
                    child: CircularProgressIndicator(key: Key('worker-loading-state')),
                  ),
                error: (e, _) => HighfiEmptyErrorState(
                    key: const Key('worker-error-state'),
                    title: '牧工加载失败',
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
}

class _WorkerListItem extends ConsumerWidget {
  const _WorkerListItem({
    required this.assignment,
    required this.farmId,
  });

  final WorkerAssignment assignment;
  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HighfiCard(
      key: Key('worker-${assignment.id}'),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          foregroundColor: AppColors.primary,
          child: Icon(Icons.badge_outlined),
        ),
        title: Text(assignment.userName),
        subtitle: Text('角色：${assignment.role}'),
        trailing: IconButton(
          key: Key('worker-remove-${assignment.id}'),
          tooltip: '移除牧工',
          color: AppColors.danger,
          icon: const Icon(Icons.person_remove_alt_1_outlined),
          onPressed: () {
            ref
                .read(workerControllerProvider.notifier)
                .removeWorker(farmId, assignment.userId);
          },
        ),
      ),
    );
  }
}
