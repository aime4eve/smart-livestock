import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/permissions/role_permission.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alerts_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/alerts_controller.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_empty_error_state.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

enum _P0AlertType { fenceBreach, batteryLow, signalLost }

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
                l10n.alertCenterTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.alertCenterDesc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  HighfiStatusChip(
                    label: l10n.commonAll,
                    color: AppColors.primary,
                    icon: Icons.grid_view_rounded,
                  ),
                  HighfiStatusChip(
                    label: l10n.alertFilterPending,
                    color: AppColors.warning,
                    icon: Icons.pending_actions_outlined,
                  ),
                  HighfiStatusChip(
                    label: l10n.alertFilterHandled,
                    color: AppColors.success,
                    icon: Icons.task_alt_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _AlertTypeChip(
              chipKey: const Key('alert-type-fence-breach'),
              label: l10n.alertChipFenceBreach,
              icon: Icons.fence,
              color: AppColors.danger,
            ),
            _AlertTypeChip(
              chipKey: const Key('alert-type-battery-low'),
              label: l10n.alertChipBatteryLow,
              icon: Icons.battery_alert_outlined,
              color: AppColors.warning,
            ),
            _AlertTypeChip(
              chipKey: const Key('alert-type-signal-lost'),
              label: l10n.alertChipSignalLost,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _statusLabel(l10n, firstItem.stage),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _statusColor(firstItem.stage),
                        ),
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      if (RolePermission.canAcknowledgeAlert(role) &&
                          firstItem.stage == AlertStage.active.name)
                        TextButton(
                          key: const Key('alert-ack'),
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
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ..._buildP0AlertRows(context),
            ],
          ),
        ),
        if (_hasAiAlerts(data)) ...[
          const SizedBox(height: AppSpacing.md),
          _buildAiAlertSection(context, data),
        ],
      ],
    );
  }

  bool _hasAiAlerts(AlertsListData data) {
    return data.items.any((a) => a.source == 'AI');
  }

  Widget _buildAiAlertSection(BuildContext context, AlertsListData data) {
    final l10n = AppLocalizations.of(context)!;
    final aiAlerts = data.items.where((a) => a.source == 'AI').toList();
    return HighfiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, size: 18, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.aiAnomalyAiAlerts,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.info,
                      )),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final alert in aiAlerts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title,
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(alert.type,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String stage) {
    final s = AlertStage.values.where((e) => e.name == stage).firstOrNull;
    return switch (s) {
      AlertStage.active => l10n.alertStageActive,
      AlertStage.dismissed => l10n.alertStageDismissed,
      AlertStage.autoResolved => l10n.alertStageAutoResolved,
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
    final l10n = AppLocalizations.of(context)!;
    final rows = <({_P0AlertType type, String rowKey})>[
      (type: _P0AlertType.fenceBreach, rowKey: 'alert-row-fence-breach'),
      (type: _P0AlertType.batteryLow, rowKey: 'alert-row-battery-low'),
      (type: _P0AlertType.signalLost, rowKey: 'alert-row-signal-lost'),
    ];

    String titleFor(_P0AlertType t) => switch (t) {
          _P0AlertType.fenceBreach => l10n.alertChipFenceBreach,
          _P0AlertType.batteryLow => l10n.alertChipBatteryLow,
          _P0AlertType.signalLost => l10n.alertChipSignalLost,
        };

    String detailFor(_P0AlertType t) => switch (t) {
          _P0AlertType.fenceBreach => l10n.alertP0FenceBreachDetail,
          _P0AlertType.batteryLow => l10n.alertP0BatteryLowDetail,
          _P0AlertType.signalLost => l10n.alertP0SignalLostDetail,
        };

    IconData iconFor(_P0AlertType t) => switch (t) {
          _P0AlertType.fenceBreach => Icons.fence,
          _P0AlertType.batteryLow => Icons.battery_alert_outlined,
          _P0AlertType.signalLost =>
            Icons.signal_wifi_connected_no_internet_4_outlined,
        };

    Color colorFor(_P0AlertType t) => switch (t) {
          _P0AlertType.fenceBreach => AppColors.danger,
          _P0AlertType.batteryLow => AppColors.warning,
          _P0AlertType.signalLost => AppColors.info,
        };

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
                Icon(iconFor(row.type), color: colorFor(row.type)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleFor(row.type),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        detailFor(row.type),
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
