import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/admin/analytics/domain/analytics_models.dart';
import 'package:smart_livestock_demo/features/admin/analytics/presentation/analytics_controller.dart';
import 'package:smart_livestock_demo/features/stats/domain/stats_repository.dart';
import 'package:smart_livestock_demo/features/stats/presentation/widgets/trend_chart.dart';
import 'package:smart_livestock_demo/l10n/gen/app_localizations.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  DateTimeRange? _dateRange;

  DateTime get _from => _dateRange?.start ?? DateTime.now().subtract(const Duration(days: 7));
  DateTime get _to => _dateRange?.end ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(analyticsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsTitle)),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('$e'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(analyticsControllerProvider.notifier).refresh(_from, _to),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(analyticsControllerProvider.notifier).refresh(_from, _to),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _buildDateSelector(context),
              const SizedBox(height: AppSpacing.md),
              _buildOverviewCards(context, data.overview),
              const SizedBox(height: AppSpacing.lg),
              TrendChart(
                title: '调用趋势',
                trend: data.trend.map((p) => StatsTrendPoint(date: p.date, value: p.totalCalls.toDouble())).toList(),
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              TrendChart(
                title: '平均响应时间 (ms)',
                trend: data.trend.map((p) => StatsTrendPoint(date: p.date, value: p.avgResponseMs.toDouble())).toList(),
                color: Colors.orange,
                suffix: 'ms',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.date_range, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text('${_fmt(_from)} ~ ${_fmt(_to)}'),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.edit_calendar, size: 18),
              label: Text(l10n.analyticsSelectRange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, UsageOverview overview) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _metricCard(context, Icons.api, '总调用', '${overview.totalCalls}', AppColors.primary),
        _metricCard(context, Icons.check_circle, '成功', '${overview.successCalls}', AppColors.success),
        _metricCard(context, Icons.error, '错误', '${overview.errorCalls}', AppColors.danger),
        _metricCard(context, Icons.speed, '成功率', '${(overview.successRate * 100).toStringAsFixed(1)}%', AppColors.info),
        _metricCard(context, Icons.timer, '平均响应', '${overview.avgResponseMs.toStringAsFixed(0)}ms', Colors.orange),
      ],
    );
  }

  Widget _metricCard(BuildContext context, IconData icon, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 4),
            Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      ref.read(analyticsControllerProvider.notifier).refresh(picked.start, picked.end);
    }
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
