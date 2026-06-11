import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/models/user_role.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/ranch/domain/ranch_models.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/ranch_controller.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/alert_card.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/auto_resolved_section.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/device_info_line.dart';
import 'package:smart_livestock_demo/features/ranch/presentation/widgets/status_dashboard_card.dart';

/// Snap levels for the bottom panel.
enum _SnapLevel { peek, half, full }

/// The main bottom sheet for the ranch tab.
///
/// Implements a four-level drill-down architecture:
///   peek → dashboard (cards) → list (alerts by category) → detail
class HealthBottomSheet extends ConsumerStatefulWidget {
  const HealthBottomSheet({super.key, required this.overview});

  final RanchOverview overview;

  @override
  ConsumerState<HealthBottomSheet> createState() => _HealthBottomSheetState();
}

class _HealthBottomSheetState extends ConsumerState<HealthBottomSheet> {
  _SnapLevel _snap = _SnapLevel.peek;

  static const _peekHeight = 56.0;
  static const _halfFraction = 0.45;
  static const _fullFraction = 0.92;

  double _dragStartY = 0;

  double _targetHeight(double parentHeight) => switch (_snap) {
    _SnapLevel.peek => _peekHeight,
    _SnapLevel.half => parentHeight * _halfFraction,
    _SnapLevel.full => parentHeight * _fullFraction,
  };

  void _snapTo(_SnapLevel target) => setState(() => _snap = target);

  void _cycleSnap() => switch (_snap) {
    _SnapLevel.peek => _snapTo(_SnapLevel.half),
    _SnapLevel.half => _snapTo(_SnapLevel.full),
    _SnapLevel.full => _snapTo(_SnapLevel.peek),
  };

