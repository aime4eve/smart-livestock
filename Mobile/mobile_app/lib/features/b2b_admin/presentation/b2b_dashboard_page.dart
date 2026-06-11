import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_route.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class B2bDashboardPage extends ConsumerStatefulWidget {
  const B2bDashboardPage({super.key});

  @override
  ConsumerState<B2bDashboardPage> createState() => _B2bDashboardPageState();
}

class _B2bDashboardPageState extends ConsumerState<B2bDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(b2bDashboardControllerProvider);
    final theme = Theme.of(context);

    return asyncData.when(
      data: (data) => _buildContent(context, data, theme),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.commonLoadFailed,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.error)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, B2bDashboardData data, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.b2bDashboardTitle,
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
                _ContractBadge(status: data.contractStatus!),
            ],
          ),
        ),
        // ── Tab bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: const [
                Tab(text: 'KPI 看板'),
                Tab(text: '告警动态'),
              ],
            ),
          ),
        ),
        // ── Tab content ──
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _KpiTab(data: data),
              _AlertTab(data: data),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 1: KPI 看板
// ═══════════════════════════════════════════════════════════════

class _KpiTab extends StatelessWidget {
  const _KpiTab({required this.data});
  final B2bDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalWorkers = data.farms.fold<int>(0, (s, f) => s + f.workerCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI grid
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: '旗下牧场',
                  value: '${data.totalFarms}',
                  icon: Icons.landscape_outlined,
                  color: const Color(0xFF2E7D32),
                  bgColor: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _KpiCard(
                  label: '牲畜总数',
                  value: '${data.totalLivestock}',
                  icon: Icons.pets_outlined,
                  color: const Color(0xFF1565C0),
                  bgColor: const Color(0xFFE3F2FD),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _KpiCard(
                  label: '总牧工',
                  value: '$totalWorkers',
                  icon: Icons.groups_outlined,
                  color: const Color(0xFF6A1B9A),
                  bgColor: const Color(0xFFF3E5F5),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _KpiCard(
                  label: '待处理告警',
                  value: '${data.pendingAlerts}',
                  icon: Icons.notification_important_outlined,
                  color: data.pendingAlerts > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                  bgColor: data.pendingAlerts > 0 ? const Color(0xFFFCE4EC) : const Color(0xFFE8F5E9),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Revenue hero card
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
                Text(l10n.b2bDashboardMonthlyRevenue,
                    style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                const SizedBox(height: 4),
                Text('\u00a5${data.monthlyRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _HeroInfoItem(
                        label: '设备在线率',
                        value: '${(data.deviceOnlineRate * 100).toStringAsFixed(0)}%'),
                    const SizedBox(width: AppSpacing.xl),
                    _HeroInfoItem(
                        label: '设备总数', value: '${data.totalDevices}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick links
          Row(
            children: [
              Expanded(
                child: _QuickLinkItem(
                  icon: Icons.sensors_outlined,
                  label: '设备',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickLinkItem(
                  icon: Icons.description_outlined,
                  label: '合同',
                  onTap: () => context.go(AppRoute.b2bAdminContract.path),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickLinkItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: '对账',
                  onTap: () => context.go(AppRoute.b2bAdminRevenue.path),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 3: 告警动态
// ═══════════════════════════════════════════════════════════════

class _AlertTab extends StatelessWidget {
  const _AlertTab({required this.data});
  final B2bDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final alerts = data.alertSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.b2bDashboardPendingAlerts, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: data.pendingAlerts > 0 ? const Color(0xFFFCE4EC) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${data.pendingAlerts}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: data.pendingAlerts > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                    )),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          if (alerts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.b2bDashboardNoPendingAlerts, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ...alerts.map((alert) => _AlertCard(alert: alert)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Shared widgets
// ═══════════════════════════════════════════════════════════════

class _ContractBadge extends StatelessWidget {
  const _ContractBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.verified_outlined : Icons.warning_amber_outlined,
            size: 14,
            color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? '合同有效' : '合同待续',
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });


  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _HeroInfoItem extends StatelessWidget {
  const _HeroInfoItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _QuickLinkItem extends StatelessWidget {
  const _QuickLinkItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });


  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF455A64))),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final Map<String, dynamic> alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final farmName = alert['farmName'] as String? ?? '未知牧场';
    final type = alert['type'] as String? ?? '告警';
    final typeLabel = switch (type) {
      'FENCE_BREACH' => '围栏越界',
      'HEALTH' => '健康异常',
      'DEVICE_OFFLINE' => '设备离线',
      _ => type,
    };
    final message = alert['message'] as String? ?? '';
    final livestockId = alert['livestockId'];
    final livestockLabel = livestockId != null ? '牲畜 #$livestockId' : '';
    final severity = alert['severity'] as String? ?? 'warning';

    final severityColor = switch (severity) {
      'critical' => const Color(0xFFC62828),
      'warning' => const Color(0xFFE65100),
      _ => const Color(0xFF1565C0),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: severityColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: severityColor, width: 4)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('$farmName \u2014 $typeLabel',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Icon(Icons.error_outline, size: 18, color: severityColor),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(message, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ],
            if (livestockLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(livestockLabel, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}
