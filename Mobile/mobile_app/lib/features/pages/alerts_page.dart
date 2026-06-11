import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/core/permissions/role_permission.dart';
import 'package:smart_livestock_demo/features/alerts/domain/alerts_repository.dart';
import 'package:smart_livestock_demo/features/alerts/presentation/alerts_controller.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_card.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:smart_livestock_demo/features/highfi/widgets/highfi_status_chip.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(alertsControllerProvider);
    final controller = ref.read(alertsControllerProvider.notifier);

    return SingleChildScrollView(
      key: const Key('page-alerts'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          asyncData.when(
            data: (data) => _buildContent(context, data, controller),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${l10n.commonLoadFailed}: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.refresh(),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AlertsListData data,
    AlertsController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (data.items.isEmpty) {
      return HighfiEmptyErrorState(
        title: l10n.alertsNoAlerts,
        description: l10n.alertsNoAlertsDesc,
        icon: Icons.notifications_off_outlined,
      );
    }

    final firstItem = data.items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                title: Text(firstItem.title),
                subtitle: Text(firstItem.subtitle),
                trailing: HighfiStatusChip(
                  label: _statusLabel(firstItem.stage),
                  color: _statusColor(firstItem.stage),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (RolePermission.canAcknowledgeAlert(role) &&
                      firstItem.stage == AlertStage.active.name)
                    TextButton(
                      key: const Key('alert-confirm'),
                      onPressed: () => controller.acknowledge(firstItem.id),
                      child: Text(l10n.alertsConfirm),
                    ),
                  if (RolePermission.canHandleAlert(role) &&
                      firstItem.stage == AlertStage.active.name)
                    TextButton(
                      key: const Key('alert-handle'),
                      onPressed: () => controller.handle(firstItem.id),
                      child: Text(l10n.alertsHandle),
                    ),
                  if (RolePermission.canArchiveAlert(role) &&
                      firstItem.stage == AlertStage.dismissed.name)
                    TextButton(
                      key: const Key('alert-archive'),
                      onPressed: () => controller.archive(firstItem.id),
                      child: Text(l10n.alertsArchive),
                    ),
                  if (RolePermission.canBatchAlerts(role) &&
                      firstItem.stage != AlertStage.autoResolved.name)
                    TextButton(
                      key: const Key('alert-batch'),
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(l10n.alertsBatchDemo)),
                          );
                      },
                      child: Text(l10n.alertsBatchHandle),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ..._buildP0AlertRows(context),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(String stage) {
    final s = AlertStage.values.where((e) => e.name == stage).firstOrNull;
    return switch (s) {
      AlertStage.active => '活跃',
      AlertStage.dismissed => '已忽略',
      AlertStage.autoResolved => '已自动解除',
      
      _ => stage,
    };
  }

  Color _statusColor(String stage) {
    final s = AlertStage.values.where((e) => e.name == stage).firstOrNull;
    return switch (s) {
      AlertStage.active => AppColors.warning,
      AlertStage.dismissed => AppColors.textSecondary,
      AlertStage.autoResolved => AppColors.success,
      
      _ => AppColors.textSecondary,
    };
  }

  List<Widget> _buildP0AlertRows(BuildContext context) {
    final rows =
        <({String rowKey, String typeName, String title, String detail})>[
      (
        rowKey: 'alert-row-fence-breach',
        typeName: '越界告警',
        title: '越界告警',
        detail: '耳标-001 · 北区围栏 · 距边界 24m'
      ),
      (
        rowKey: 'alert-row-battery-low',
        typeName: '电池低电',
        title: '电池低电',
        detail: '设备-045 · 电量 12% · 建议今日更换'
      ),
      (
        rowKey: 'alert-row-signal-lost',
        typeName: '信号丢失',
        title: '信号丢失',
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
                  row.typeName == '越界告警'
                      ? Icons.fence
                      : row.typeName == '电池低电'
                          ? Icons.battery_alert_outlined
                          : Icons.signal_wifi_connected_no_internet_4_outlined,
                  color: row.typeName == '越界告警'
                      ? AppColors.danger
                      : row.typeName == '电池低电'
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
