import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/features/mine/presentation/mine_controller.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/widgets/subscription_status_card.dart';

class MinePage extends ConsumerWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(mineControllerProvider);
    final role = ref.watch(sessionControllerProvider).role;
    
    return SingleChildScrollView(
      key: const Key('page-mine'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          asyncProfile.when(
            data: (profile) => _buildProfileSection(profile, context),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          ),
          
          if (role == UserRole.owner) ...[
            const SizedBox(height: AppSpacing.lg),
            const SubscriptionStatusCard(),
            const SizedBox(height: AppSpacing.xl),
            
            // 业务管理功能
            _buildBusinessManagement(context),
            const SizedBox(height: AppSpacing.xl),
            
            // 高级管理功能  
            _buildAdvancedManagement(context),
          ],
          
          const SizedBox(height: AppSpacing.xl),
          
          // 退出登录
          _buildLogoutSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildProfileSection(profile, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighfiCard(
          key: const Key('mine-profile-card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('我的',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  HighfiStatusChip(
                    label: profile.active == true ? '账户正常' : '账户已停用',
                    color: profile.active == true ? AppColors.success : AppColors.danger,
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (profile.displayName != null)
                Text('姓名：${profile.displayName!}',
                    style: Theme.of(context).textTheme.bodyMedium),
              if (profile.phone != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('手机号：${profile.phone!}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
              if (profile.role != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('角色：${profile.role!}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // 个人设备和工具
        Text(
          '个人设备与工具',
          style: Theme.of(context).textTheme.titleMedium,
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
        
        HighfiCard(
          child: ListTile(
            key: const Key('mine-offline-maps'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.map_outlined),
            title: const Text('离线地图管理'),
            subtitle: const Text('下载和管理离线瓦片数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.offlineTileManagement.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        HighfiCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.headset_mic_outlined),
            title: const Text('帮助与支持'),
            subtitle: const Text('查看设备绑定、帮助文档与联系客服入口'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现帮助与支持页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('帮助与支持页面开发中...')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessManagement(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '业务管理',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        
        // 订阅管理
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
        
        // 对账看板
        HighfiCard(
          child: ListTile(
            key: const Key('mine-revenue'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('对账看板'),
            subtitle: const Text('查看各周期分润对账数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformRevenue.path),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // 订阅服务管理
        HighfiCard(
          child: ListTile(
            key: const Key('mine-subscriptions'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.subscriptions_outlined),
            title: const Text('订阅服务管理'),
            subtitle: const Text('管理订阅套餐和业务服务'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoute.platformSubscriptions.path),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedManagement(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '高级管理',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        
        // 牧工管理
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
        
        // API授权管理
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
    );
  }

  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) {
    return HighfiCard(
      child: ListTile(
        key: const Key('mine-logout'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.logout, color: AppColors.danger),
        title: const Text('退出登录',
            style: TextStyle(color: AppColors.danger)),
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('确认退出'),
              content: const Text('确定要退出登录吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(sessionControllerProvider.notifier).logout();
                  },
                  child: const Text('退出',
                      style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