  void _onVerticalDragStart(DragStartDetails d) {
    _dragStartY = d.globalPosition.dy;
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final dy = _dragStartY - d.globalPosition.dy;
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
    final l10n = AppLocalizations.of(context)!;
    final stats = widget.overview.overallStats;
    final role = ref.watch(sessionControllerProvider).role;
    final controller = ref.read(ranchControllerProvider.notifier);
    final drillLevel = controller.drillLevel;
    final selectedCategory = controller.selectedCategory;

    final mq = MediaQuery.of(context);
    final parentHeight = mq.size.height - mq.padding.top - kToolbarHeight;
    final targetH = _targetHeight(parentHeight);

    // Auto-expand on drill-down
    if (drillLevel != RanchDrillLevel.dashboard && _snap == _SnapLevel.peek) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _snapTo(_SnapLevel.full);
      });
    }

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
            // ── Drag handle + peek bar ─────────────────────────────
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
                      _buildPeekBar(stats),
                    ],
                  ),
                ),
              ),
            ),
            // ── Content area ────────────────────────────────────────
            Expanded(
              child: switch (drillLevel) {
                RanchDrillLevel.dashboard => _buildDashboard(context, widget.overview, controller),
                RanchDrillLevel.list => _buildList(context, widget.overview, controller, selectedCategory, role),
                RanchDrillLevel.detail => _buildDetail(context, controller, role),
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Peek bar: "头数 · 归栏率 · 健康率" ────────────────────────
  Widget _buildPeekBar(RanchOverviewStats stats) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${stats.totalLivestock}头',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(
          '归栏 ${(stats.inFenceRate * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 13,
            color: stats.inFenceRate >= 0.9 ? AppColors.success : AppColors.warning,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '健康 ${(stats.healthyRate * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 13,
            color: stats.healthyRate >= 0.9 ? AppColors.success : AppColors.warning,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (stats.alertCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${stats.alertCount}条告警',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ── Dashboard: fence + health summary cards ────────────────────
  Widget _buildDashboard(BuildContext context, RanchOverview overview, RanchController controller) {
    final fenceSummary = overview.fenceAlertSummary;
    final healthSummary = overview.healthAlertSummary;
    final fenceTotal = fenceSummary.values.fold(0, (a, b) => a + b);
    final healthTotal = healthSummary.values.fold(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        // Scene summary chips (compact)
        _buildSceneChips(context, overview.sceneSummary),
        const SizedBox(height: AppSpacing.md),

        // Fence card — only show when count > 0
        if (fenceTotal > 0)
          StatusDashboardCard(
          icon: Icons.fence,
          title: '围栏告警',
          alertCount: fenceTotal,
          subtitle: fenceTotal > 0
              ? fenceSummary.entries.map((e) => '${_fenceTypeLabel(e.key)} ${e.value}').join('  ')
              : '围栏正常',
          accentColor: AppColors.warning,
          onTap: () => controller.showCategoryList('fence'),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Health card — only show when count > 0
        if (healthTotal > 0)
        StatusDashboardCard(
          icon: Icons.favorite,
          title: '健康告警',
          alertCount: healthTotal,
          subtitle: healthTotal > 0
              ? healthSummary.entries.map((e) => '${_healthTypeLabel(e.key)} ${e.value}').join('  ')
              : '牲畜健康',
          accentColor: AppColors.danger,
          onTap: () => controller.showCategoryList('health'),
        ),
        const SizedBox(height: AppSpacing.md),

        // Recent active alerts preview
        if (overview.alerts.where((a) => a.status == 'ACTIVE' || a.status == 'PENDING').isNotEmpty) ...[
          Text(AppLocalizations.of(context)!.ranchHealthLatestAlerts, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...overview.alerts
            .where((a) => a.status == 'ACTIVE' || a.status == 'PENDING')
            .take(3)
            .map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AlertCard(
                alert: alert,
                onTap: () => controller.showAlertDetail(alert.id),
              ),
            )),
        ],
      ],
    );
  }

  // ── Scene chips (compact, from sceneSummary) ───────────────────
  Widget _buildSceneChips(BuildContext context, RanchSceneSummary scene) {
    final items = [
      (Icons.thermostat, '发热', scene.fever.abnormalCount, AppColors.danger),
      (Icons.pets, '消化', scene.digestive.abnormalCount, AppColors.warning),
      (Icons.favorite, '发情', scene.estrus.highScoreCount, AppColors.accent),
      (Icons.shield, '疫病', scene.epidemic.abnormalRate > 0.1 ? 1 : 0, AppColors.info),
    ];

    return Row(
      children: items.map((item) {
        final (icon, label, count, color) = item;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _SceneChip(
              icon: icon,
              label: label,
              count: count,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── List: alerts filtered by category ──────────────────────────
  Widget _buildList(
    BuildContext context,
    RanchOverview overview,
    RanchController controller,
    String? category,
    dynamic role,
  ) {
    final allAlerts = overview.alerts;
    final fenceTypes = {'FENCE_BREACH', 'FENCE_APPROACH', 'ZONE_APPROACH'};
    final isFence = category == 'fence';

    final filtered = allAlerts.where((a) {
      final matchCat = isFence
          ? fenceTypes.contains(a.type)
          : !fenceTypes.contains(a.type);
      return matchCat;
    }).toList();

    final active = filtered.where((a) => a.status == 'ACTIVE' || a.status == 'PENDING' || a.status == 'ACKNOWLEDGED').toList();
    final autoResolved = filtered.where((a) => a.status == 'AUTO_RESOLVED' || a.status == 'ARCHIVED').toList();
    final dismissed = filtered.where((a) => a.status == 'DISMISSED' || a.status == 'HANDLED').toList();

    final unreadActiveCount = active.where((a) => !a.read).length;
    final canManage = role is UserRole && role != UserRole.worker;

    return Column(
      children: [
        // Back bar
        _BackBar(
          title: isFence ? '围栏告警' : '健康告警',
          onBack: controller.showDashboard,
        ),
        if (unreadActiveCount > 0 && canManage)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  final ids = active.where((a) => !a.read).map((a) => a.id).toList();
                  if (ids.isNotEmpty) controller.batchRead(ids);
                },
                child: Text(AppLocalizations.of(context)!.ranchHealthAllRead(unreadActiveCount.toString()), style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              // Active alerts
              ...active.map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AlertCard(
                  alert: alert,
                  showDismiss: canManage,
                  onTap: () => controller.showAlertDetail(alert.id),
                  onDismiss: canManage ? () => controller.dismiss(alert.id) : null,
                ),
              )),

              // Dismissed alerts (compact)
              if (dismissed.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(AppLocalizations.of(context)!.ranchHealthDismissed(dismissed.length.toString()),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                ...dismissed.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: AlertCard(
                    alert: alert,
                    onTap: () => controller.showAlertDetail(alert.id),
                  ),
                )),
              ],

              // Auto-resolved section (collapsible)
              AutoResolvedSection(
                alerts: autoResolved,
                onTapAlert: (a) => controller.showAlertDetail(a.id),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Detail: single alert detail view ───────────────────────────
  Widget _buildDetail(BuildContext context, RanchController controller, dynamic role) {
    final l10n = AppLocalizations.of(context)!;
    final overview = widget.overview;
    final selectedId = controller.selectedAlertId;
    if (selectedId == null) return const SizedBox.shrink();

    final alert = overview.alerts.cast<RanchAlertData?>().firstWhere(
      (a) => a?.id == selectedId,
      orElse: () => null,
    );
    if (alert == null) return const SizedBox.shrink();

    final fenceTypes = {'FENCE_BREACH', 'FENCE_APPROACH', 'ZONE_APPROACH'};
    final isFence = fenceTypes.contains(alert.type);

    return Column(
      children: [
        _BackBar(
          title: isFence ? '围栏告警详情' : '健康告警详情',
          onBack: () => controller.showCategoryList(
            isFence ? 'fence' : 'health',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert header
                AlertCard(alert: alert),
                const SizedBox(height: AppSpacing.md),

                // Device info (subtle)
                DeviceInfoLine(deviceId: alert.livestockId),
                const SizedBox(height: AppSpacing.md),

                // Content depends on type
                if (isFence)
                  _FenceDetailContent(alert: alert)
                else
                  _HealthDetailContent(alert: alert),

                const SizedBox(height: AppSpacing.md),

                // Capability boundary note
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.info),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isFence
                            ? '系统能检测围栏越界，定位精度取决于GPS信号'
                            : '系统能通知你健康异常，需线下排查确认',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Dismiss button for active alerts (owner/b2b_admin only)
                if (alert.status == 'ACTIVE' && role is UserRole && role != UserRole.worker)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          controller.dismiss(alert.id);
                          controller.showDashboard();
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(AppLocalizations.of(context)!.ranchHealthIgnoreAlert),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fenceTypeLabel(String type) => switch (type) {
    'FENCE_BREACH' => '越界',
    'FENCE_APPROACH' => '接近',
    'ZONE_APPROACH' => '区域',
    _ => type,
  };

  String _healthTypeLabel(String type) => switch (type) {
    'TEMPERATURE_ABNORMAL' || 'FEVER' => '发热',
    'DIGESTIVE_ABNORMAL' || 'BEHAVIOR_ABNORMAL' => '消化',
    'ESTRUS' => '发情',
    'EPIDEMIC' => '疫病',
    _ => type,
  };
}

// ── Back navigation bar ──────────────────────────────────────────
class _BackBar extends StatelessWidget {
  const _BackBar({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onBack,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            const Icon(Icons.chevron_left, size: 20),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

// ── Scene chip ───────────────────────────────────────────────────
class _SceneChip extends StatelessWidget {
  const _SceneChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasAlert = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: hasAlert ? color.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasAlert ? color.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: hasAlert ? color : AppColors.textSecondary),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
          if (hasAlert)
            Text('$count', style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            )),
        ],
      ),
    );
  }
}

// ── Fence detail content (placeholder for Task 15) ───────────────
class _FenceDetailContent extends StatelessWidget {
  const _FenceDetailContent({required this.alert});
  final RanchAlertData alert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.ranchHealthFenceInfo, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(label: '类型', value: alert.type),
            if (alert.distance != null)
              _InfoRow(label: '距围栏', value: '${alert.distance!.toStringAsFixed(0)}m'),
            if (alert.direction != null)
              _InfoRow(label: '方向', value: alert.direction!),
            if (alert.occurredAt != null)
              _InfoRow(label: '发生时间', value: alert.occurredAt!),
          ],
        ),
      ),
    );
  }
}

// ── Health detail content (links to detail pages) ────────────────
class _HealthDetailContent extends StatelessWidget {
  const _HealthDetailContent({required this.alert});
  final RanchAlertData alert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final healthType = alert.type;
    final livestockId = alert.livestockId;
    final canNavigate = livestockId != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.ranchHealthDetail, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(label: '异常类型', value: _healthLabel(healthType)),
            if (alert.occurredAt != null)
              _InfoRow(label: '发生时间', value: alert.occurredAt!),
            if (canNavigate) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToDetail(context, healthType, livestockId),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l10n.ranchHealthDetailLink(_healthLabel(healthType))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _healthLabel(String type) => switch (type) {
    'TEMPERATURE_ABNORMAL' || 'FEVER' => '发热',
    'DIGESTIVE_ABNORMAL' || 'BEHAVIOR_ABNORMAL' => '消化异常',
    'ESTRUS' => '发情',
    'EPIDEMIC' => '疫病',
    _ => type,
  };

  void _navigateToDetail(BuildContext context, String type, String livestockId) {
    final path = switch (type) {
      'TEMPERATURE_ABNORMAL' || 'FEVER' => '/twin/fever/$livestockId',
      'DIGESTIVE_ABNORMAL' || 'BEHAVIOR_ABNORMAL' => '/twin/digestive/$livestockId',
      'ESTRUS' => '/twin/estrus/$livestockId',
      _ => null,
    };
    if (path != null) {
      context.push(path);
    }
  }
}

// ── Info row helper ──────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
