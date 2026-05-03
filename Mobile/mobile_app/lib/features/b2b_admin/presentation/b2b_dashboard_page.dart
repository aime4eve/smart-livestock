import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/b2b_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/widgets/alert_bottom_sheet.dart';

class B2bDashboardPage extends ConsumerWidget {
  const B2bDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(b2bDashboardControllerProvider);
    final theme = Theme.of(context);

    return switch (data.viewState) {
      ViewState.loading => const Center(child: CircularProgressIndicator()),
      ViewState.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text('加载失败',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.error)),
              if (data.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(data.message!,
                      style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ViewState.empty => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  size: 48, color: theme.disabledColor),
              const SizedBox(height: AppSpacing.md),
              Text('暂无数据', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ViewState.forbidden => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 48, color: theme.disabledColor),
              const SizedBox(height: AppSpacing.md),
              Text('无权限访问',
                  style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ViewState.offline => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 48, color: theme.disabledColor),
              const SizedBox(height: AppSpacing.md),
              Text('网络不可用',
                  style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ViewState.normal => _buildContent(context, data),
    };
  }

  Widget _buildContent(BuildContext context, B2bDashboardData data) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('B端控制台',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (data.partnerName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(data.partnerName!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor)),
                      ),
                  ],
                ),
              ),
              if (data.contractStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: data.contractStatus == 'active'
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.contractStatus == 'active'
                            ? Icons.verified_outlined
                            : Icons.warning_amber_outlined,
                        size: 14,
                        color: data.contractStatus == 'active'
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.contractStatus == 'active' ? '合同有效' : '合同待续',
                        style: TextStyle(
                          fontSize: 12,
                          color: data.contractStatus == 'active'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Hero card ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF37474F), Color(0xFF607D8B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x4037474F), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¥${data.monthlyRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text('本月营收',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    _HeroStat(
                      label: '旗下牧场',
                      value: '${data.totalFarms}',
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _HeroStat(
                      label: '总牲畜',
                      value: '${data.totalLivestock}',
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    _HeroStat(
                      label: '待处理告警',
                      value: '${data.pendingAlerts}',
                      highlight: data.pendingAlerts > 0,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Device online rate progress bar
                Row(
                  children: [
                    Text('设备在线率',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    const Spacer(),
                    Text(
                      '${(data.deviceOnlineRate * 100).toInt()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.deviceOnlineRate.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Alert reminder bar ---
          if (data.pendingAlerts > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Material(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  key: const Key('b2b-alert-bar'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => B2bAlertBottomSheet.show(
                      context, data.alertSummary, data.pendingAlerts),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined,
                            size: 20, color: Color(0xFFE65100)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '${data.pendingAlerts} 条待处理告警',
                            style: const TextStyle(
                                color: Color(0xFFE65100),
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: Color(0xFFE65100)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // --- Quick links grid ---
          Row(
            children: [
              _QuickLinkItem(
                key: const Key('b2b-quick-revenue'),
                icon: Icons.bar_chart_outlined,
                label: '对账',
                onTap: () =>
                    context.go(AppRoute.b2bAdminRevenue.path),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickLinkItem(
                key: const Key('b2b-quick-contract'),
                icon: Icons.description_outlined,
                label: '合同',
                onTap: () =>
                    context.go(AppRoute.b2bAdminContract.path),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickLinkItem(
                key: const Key('b2b-quick-farms'),
                icon: Icons.agriculture_outlined,
                label: '牧场',
                onTap: () =>
                    context.go(AppRoute.b2bAdminFarms.path),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickLinkItem(
                key: const Key('b2b-quick-workers'),
                icon: Icons.engineering_outlined,
                label: '牧工',
                onTap: () =>
                    context.go(AppRoute.b2bWorkerManagement.path),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- Farm list ---
          Text('旗下牧场', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...data.farms.map((farm) => _FarmCard(farm: farm)),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFFFFCC80) : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }
}

class _QuickLinkItem extends StatelessWidget {
  const _QuickLinkItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: const Color(0xFF607D8B)),
                const SizedBox(height: AppSpacing.xs),
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF455A64))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  const _FarmCard({required this.farm});

  final B2bFarmSummary farm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine alert count: use region field convention or default to status
    // The status field encodes 'active' or other; we check if name suggests alerts
    final bool hasAlerts = farm.status != 'active';

    return Container(
      key: Key('b2b-farm-${farm.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Agriculture icon box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.agriculture_outlined,
                size: 24, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: AppSpacing.md),
          // Farm info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farm.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _FarmStatChip(
                        icon: Icons.groups_outlined, label: '${farm.workerCount}'),
                    const SizedBox(width: AppSpacing.sm),
                    _FarmStatChip(
                        icon: Icons.pets_outlined,
                        label: '${farm.livestockCount}'),
                    const SizedBox(width: AppSpacing.sm),
                    _FarmStatChip(
                        icon: Icons.sensors_outlined,
                        label: '${farm.deviceCount}'),
                  ],
                ),
              ],
            ),
          ),
          // Status tag
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: hasAlerts
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hasAlerts ? '告警' : '正常',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasAlerts
                    ? const Color(0xFFE65100)
                    : const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmStatChip extends StatelessWidget {
  const _FarmStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).hintColor),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).hintColor)),
      ],
    );
  }
}
