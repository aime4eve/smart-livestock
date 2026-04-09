import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/mock/mock_config.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/permissions/role_permission.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class FencePage extends ConsumerWidget {
  const FencePage({super.key, required this.role});

  final DemoRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = RolePermission.canEditFence(role);
    final data = ref.watch(fenceControllerProvider(role));
    final controller = ref.read(fenceControllerProvider(role).notifier);

    return SingleChildScrollView(
      key: const Key('page-fence'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '围栏页',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (canManage) ...[
            Row(
              children: [
                TextButton(
                  key: const Key('fence-add'),
                  onPressed: () => context.go(AppRoute.fenceCreate.path),
                  child: const Text('新增围栏'),
                ),
                IconButton(
                  key: const Key('fence-edit-action'),
                  onPressed: controller.markEditSaved,
                  icon: const Icon(Icons.edit),
                  tooltip: '编辑',
                ),
                IconButton(
                  key: const Key('fence-delete'),
                  onPressed: () {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('演示：删除围栏待接入')),
                      );
                  },
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除',
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (data.editSaved)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '演示：围栏编辑已保存（本地）',
                key: Key('fence-flow-edit-saved'),
              ),
            ),
          _buildBody(data),
        ],
      ),
    );
  }

  Widget _buildBody(FenceViewData data) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无围栏',
          description: '可从地图页直接创建新围栏。',
          icon: Icons.fence_outlined,
        );
      case ViewState.error:
      case ViewState.forbidden:
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '围栏场景暂不可用',
          description: data.message ?? '',
          icon: Icons.cloud_off_outlined,
        );
      case ViewState.normal:
        return HighfiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(data.fenceTitle),
                subtitle: Text(data.fenceSubtitle),
                trailing: const HighfiStatusChip(
                  label: '模板可用',
                  icon: Icons.category_outlined,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  HighfiStatusChip(
                    key: const Key('fence-group-chip'),
                    label: MockConfig.fenceGroups.first,
                    icon: Icons.group_work_outlined,
                    color: Colors.teal,
                  ),
                  for (final template in MockConfig.fenceTemplates)
                    HighfiStatusChip(label: template),
                ],
              ),
            ],
          ),
        );
    }
  }
}
