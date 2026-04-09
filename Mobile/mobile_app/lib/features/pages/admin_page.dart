import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/admin/domain/admin_repository.dart';
import 'package:smart_livestock_demo/features/admin/presentation/admin_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);
    return SingleChildScrollView(
      key: const Key('page-admin'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HighfiCard(
            key: const Key('admin-overview-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '租户后台占位',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '用于演示平台运维开通租户、禁用启用与 license 管理。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                const HighfiStatusChip(
                  label: 'ops / owner 演示入口',
                  color: AppColors.info,
                  icon: Icons.admin_panel_settings_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.viewState == ViewState.normal) ...[
            HighfiCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    key: const Key('tenant-open'),
                    onPressed: () {},
                    child: const Text('开通租户'),
                  ),
                  TextButton(
                    key: const Key('tenant-toggle'),
                    onPressed: () {},
                    child: const Text('禁用/启用'),
                  ),
                  TextButton(
                    key: const Key('tenant-license-adjust'),
                    onPressed: controller.markLicenseAdjusted,
                    child: const Text('调整 license'),
                  ),
                ],
              ),
            ),
            if (data.licenseAdjusted)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '演示：license 已调整（本地）',
                  key: Key('tenant-license-demo-applied'),
                ),
              ),
            HighfiCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(data.tenantTitle),
                subtitle: Text(data.tenantSubtitle),
              ),
            ),
          ] else
            _buildNonNormal(data),
        ],
      ),
    );
  }

  Widget _buildNonNormal(AdminViewData data) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无租户',
          description: '可通过演示入口快速创建租户。',
          icon: Icons.domain_disabled_outlined,
        );
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '租户列表加载失败',
          description: data.message ?? '',
          icon: Icons.error_outline,
        );
      case ViewState.forbidden:
        return HighfiEmptyErrorState(
          title: '无平台运维权限',
          description: data.message ?? '',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '离线后台快照',
          description: data.message ?? '',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.normal:
        return const SizedBox.shrink();
    }
  }
}
