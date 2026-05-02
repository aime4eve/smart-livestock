import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/mine/domain/mine_repository.dart';
import 'package:smart_livestock_demo/features/mine/presentation/mine_controller.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/widgets/subscription_status_card.dart';

class MinePage extends ConsumerWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(mineControllerProvider);
    final role = ref.watch(sessionControllerProvider).role;
    return SingleChildScrollView(
      key: const Key('page-mine'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStateBody(context, data),
          if (role == DemoRole.owner) ...[
            const SizedBox(height: AppSpacing.md),
            const SubscriptionStatusCard(),
            const SizedBox(height: AppSpacing.md),
            HighfiCard(
              child: ListTile(
                key: const Key('mine-subscription-manage'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.workspace_premium),
                title: const Text('订阅管理'),
                subtitle: const Text('查看和升级订阅套餐'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoute.subscriptionPlan.path),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HighfiCard(
              child: ListTile(
                key: const Key('mine-worker-management'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.groups_2_outlined),
                title: const Text('牧工管理'),
                subtitle: const Text('查看和移除当前牧场牧工'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoute.workerManagement.path),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HighfiCard(
              child: ListTile(
                key: const Key('mine-api-auth'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.api),
                title: const Text('API授权管理'),
                subtitle: const Text('管理 API Key 和第三方访问授权'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoute.mineApiAuth.path),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStateBody(BuildContext context, MineViewData data) {
    switch (data.viewState) {
      case ViewState.normal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HighfiCard(
              key: const Key('mine-profile-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('我的', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  const HighfiStatusChip(
                    label: '账户正常',
                    color: AppColors.success,
                    icon: Icons.verified_user_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(data.normalText),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HighfiCard(
              child: ListTile(
                key: const Key('mine-device-mgmt'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices),
                title: const Text('设备管理'),
                subtitle: const Text('查看和管理绑定的 IoT 设备'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoute.devices.path),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const HighfiCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.headset_mic_outlined),
                title: Text('帮助与支持'),
                subtitle: Text('查看设备绑定、帮助文档与联系客服入口'),
              ),
            ),
          ],
        );
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无个人数据',
          description: '当前账号尚未同步到本地演示数据。',
          icon: Icons.person_off_outlined,
        );
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '我的页加载失败',
          description: data.message ?? '',
          icon: Icons.error_outline,
        );
      case ViewState.forbidden:
        return HighfiEmptyErrorState(
          title: '无权限查看个人中心',
          description: data.message ?? '',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '离线个人快照',
          description: data.message ?? '',
          icon: Icons.cloud_off_rounded,
        );
    }
  }
}
