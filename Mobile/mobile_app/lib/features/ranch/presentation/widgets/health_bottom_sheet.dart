import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/core/permissions/role_permission.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/alerts/presentation/alerts_controller.dart';
import 'package:smart_livestock_demo/features/ranch/domain/ranch_models.dart';

/// Three snap levels for the bottom panel.
enum _SnapLevel { peek, half, full }

class HealthBottomSheet extends ConsumerStatefulWidget {
  const HealthBottomSheet({super.key, required this.overview});

  final RanchOverview overview;

  @override
  ConsumerState<HealthBottomSheet> createState() => _HealthBottomSheetState();
}

class _HealthBottomSheetState extends ConsumerState<HealthBottomSheet>
    {
  _SnapLevel _snap = _SnapLevel.peek;

  // Heights as fractions of parent
  static const _peekHeight = 56.0;
  static const _halfFraction = 0.45;
  static const _fullFraction = 0.92;

  String _alertStatusFilter = 'ALL';
  String _alertTypeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  double _targetHeight(double parentHeight) {
    switch (_snap) {
      case _SnapLevel.peek:
        return _peekHeight;
      case _SnapLevel.half:
        return parentHeight * _halfFraction;
      case _SnapLevel.full:
        return parentHeight * _fullFraction;
    }
  }

  void _snapTo(_SnapLevel target) {
    setState(() => _snap = target);
  }

  void _cycleSnap() {
    switch (_snap) {
      case _SnapLevel.peek:
        _snapTo(_SnapLevel.half);
      case _SnapLevel.half:
        _snapTo(_SnapLevel.full);
      case _SnapLevel.full:
        _snapTo(_SnapLevel.peek);
    }
  }

  double _dragStartY = 0;

  void _onVerticalDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final dy = _dragStartY - details.globalPosition.dy;
    if (dy > 40 && _snap == _SnapLevel.peek) {
      _snapTo(_SnapLevel.half);
    } else if (dy > 40 && _snap == _SnapLevel.half) {
      _snapTo(_SnapLevel.full);
    } else if (dy < -40 && _snap == _SnapLevel.full) {
      _snapTo(_SnapLevel.half);
    } else if (dy < -40 && _snap == _SnapLevel.half) {
      _snapTo(_SnapLevel.peek);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.overview.overallStats;
    final scene = widget.overview.sceneSummary;
    final alerts = _filteredAlerts;
    final tasks = widget.overview.pendingTasks;
    final role = ref.watch(sessionControllerProvider).role;

    // Use MediaQuery instead of LayoutBuilder because this widget lives
    // inside a Positioned(bottom:0) in a Stack, which gives unbounded
    // maxHeight via LayoutBuilder constraints.
    final mq = MediaQuery.of(context);
    final parentHeight = mq.size.height - mq.padding.top - kToolbarHeight;
    final targetH = _targetHeight(parentHeight);

    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: targetH,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Column(
          children: [
            // ── Drag handle + peek bar ────────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: _onVerticalDragStart,
              onVerticalDragEnd: _onVerticalDragEnd,
              onTap: _cycleSnap,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  height: _peekHeight,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${stats.totalLivestock}头',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(width: AppSpacing.md),
                          Text('健康率 ${(stats.healthyRate * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(width: AppSpacing.md),
                          Text('${stats.alertCount}告警',
                              style: TextStyle(
                                color: stats.alertCount > 0 ? AppColors.danger : AppColors.textSecondary,
                                fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _snap == _SnapLevel.peek
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Scrollable content ─────────────────────────────────────
            if (_snap != _SnapLevel.peek)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: [
                    // Overview (stats + health scenes merged)
                    Text('📋 概况', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    _StatCardRow(stats: stats),
                    const SizedBox(height: AppSpacing.md),
                    _SceneCardGrid(scene: scene),
                    const SizedBox(height: AppSpacing.xl),

                    // Alerts
                    if (widget.overview.alerts.isNotEmpty) ...[
                      Row(
                        children: [
                          Text('🚨 告警', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          Text('${widget.overview.alerts.length}条',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _AlertFilterChips(
                        statusFilter: _alertStatusFilter,
                        typeFilter: _alertTypeFilter,
                        onStatusChanged: (v) => setState(() => _alertStatusFilter = v),
                        onTypeChanged: (v) => setState(() => _alertTypeFilter = v),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (role != null)
                        _AlertList(
                          alerts: alerts,
                          allAlerts: widget.overview.alerts,
                          role: role,
                          ref: ref,
                        ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Pending tasks
                    if (tasks.isNotEmpty) ...[
                      Text('⏰ 待处理任务', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      _PendingTaskList(tasks: tasks),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<RanchAlertData> get _filteredAlerts {
    var result = widget.overview.alerts;
    if (_alertStatusFilter != 'ALL') {
      result = result.where((a) => a.status == _alertStatusFilter).toList();
    }
    if (_alertTypeFilter != 'ALL') {
      result = result.where((a) => a.type == _alertTypeFilter).toList();
    }
    return result;
  }
}

// ── Stat card row ─────────────────────────────────────────────────────

class _StatCardRow extends StatelessWidget {
  const _StatCardRow({required this.stats});
  final RanchOverviewStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      ('牲畜', '${stats.totalLivestock}', AppColors.primary),
      ('健康率', '${(stats.healthyRate * 100).toStringAsFixed(1)}%', AppColors.success),
      ('告警', '${stats.alertCount}', stats.alertCount > 0 ? AppColors.danger : AppColors.success),
      ('严重', '${stats.criticalCount}', stats.criticalCount > 0 ? AppColors.danger : AppColors.textSecondary),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: items[i].$3.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: items[i].$3.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(items[i].$2, style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: items[i].$3,
                  )),
                  const SizedBox(height: 2),
                  Text(items[i].$1, style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Scene card grid ───────────────────────────────────────────────────

class _SceneCardGrid extends StatelessWidget {
  const _SceneCardGrid({required this.scene});
  final RanchSceneSummary scene;

  @override
  Widget build(BuildContext context) {
    final scenes = [
      _SceneItem(
        icon: Icons.thermostat,
        title: '发热',
        metric: '异常 ${scene.fever.abnormalCount}  严重${scene.fever.criticalCount}',
        color: scene.fever.criticalCount > 0
            ? AppColors.danger
            : scene.fever.abnormalCount > 0
                ? AppColors.warning
                : Colors.orange,
        hasAlert: scene.fever.criticalCount > 0 || scene.fever.abnormalCount > 0,
        route: AppRoute.twinFever.path,
      ),
      _SceneItem(
        icon: Icons.grain,
        title: '消化',
        metric: '异常${scene.digestive.abnormalCount}  观察${scene.digestive.watchCount}',
        color: scene.digestive.abnormalCount > 0
            ? AppColors.warning
            : Colors.brown,
        hasAlert: scene.digestive.abnormalCount > 0,
        route: AppRoute.twinDigestive.path,
      ),
      _SceneItem(
        icon: Icons.favorite,
        title: '发情',
        metric: '高分${scene.estrus.highScoreCount}',
        color: scene.estrus.highScoreCount > 0 ? AppColors.warning : Colors.pink,
        hasAlert: scene.estrus.highScoreCount > 0,
        route: AppRoute.twinEstrus.path,
      ),
      _SceneItem(
        icon: Icons.shield,
        title: '疫病',
        metric: '${(scene.epidemic.abnormalRate * 100).toStringAsFixed(1)}%',
        color: scene.epidemic.abnormalRate > 0.1
            ? AppColors.danger
            : Colors.teal,
        hasAlert: scene.epidemic.abnormalRate > 0.05,
        route: AppRoute.twinEpidemic.path,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < scenes.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _CompactSceneChip(
              scene: scenes[i],
              onTap: () => context.go(scenes[i].route),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Alert filter chips ────────────────────────────────────────────────

class _AlertFilterChips extends StatelessWidget {
  const _AlertFilterChips({
    required this.statusFilter,
    required this.typeFilter,
    required this.onStatusChanged,
    required this.onTypeChanged,
  });

  final String statusFilter;
  final String typeFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _buildChip(context, '全部', 'ALL', statusFilter, AppColors.primary, Icons.grid_view_rounded, onStatusChanged),
            _buildChip(context, '待处理', 'PENDING', statusFilter, AppColors.warning, Icons.pending_actions_outlined, onStatusChanged),
            _buildChip(context, '已确认', 'ACKNOWLEDGED', statusFilter, AppColors.info, Icons.check_circle_outline, onStatusChanged),
            _buildChip(context, '已处理', 'HANDLED', statusFilter, AppColors.success, Icons.task_alt_outlined, onStatusChanged),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _buildChip(context, '越界', 'FENCE_BREACH', typeFilter, AppColors.danger, Icons.fence, onTypeChanged),
            _buildChip(context, '体温异常', 'TEMPERATURE_ABNORMAL', typeFilter, AppColors.warning, Icons.thermostat, onTypeChanged),
            _buildChip(context, '行为异常', 'BEHAVIOR_ABNORMAL', typeFilter, AppColors.info, Icons.pets, onTypeChanged),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, String value, String current, Color color, IconData icon, ValueChanged<String> onChanged) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              fontSize: 12,
              color: selected ? color : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Alert list ────────────────────────────────────────────────────────

class _AlertList extends ConsumerWidget {
  const _AlertList({
    required this.alerts,
    required this.allAlerts,
    required this.role,
    required this.ref,
  });

  final List<RanchAlertData> alerts;
  final List<RanchAlertData> allAlerts;
  final UserRole role;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (alerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text('无匹配告警', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          )),
        ),
      );
    }

    return Column(
      children: [
        if (RolePermission.canBatchAlerts(role))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('演示：批量处理待接入')));
                  },
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('批量处理'),
                ),
              ],
            ),
          ),
        for (final alert in alerts)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _alertColor(alert.severity).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _alertColor(alert.severity).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _alertIcon(alert.type),
                      color: _alertColor(alert.severity),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.message,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusColor(alert.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _statusLabel(alert.status),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _statusColor(alert.status),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (RolePermission.canAcknowledgeAlert(role) &&
                          alert.status == 'PENDING')
                        TextButton(
                          onPressed: () => ref
                              .read(alertsControllerProvider.notifier)
                              .acknowledge(alert.id),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('确认', style: TextStyle(fontSize: 12)),
                        ),
                      if (RolePermission.canHandleAlert(role) &&
                          alert.status == 'ACKNOWLEDGED')
                        TextButton(
                          onPressed: () => ref
                              .read(alertsControllerProvider.notifier)
                              .handle(alert.id),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('处理', style: TextStyle(fontSize: 12)),
                        ),
                      if (RolePermission.canArchiveAlert(role) &&
                          alert.status == 'HANDLED')
                        TextButton(
                          onPressed: () => ref
                              .read(alertsControllerProvider.notifier)
                              .archive(alert.id),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('归档', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData _alertIcon(String type) {
    return switch (type) {
      'FENCE_BREACH' => Icons.fence,
      'TEMPERATURE_ABNORMAL' => Icons.thermostat,
      'BEHAVIOR_ABNORMAL' => Icons.pets,
      'ESTRUS' => Icons.favorite,
      'EPIDEMIC' => Icons.shield,
      _ => Icons.warning,
    };
  }

  Color _alertColor(String severity) {
    return switch (severity) {
      'CRITICAL' => AppColors.danger,
      'HIGH' => AppColors.danger,
      'MEDIUM' => AppColors.warning,
      'WARNING' => AppColors.warning,
      _ => AppColors.info,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'PENDING' => '待处理',
      'ACKNOWLEDGED' => '已确认',
      'HANDLED' => '已处理',
      'ARCHIVED' => '已归档',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'PENDING' => AppColors.warning,
      'ACKNOWLEDGED' => AppColors.info,
      'HANDLED' => AppColors.success,
      'ARCHIVED' => AppColors.textSecondary,
      _ => AppColors.textSecondary,
    };
  }
}

// ── Pending task list ─────────────────────────────────────────────────

class _PendingTaskList extends StatelessWidget {
  const _PendingTaskList({required this.tasks});
  final List<RanchPendingTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final task in tasks)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (task.severity == 'CRITICAL'
                      ? AppColors.danger
                      : AppColors.warning).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  task.severity == 'CRITICAL' ? Icons.error : Icons.warning,
                  color: task.severity == 'CRITICAL'
                      ? AppColors.danger
                      : AppColors.warning,
                  size: 18,
                ),
              ),
              title: Text(task.title, style: Theme.of(context).textTheme.bodyMedium),
              subtitle: task.subtitle.isNotEmpty
                  ? Text(task.subtitle, style: Theme.of(context).textTheme.bodySmall)
                  : null,
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: task.routePath.isNotEmpty ? () => context.go(task.routePath) : null,
            ),
          ),
      ],
    );
  }
}

// ── Compact scene chip ─────────────────────────────────────────────────

class _CompactSceneChip extends StatelessWidget {
  const _CompactSceneChip({required this.scene, required this.onTap});
  final _SceneItem scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: scene.hasAlert
          ? scene.color.withValues(alpha: 0.08)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scene.color.withValues(alpha: scene.hasAlert ? 0.5 : 0.15),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scene.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(scene.icon, color: scene.color, size: 16),
              ),
              const SizedBox(height: 6),
              Text(scene.title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(scene.metric,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scene.hasAlert ? scene.color : AppColors.textSecondary,
                  fontWeight: scene.hasAlert ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Internal types ────────────────────────────────────────────────────

class _SceneItem {
  const _SceneItem({
    required this.icon,
    required this.title,
    required this.metric,
    required this.color,
    required this.hasAlert,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String metric;
  final Color color;
  final bool hasAlert;
  final String route;
}
