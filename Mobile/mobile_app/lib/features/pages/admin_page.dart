import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/admin/presentation/admin_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(adminControllerProvider);

    return asyncData.when(
      data: (data) => SingleChildScrollView(
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
                    label: 'platform_admin / owner 演示入口',
                    color: AppColors.info,
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HighfiCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(data.tenantTitle),
                subtitle: Text(data.tenantSubtitle),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
