import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/core/utils/currency_formatter.dart';
import 'package:smart_livestock_demo/features/revenue/domain/revenue_repository.dart';
import 'package:smart_livestock_demo/features/revenue/presentation/revenue_controller.dart';

class B2bRevenuePage extends ConsumerStatefulWidget {
  const B2bRevenuePage({super.key});

  @override
  ConsumerState<B2bRevenuePage> createState() => _B2bRevenuePageState();
}

class _B2bRevenuePageState extends ConsumerState<B2bRevenuePage> {
  _FilterOption _selectedFilter = _FilterOption.all;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(revenueControllerProvider);

    return switch (data.viewState) {
      ViewState.loading => const Center(
          key: Key('b2b-revenue-loading'),
          child: CircularProgressIndicator(),
        ),
      ViewState.error => _ErrorView(
          key: const Key('b2b-revenue-error'),
          message: data.message ?? '加载失败',
        ),
      ViewState.empty => const _EmptyView(
          key: Key('b2b-revenue-empty'),
        ),
      ViewState.forbidden => const _ForbiddenView(
          key: Key('b2b-revenue-forbidden'),
        ),
      ViewState.offline => const _OfflineView(
          key: Key('b2b-revenue-offline'),
        ),
      ViewState.normal => _buildContent(context, data),
    };
  }

  Widget _buildContent(BuildContext context, RevenueListViewData data) {
    final theme = Theme.of(context);
    final filteredPeriods = _applyFilter(data.periods);

    final totalPartnerShare = data.periods.fold<double>(
      0,
      (sum, p) => sum + p.partnerShare,
    );
    final pendingCount =
        data.periods.where((p) => p.status != 'confirmed').length;
    final confirmedCount =
        data.periods.where((p) => p.status == 'confirmed').length;

    return SingleChildScrollView(
      key: const Key('page-b2b-revenue'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Text('对账', style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: AppSpacing.lg),

          // --- Summary metrics (3-column grid) ---
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  key: const Key('b2b-revenue-metric-total'),
                  label: '累计分润',
                  value: formatCurrency(totalPartnerShare),
                  backgroundColor: const Color(0xFFE8F5E9),
                  valueColor: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  key: const Key('b2b-revenue-metric-pending'),
                  label: '待确认数',
                  value: '$pendingCount',
                  backgroundColor: const Color(0xFFFFF3E0),
                  valueColor: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  key: const Key('b2b-revenue-metric-confirmed'),
                  label: '已结算数',
                  value: '$confirmedCount',
                  backgroundColor: const Color(0xFFE3F2FD),
                  valueColor: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Filter pills ---
          Row(
            children: _FilterOption.values.map((option) {
              final isSelected = option == _selectedFilter;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  key: Key('b2b-revenue-filter-${option.name}'),
                  label: Text(option.label),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedFilter = option);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Period cards ---
          if (filteredPeriods.isEmpty)
            const _EmptyView(key: Key('b2b-revenue-filter-empty'))
          else
            ...filteredPeriods.map((period) => _PeriodCard(
                  key: Key('b2b-period-${period.id}'),
                  period: period,
                  onTap: () => context.go(
                    '/b2b/admin/revenue/${period.id}',
                  ),
                )),
        ],
      ),
    );
  }

  List<RevenuePeriod> _applyFilter(List<RevenuePeriod> periods) {
    return switch (_selectedFilter) {
      _FilterOption.all => periods,
      _FilterOption.pending =>
        periods.where((p) => p.status != 'confirmed').toList(),
      _FilterOption.confirmed =>
        periods.where((p) => p.status == 'confirmed').toList(),
    };
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color backgroundColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(
            fontSize: 12,
            color: valueColor.withValues(alpha: 0.8),
          )),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          )),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    super.key,
    required this.period,
    required this.onTap,
  });

  final RevenuePeriod period;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfirmed = period.status == 'confirmed';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: isConfirmed
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatCurrency(period.partnerShare),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _StatusTag(isConfirmed: isConfirmed),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  period.periodLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '点击查看明细',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.isConfirmed});

  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isConfirmed
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConfirmed
                ? Icons.check_circle_outline
                : Icons.pending_outlined,
            size: 14,
            color: isConfirmed
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE65100),
          ),
          const SizedBox(width: 4),
          Text(
            isConfirmed ? '已确认' : '待确认',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isConfirmed
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ViewState fallback views
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: AppSpacing.md),
          Text('加载失败', style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
          )),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(message, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: theme.disabledColor),
            const SizedBox(height: AppSpacing.md),
            Text('暂无对账数据，系统将在每月1日自动生成结算周期',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ForbiddenView extends StatelessWidget {
  const _ForbiddenView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 48, color: theme.disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text('无权限访问', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: theme.disabledColor),
          const SizedBox(height: AppSpacing.md),
          Text('网络不可用', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

enum _FilterOption {
  all('全部'),
  pending('待确认'),
  confirmed('已结算');

  const _FilterOption(this.label);
  final String label;
}

