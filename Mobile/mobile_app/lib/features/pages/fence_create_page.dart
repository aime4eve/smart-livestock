import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence_create/domain/fence_create_repository.dart';
import 'package:smart_livestock_demo/features/fence_create/presentation/fence_create_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';

class FenceCreatePage extends ConsumerWidget {
  const FenceCreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(fenceCreateControllerProvider);
    final controller = ref.read(fenceCreateControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建围栏'),
        leading: IconButton(
          key: const Key('fence-create-back'),
          onPressed: () => context.go(AppRoute.fence.path),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        key: const Key('page-fence-create'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (data.viewState == ViewState.normal ||
                data.viewState == ViewState.error)
              _buildForm(context, data, controller)
            else
              _buildNonNormal(data),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    FenceCreateViewData data,
    FenceCreateController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighfiCard(
          key: const Key('fence-create-info'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('基本信息', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('fence-create-name'),
                decoration: const InputDecoration(
                  labelText: '围栏名称',
                  border: OutlineInputBorder(),
                ),
                onChanged: controller.setName,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<FenceType>(
                key: const Key('fence-create-type'),
                initialValue: data.fenceType,
                decoration: const InputDecoration(
                  labelText: '围栏类型',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: FenceType.rectangle, child: Text('矩形')),
                  DropdownMenuItem(value: FenceType.circle, child: Text('圆形')),
                  DropdownMenuItem(
                      value: FenceType.polygon, child: Text('多边形')),
                ],
                onChanged: (value) {
                  if (value != null) controller.setFenceType(value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        HighfiCard(
          key: const Key('fence-create-area'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('围栏范围', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '面积：${data.areaHectares?.toStringAsFixed(1) ?? '0.0'} 公顷',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F2E5), Color(0xFFF8F6F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.draw_outlined,
                          size: 32, color: AppColors.primary),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '地图选区（占位）',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        HighfiCard(
          key: const Key('fence-create-alert'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('告警设置', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                key: const Key('fence-create-enter-alert'),
                contentPadding: EdgeInsets.zero,
                title: const Text('进入告警'),
                subtitle: const Text('牲畜进入围栏时触发告警'),
                value: data.enterAlert,
                onChanged: controller.setEnterAlert,
              ),
              SwitchListTile(
                key: const Key('fence-create-leave-alert'),
                contentPadding: EdgeInsets.zero,
                title: const Text('离开告警'),
                subtitle: const Text('牲畜离开围栏时触发告警'),
                value: data.leaveAlert,
                onChanged: controller.setLeaveAlert,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (data.saved)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              '演示：围栏已保存（本地）',
              key: Key('fence-create-saved'),
            ),
          ),
        if (data.viewState == ViewState.error)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              data.message ?? '保存失败',
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('fence-create-cancel'),
                onPressed: () => context.go(AppRoute.fence.path),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('fence-create-save'),
                onPressed: data.saving ? null : controller.save,
                child: data.saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存围栏'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNonNormal(FenceCreateViewData data) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '无法创建围栏',
          description: '当前无可用的围栏模板。',
          icon: Icons.fence_outlined,
        );
      case ViewState.forbidden:
        return const HighfiEmptyErrorState(
          title: '无权限创建围栏',
          description: '仅牧场主可创建围栏。',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '离线模式',
          description: data.message ?? '离线状态下无法创建围栏。',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.error:
      case ViewState.normal:
        return const SizedBox.shrink();
    }
  }
}
