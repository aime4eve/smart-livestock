import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Tab 3: Dynamic GPS quality testing - route management + dynamic tests + reports.
class DynamicReportTab extends ConsumerStatefulWidget {
  const DynamicReportTab({super.key});

  @override
  ConsumerState<DynamicReportTab> createState() => _DynamicReportTabState();
}

class _DynamicReportTabState extends ConsumerState<DynamicReportTab> {
  int? _selectedRouteId;
  double _threshold = 5.0;
  int? _reportSessionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final routesAsync = ref.watch(dynamicRoutesProvider);

    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(dynamicRoutesProvider),
      ),
      data: (routes) {
        if (routes.isEmpty) {
          return _EmptyRouteState(
              l10n: l10n, onCreate: () => _showCreateRouteDialog(l10n));
        }
        _selectedRouteId ??= routes.first.id;

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final leftPanel = _buildRoutePanel(l10n, routes);
            final rightPanel = _buildReportPanel(l10n, routes);
            if (wide) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 300, child: leftPanel),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: rightPanel),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  leftPanel,
                  const SizedBox(height: AppSpacing.lg),
                  rightPanel,
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -- Left panel: routes + point sequence --

  Widget _buildRoutePanel(AppLocalizations l10n, List<DynamicRoute> routes) {
    return Card(
      key: const Key('dynamic-routes-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(l10n.gpsQualityRouteList,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  key: const Key('add-route-btn'),
                  icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
                  tooltip: l10n.gpsQualityAddRoute,
                  onPressed: () => _showCreateRouteDialog(l10n),
                ),
              ],
            ),
          ),
          ...routes.map((r) {
            final selected = _selectedRouteId == r.id;
            return InkWell(
              key: ValueKey('route-${r.id}'),
              onTap: () => setState(() {
                _selectedRouteId = r.id;
                _reportSessionId = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primarySoft : null,
                  border: Border(
                    left: BorderSide(
                        width: 3,
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          if (r.description != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(r.description!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: AppColors.textSecondary),
                      tooltip: l10n.gpsQualityDeleteRoute,
                      onPressed: () => _deleteRoute(l10n, r),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_selectedRouteId != null)
            _buildPointSequence(l10n, _selectedRouteId!),
        ],
      ),
    );
  }

  Widget _buildPointSequence(AppLocalizations l10n, int routeId) {
    final pointsAsync = ref.watch(routePointsProvider(routeId));
    final rtkPoints = ref.watch(rtkPointsProvider).value ?? [];
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.gpsQualityRoutePoints,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const Spacer(),
              TextButton.icon(
                key: const Key('add-route-point-btn'),
                icon: const Icon(Icons.add, size: 14),
                label: Text(l10n.gpsQualityAddRoutePoint,
                    style: const TextStyle(fontSize: 12)),
                onPressed: () =>
                    _showAddPointDialog(l10n, routeId, rtkPoints),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          pointsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) =>
                Text('$e', style: const TextStyle(fontSize: 11, color: AppColors.danger)),
            data: (points) {
              if (points.isEmpty) {
                return Text(l10n.gpsQualityRouteNoPoints,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary));
              }
              return Column(
                children: points.map((p) {
                  final rtk = rtkPoints
                      .where((r) => r.id == p.rtkPointId)
                      .firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(11)),
                          child: Text('${p.sequenceNo}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            rtk != null
                                ? '${rtk.pointLabel} | ${rtk.locationName}'
                                : '#${p.rtkPointId}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // -- Right panel: create test + report --

  Widget _buildReportPanel(
      AppLocalizations l10n, List<DynamicRoute> routes) {
    final devicesAsync = ref.watch(gpsDevicesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          key: const Key('create-dynamic-test-card'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _CreateDynamicTestForm(
              l10n: l10n,
              routes: routes,
              devices: devicesAsync.value ?? [],
              selectedRouteId: _selectedRouteId,
              onCreated: (sessionId) =>
                  setState(() => _reportSessionId = sessionId),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_reportSessionId != null)
          _buildReport(l10n, _reportSessionId!)
        else
          Card(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.analytics_outlined,
                        size: 40, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.gpsQualityDynamicNoTest,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReport(AppLocalizations l10n, int sessionId) {
    final reportAsync = ref.watch(dynamicReportProvider(
        (sessionId: sessionId, threshold: _threshold)));
    return Card(
      key: const Key('dynamic-report-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.gpsQualityDynamicThreshold,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Expanded(
                  child: Slider(
                    key: const Key('threshold-slider'),
                    value: _threshold,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '${_threshold.round()}m',
                    onChanged: (v) => setState(() => _threshold = v),
                  ),
                ),
                Text('${_threshold.round()}m',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            reportAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child:
                    Text('$e', style: const TextStyle(color: AppColors.danger)),
              ),
              data: (report) =>
                  _ReportContent(l10n: l10n, report: report),
            ),
          ],
        ),
      ),
    );
  }

  // -- Dialogs --

  Future<void> _showCreateRouteDialog(AppLocalizations l10n) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('create-route-dialog'),
        title: Text(l10n.gpsQualityAddRoute),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  key: const Key('route-name-input'),
                  decoration:
                      InputDecoration(labelText: l10n.gpsQualityRouteName)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: descCtrl,
                  key: const Key('route-desc-input'),
                  decoration: InputDecoration(
                      labelText: l10n.gpsQualityRouteDescription),
                  maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.gpsQualityCancelSession)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.gpsQualityAddRoute)),
        ],
      ),
    );
    if (result != true || nameCtrl.text.trim().isEmpty) return;
    try {
      await ref.read(gpsQualityApiRepositoryProvider).createDynamicRoute(
            name: nameCtrl.text.trim(),
            description: descCtrl.text.trim().isEmpty
                ? null
                : descCtrl.text.trim(),
          );
      ref.invalidate(dynamicRoutesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _showAddPointDialog(
      AppLocalizations l10n, int routeId, List<RtkPoint> rtkPoints) async {
    final pointsAsync = ref.read(routePointsProvider(routeId));
    final existing = pointsAsync.value ?? [];
    final nextSeq = existing.isEmpty
        ? 1
        : existing
                .map((p) => p.sequenceNo)
                .reduce((a, b) => a > b ? a : b) +
            1;
    int? selectedPointId;
    int seqNo = nextSeq;
    final result =
        await showDialog<({int rtkPointId, int sequenceNo})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          key: const Key('add-route-point-dialog'),
          title: Text(l10n.gpsQualityAddRoutePoint),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  key: const Key('rtk-point-select'),
                  decoration: InputDecoration(
                      labelText: l10n.gpsQualitySelectRtkPoint),
                  value: selectedPointId,
                  items: rtkPoints
                      .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                              '${p.locationName} | ${p.pointLabel}',
                              style:
                                  const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedPointId = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(l10n.gpsQualityDynamicSequenceNo),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        key: const Key('seq-no-input'),
                        initialValue: '$seqNo',
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(isDense: true),
                        onChanged: (v) =>
                            seqNo = int.tryParse(v) ?? seqNo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.gpsQualityCancelSession)),
            FilledButton(
              onPressed: selectedPointId == null
                  ? null
                  : () => Navigator.pop(ctx,
                      (rtkPointId: selectedPointId!, sequenceNo: seqNo)),
              child: Text(l10n.gpsQualityAddRoutePoint),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final current =
        ref.read(routePointsProvider(routeId)).value ?? [];
    final updated = [
      ...current.map(
          (p) => (rtkPointId: p.rtkPointId, sequenceNo: p.sequenceNo)),
      (rtkPointId: result.rtkPointId, sequenceNo: result.sequenceNo),
    ]..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
    try {
      await ref
          .read(gpsQualityApiRepositoryProvider)
          .replaceRoutePoints(routeId, updated);
      ref.invalidate(routePointsProvider(routeId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteRoute(
      AppLocalizations l10n, DynamicRoute route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('delete-route-dialog'),
        title: Text(l10n.gpsQualityDeleteRoute),
        content: Text('${route.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.gpsQualityCancelSession)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.gpsQualityDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(gpsQualityApiRepositoryProvider)
          .deleteDynamicRoute(route.id);
      ref.invalidate(dynamicRoutesProvider);
      if (_selectedRouteId == route.id) {
        setState(() => _selectedRouteId = null);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

// -- Report content widget --

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.l10n, required this.report});
  final AppLocalizations l10n;
  final DynamicQualityReport report;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM-dd HH:mm');
    final s = report.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _GradeBadge(grade: report.grade),
            const SizedBox(width: AppSpacing.sm),
            Text('${report.deviceCode} | ${report.routeName}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${fmt.format(report.startedAt.toLocal())} -> ${report.endedAt != null ? fmt.format(report.endedAt!.toLocal()) : "..."}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _StatCard(
                label: l10n.gpsQualityRoutePoints,
                value: '${s.routePointCount}'),
            _StatCard(
                label: l10n.gpsQualityDynamicMatched,
                value: '${s.matchedCount}',
                color: AppColors.success),
            _StatCard(
                label: l10n.gpsQualityDynamicMissed,
                value: '${s.missedCount}',
                color: AppColors.danger),
            _StatCard(
                label: l10n.gpsQualityDynamicCoverage,
                value: '${s.coverage.toStringAsFixed(1)}%',
                color: AppColors.success),
            _StatCard(
                label: l10n.gpsQualityDynamicInOrder,
                value: s.inOrder ? 'pass' : 'fail',
                color: s.inOrder ? AppColors.success : AppColors.danger),
            _StatCard(
                label: l10n.gpsQualityDynamicAmbiguous,
                value: '${s.ambiguousCount}',
                color: AppColors.warning),
            _StatCard(
                label: l10n.gpsQualityTipMeanError,
                value: '${s.meanError.toStringAsFixed(1)}m'),
            _StatCard(
                label: 'P50', value: '${s.p50.toStringAsFixed(1)}m'),
            _StatCard(
                label: 'P95', value: '${s.p95.toStringAsFixed(1)}m'),
            _StatCard(
                label: l10n.gpsQualityTipMaxError,
                value: '${s.maxError.toStringAsFixed(1)}m'),
          ],
        ),
        if (report.perPoint.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.gpsQualityRoutePoints,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              key: const Key('per-point-table'),
              columnSpacing: 16,
              columns: [
                DataColumn(
                    label: Text(l10n.gpsQualityDynamicSequenceNo)),
                DataColumn(label: Text(l10n.gpsQualityPointLabel)),
                DataColumn(label: Text(l10n.gpsQualityLocationName)),
                DataColumn(
                    label: Text(l10n.gpsQualityDynamicThreshold)),
                DataColumn(label: Text(l10n.gpsQualityDynamicError)),
                DataColumn(label: Text(l10n.gpsQualityStartTime)),
              ],
              rows: report.perPoint.map((p) {
                final status = !p.passed
                    ? l10n.gpsQualityDynamicMissedPoint
                    : p.ambiguous
                        ? l10n.gpsQualityDynamicAmbiguous
                        : l10n.gpsQualityDynamicPassed;
                final statusColor = !p.passed
                    ? AppColors.danger
                    : p.ambiguous
                        ? AppColors.warning
                        : AppColors.success;
                return DataRow(
                  key: ValueKey('pp-${p.rtkPointId}-${p.sequenceNo}'),
                  cells: [
                    DataCell(Text('${p.sequenceNo}',
                        style: const TextStyle(fontSize: 12))),
                    DataCell(Text(p.label,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
                    DataCell(Text(p.locationName,
                        style: const TextStyle(fontSize: 12))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(status,
                          style:
                              TextStyle(fontSize: 11, color: statusColor)),
                    )),
                    DataCell(Text(
                      p.error != null
                          ? '${p.error!.toStringAsFixed(1)}m'
                          : '-',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.error != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary),
                    )),
                    DataCell(Text(
                      p.matchedAt != null
                          ? fmt.format(p.matchedAt!.toLocal())
                          : '-',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
        if (report.staticComparison != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.gpsQualityStaticComparison,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                  child: _ComparisonCard(
                title: l10n.gpsQualityTestTypeStatic,
                grade: report.staticComparison!.staticGrade,
                p95: report.staticComparison!.staticP95,
              )),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: _ComparisonCard(
                title: l10n.gpsQualityTestTypeDynamic,
                grade: report.grade,
                p95: s.p95,
                delta: report.staticComparison!.deltaP95,
              )),
            ],
          ),
        ],
      ],
    );
  }
}

// -- Helper widgets --

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});
  final QualityGrade grade;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (grade) {
      QualityGrade.excellent => ('EXCELLENT', const Color(0xFF16A34A)),
      QualityGrade.usable => ('USABLE', const Color(0xFF2563EB)),
      QualityGrade.marginal => ('MARGINAL', const Color(0xFFB45309)),
      QualityGrade.unavailable =>
        ('UNAVAILABLE', AppColors.textSecondary),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.title,
    required this.grade,
    required this.p95,
    this.delta,
  });
  final String title;
  final QualityGrade grade;
  final double p95;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          _GradeBadge(grade: grade),
          const SizedBox(height: AppSpacing.sm),
          Text('P95: ${p95.toStringAsFixed(1)}m',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          if (delta != null) ...[
            const SizedBox(height: 2),
            Text(
              delta! < 0
                  ? 'delta ${delta!.abs().toStringAsFixed(1)}m down'
                  : 'delta ${delta!.toStringAsFixed(1)}m up',
              style: TextStyle(
                  fontSize: 11,
                  color: delta! < 0
                      ? AppColors.success
                      : AppColors.danger,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateDynamicTestForm extends ConsumerStatefulWidget {
  const _CreateDynamicTestForm({
    required this.l10n,
    required this.routes,
    required this.devices,
    required this.selectedRouteId,
    required this.onCreated,
  });
  final AppLocalizations l10n;
  final List<DynamicRoute> routes;
  final List<DeviceBrief> devices;
  final int? selectedRouteId;
  final ValueChanged<int> onCreated;

  @override
  ConsumerState<_CreateDynamicTestForm> createState() =>
      _CreateDynamicTestFormState();
}

class _CreateDynamicTestFormState
    extends ConsumerState<_CreateDynamicTestForm> {
  int? _deviceId;
  DateTime? _startedAt;
  DateTime? _endedAt;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.gpsQualityCreateDynamicTest,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                    labelText: l10n.gpsQualitySelectRoute,
                    isDense: true),
                child: Text(
                  widget.routes
                          .where((r) => r.id == widget.selectedRouteId)
                          .firstOrNull
                          ?.name ??
                      '-',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: const Key('dynamic-test-device'),
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: l10n.gpsQualityDevice, isDense: true),
                value: _deviceId,
                items: widget.devices
                    .map((d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.deviceCode,
                            style:
                                const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _deviceId = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
                child: _CompactField(
                    label: l10n.gpsQualityStartTime,
                    value: _startedAt,
                    onChanged: (v) =>
                        setState(() => _startedAt = v))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _CompactField(
                    label: l10n.gpsQualityEndTime,
                    value: _endedAt,
                    onChanged: (v) =>
                        setState(() => _endedAt = v))),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              key: const Key('create-dynamic-test-btn'),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(l10n.gpsQualityCreateDynamicTest,
                      style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final l10n = widget.l10n;
    if (widget.selectedRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.gpsQualityDynamicNoRoute)));
      return;
    }
    if (_deviceId == null || _startedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('select device + start time')));
      return;
    }

    // Pre-check: query device sessions to detect time overlap before submitting
    try {
      final result = await ref
          .read(gpsQualityApiRepositoryProvider)
          .fetchSessions(deviceId: _deviceId);
      final fmt = DateFormat('MM-dd HH:mm');
      for (final s in result.items) {
        if (s.status == CalibrationStatus.canceled) continue;
        final existStart = s.startedAt;
        final existEnd = s.endedAt;
        final newStart = _startedAt!.toUtc();
        final newEnd = _endedAt?.toUtc();
        final startBeforeExistEnd =
            existEnd == null || newStart.isBefore(existEnd);
        final existStartBeforeNewEnd =
            newEnd == null || existStart.isBefore(newEnd);
        if (startBeforeExistEnd && existStartBeforeNewEnd) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              '${l10n.gpsQualityDevice}: ${s.deviceCode} | #${s.id}  ${fmt.format(existStart.toLocal())} -> ${existEnd != null ? fmt.format(existEnd.toLocal()) : "..."}',
            ),
            duration: const Duration(seconds: 4),
          ));
          return;
        }
      }
    } catch (_) {
      // If pre-check fails, proceed and let backend validate
    }

    setState(() => _saving = true);
    try {
      final session = await ref
          .read(gpsQualityApiRepositoryProvider)
          .createDynamicSession(
            deviceId: _deviceId!,
            routeId: widget.selectedRouteId!,
            startedAt: _startedAt!,
            endedAt: _endedAt,
          );
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onCreated(session.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _CompactField extends StatelessWidget {
  const _CompactField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return InputDecorator(
      decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
      child: InkWell(
        onTap: () => _pick(context),
        child: Row(
          children: [
            const Icon(Icons.event, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value != null
                    ? fmt.format(value!.toLocal())
                    : l10n.gpsQualityNoData,
                style: TextStyle(
                    fontSize: 13,
                    color: value != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(value ?? now));
    if (time == null) return;
    onChanged(DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }
}

class _EmptyRouteState extends StatelessWidget {
  const _EmptyRouteState({required this.l10n, required this.onCreate});
  final AppLocalizations l10n;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.gpsQualityDynamicNoRoute,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const Key('empty-create-route-btn'),
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.gpsQualityAddRoute),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: AppColors.danger),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
                onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
