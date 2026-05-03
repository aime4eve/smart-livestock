import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_worker_management_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_worker_management_controller.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/widgets/confirm_dialog.dart';

class B2bWorkerManagementPage extends ConsumerWidget {
  const B2bWorkerManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(b2bWorkerManagementControllerProvider);
    final theme = Theme.of(context);

    return switch (data.viewState) {
      ViewState.loading => const Center(
          key: Key('b2b-worker-mgmt-loading'),
          child: CircularProgressIndicator(),
        ),
      ViewState.error => Center(
          key: const Key('b2b-worker-mgmt-error'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text('加载失败',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.error)),
              if (data.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(data.message!, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ViewState.empty => Center(
          key: const Key('b2b-worker-mgmt-empty'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: theme.disabledColor),
              const SizedBox(height: AppSpacing.md),
              Text('暂无数据', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ViewState.forbidden => Center(
          key: const Key('b2b-worker-mgmt-forbidden'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: theme.disabledColor),
              const SizedBox(height: AppSpacing.md),
              Text('无权限访问', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ViewState.offline => Center(
          key: const Key('b2b-worker-mgmt-offline'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: theme.disabledColor),
              const SizedBox(height: AppSpacing.md),
              Text('网络不可用', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ViewState.normal => _buildContent(context, data),
    };
  }

  Widget _buildContent(BuildContext context, B2bWorkerManagementViewData data) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const Key('page-b2b-worker-management'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Page header ---
          Text(
            '牧工管理',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Summary metrics (3 columns) ---
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  key: const Key('b2b-metric-farms'),
                  label: '旗下牧场',
                  value: '${data.subFarms.length}',
                  backgroundColor: const Color(0xFFE8F5E9),
                  textColor: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  key: const Key('b2b-metric-total-workers'),
                  label: '总牧工',
                  value: '${data.totalWorkers}',
                  backgroundColor: const Color(0xFFE3F2FD),
                  textColor: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  key: const Key('b2b-metric-offline'),
                  label: '离岗',
                  value: '${data.offlineWorkerCount}',
                  backgroundColor: const Color(0xFFFFF3E0),
                  textColor: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Batch assign entry card ---
          Material(
            key: const Key('b2b-batch-assign-card'),
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                B2bConfirmDialog.show(
                  context,
                  title: '功能开发中',
                  subtitle: '批量分配功能即将上线',
                  confirmLabel: '知道了',
                  cancelLabel: '关闭',
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_add_outlined,
                        size: 22,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '批量分配牧工',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '选择牧工并分配到指定牧场',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Farm cards list ---
          ...data.subFarms.map((farm) => _FarmCard(
                key: Key('b2b-farm-${farm.id}'),
                farm: farm,
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  const _FarmCard({
    super.key,
    required this.farm,
  });

  final B2bSubFarm farm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final path = AppRoute.b2bWorkerDetail.path.replaceFirst(
              ':farmId',
              farm.id,
            );
            context.go(path);
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                // Agriculture icon box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.agriculture_outlined,
                    size: 24,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Farm info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _FarmStatChip(
                            icon: Icons.groups_outlined,
                            label: '${farm.workerCount}',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FarmStatChip(
                            icon: Icons.pets_outlined,
                            label: '${farm.livestockCount}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Worker count tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${farm.workerCount} 人',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FarmStatChip extends StatelessWidget {
  const _FarmStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).hintColor),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}
