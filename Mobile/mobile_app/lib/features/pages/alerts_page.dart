import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/mock/mock_config.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/permissions/role_permission.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/presentation/alerts_controller.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key, required this.role});

  final DemoRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(alertsControllerProvider(role));
    final controller = ref.read(alertsControllerProvider(role).notifier);

    return SingleChildScrollView(
      key: const Key('page-alerts'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.viewState == ViewState.normal) ...[
            HighfiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '告警中心',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '聚焦围栏越界、设备低电、信号丢失三类 P0 告警。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      HighfiStatusChip(
                        label: '全部',
                        color: AppColors.primary,
                        icon: Icons.grid_view_rounded,
                      ),
                      HighfiStatusChip(
                        label: '未处理',
                        color: AppColors.warning,
                        icon: Icons.pending_actions_outlined,
                      ),
                      HighfiStatusChip(
                        label: '已处理',
                        color: AppColors.success,
                        icon: Icons.task_alt_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _AlertTypeChip(
                  chipKey: Key('alert-type-fence-breach'),
                  label: '越界告警',
                  icon: Icons.fence,
                  color: AppColors.danger,
                ),
                _AlertTypeChip(
                  chipKey: Key('alert-type-battery-low'),
                  label: '电池低电',
                  icon: Icons.battery_alert_outlined,
                  color: AppColors.warning,
                ),
                _AlertTypeChip(
                  chipKey: Key('alert-type-signal-lost'),
                  label: '信号丢失',
                  icon: Icons.signal_wifi_connected_no_internet_4_outlined,
                  color: AppColors.info,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            HighfiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(data.title),
                    subtitle: Text(data.subtitle),
                    trailing: HighfiStatusChip(
                      label: _statusLabel(data.stage),
                      color: _statusColor(data.stage),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (RolePermission.canAcknowledgeAlert(role) &&
                          data.stage == AlertStage.pending)
                        TextButton(
                          key: const Key('alert-confirm'),
                          onPressed: controller.acknowledge,
                          child: const Text('确认'),
                        ),
                      if (RolePermission.canHandleAlert(role) &&
                          data.stage == AlertStage.acknowledged)
                        TextButton(
                          key: const Key('alert-handle'),
                          onPressed: controller.handle,
                          child: const Text('处理'),
                        ),
                      if (RolePermission.canArchiveAlert(role) &&
                          data.stage == AlertStage.handled)
                        TextButton(
                          key: const Key('alert-archive'),
                          onPressed: controller.archive,
                          child: const Text('归档'),
                        ),
                      if (RolePermission.canBatchAlerts(role) &&
                          data.stage != AlertStage.archived)
                        TextButton(
                          key: const Key('alert-batch'),
                          onPressed: () {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(content: Text('演示：批量处理待接入')),
                              );
                          },
                          child: const Text('批量处理'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._buildP0AlertRows(context),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (data.stage.index >= AlertStage.acknowledged.index)
              Text(
                '流程：已确认',
                key: const Key('alert-status-confirmed'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (data.stage.index >= AlertStage.handled.index)
              Text(
                '流程：已处理',
                key: const Key('alert-status-handled'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (data.stage.index >= AlertStage.archived.index)
              Text(
                '流程：已归档',
                key: const Key('alert-status-archived'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ] else
            _buildNonNormalBody(data),
        ],
      ),
    );
  }

  String _statusLabel(AlertStage stage) {
    switch (stage) {
      case AlertStage.pending:
        return '待处理';
      case AlertStage.acknowledged:
        return '已确认';
      case AlertStage.handled:
        return '已处理';
      case AlertStage.archived:
        return '已归档';
    }
  }

  Widget _buildNonNormalBody(AlertsViewData data) {
    switch (data.viewState) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.empty:
        return const HighfiEmptyErrorState(
          title: '暂无告警',
          description: '当前没有触发中的 P0 告警。',
          icon: Icons.notifications_off_outlined,
        );
      case ViewState.error:
        return HighfiEmptyErrorState(
          title: '告警列表加载失败',
          description: data.message ?? '',
          icon: Icons.error_outline,
        );
      case ViewState.forbidden:
        return HighfiEmptyErrorState(
          title: '无权限处理告警',
          description: data.message ?? '',
          icon: Icons.lock_outline_rounded,
        );
      case ViewState.offline:
        return HighfiEmptyErrorState(
          title: '离线告警快照',
          description: data.message ?? '',
          icon: Icons.cloud_off_rounded,
        );
      case ViewState.normal:
        return const SizedBox.shrink();
    }
  }

  Color _statusColor(AlertStage stage) {
    switch (stage) {
      case AlertStage.pending:
        return AppColors.warning;
      case AlertStage.acknowledged:
        return AppColors.info;
      case AlertStage.handled:
        return AppColors.success;
      case AlertStage.archived:
        return AppColors.textSecondary;
    }
  }

  List<Widget> _buildP0AlertRows(BuildContext context) {
    final rows =
        <({String rowKey, String typeName, String title, String detail})>[
      (
        rowKey: 'alert-row-fence-breach',
        typeName: MockConfig.p0AlertTypes[0],
        title: MockConfig.p0AlertTypes[0],
        detail: '耳标-001 · 北区围栏 · 距边界 24m'
      ),
      (
        rowKey: 'alert-row-battery-low',
        typeName: MockConfig.p0AlertTypes[1],
        title: MockConfig.p0AlertTypes[1],
        detail: '设备-045 · 电量 12% · 建议今日更换'
      ),
      (
        rowKey: 'alert-row-signal-lost',
        typeName: MockConfig.p0AlertTypes[2],
        title: MockConfig.p0AlertTypes[2],
        detail: '耳标-023 · 失联 18 分钟 · 最后位置东坡'
      ),
    ];

    return [
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            key: Key(row.rowKey),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  row.typeName == MockConfig.p0AlertTypes[0]
                      ? Icons.fence
                      : row.typeName == MockConfig.p0AlertTypes[1]
                          ? Icons.battery_alert_outlined
                          : Icons.signal_wifi_connected_no_internet_4_outlined,
                  color: row.typeName == MockConfig.p0AlertTypes[0]
                      ? AppColors.danger
                      : row.typeName == MockConfig.p0AlertTypes[1]
                          ? AppColors.warning
                          : AppColors.info,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        row.detail,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

class _AlertTypeChip extends StatelessWidget {
  const _AlertTypeChip({
    required this.chipKey,
    required this.label,
    required this.icon,
    required this.color,
  });

  final Key chipKey;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HighfiStatusChip(
      key: chipKey,
      label: label,
      icon: icon,
      color: color,
    );
  }
}
