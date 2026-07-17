import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Tab 1: Session-Test workflow.
/// Session = device + time window. Test = sub-range + truth reference.
/// Left: session list. Right: session detail (timeline + test list + report).
class SessionTestTab extends ConsumerStatefulWidget {
  const SessionTestTab({super.key});

  @override
  ConsumerState<SessionTestTab> createState() => _SessionTestTabState();
}

class _SessionTestTabState extends ConsumerState<SessionTestTab> {
  int? _selectedSessionId;
  int? _selectedTestId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionsAsync = ref.watch(gpsSessionsProvider);

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: '$e',
          onRetry: () => ref.invalidate(gpsSessionsProvider)),
      data: (sessions) {
        if (sessions.isEmpty) {
          return _EmptyState(l10n: l10n, onCreate: () => _showCreateSessionDialog(l10n));
        }
        _selectedSessionId ??= sessions.first.id;

        // Watch tests for all sessions to build tags
        final testsBySession = <int, List<CalibrationSession>>{};
        for (final s in sessions) {
          testsBySession[s.id] = ref.watch(sessionTestsProvider(s.id)).value ?? [];
        }

        return LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final left = _buildSessionList(l10n, sessions, testsBySession);
          final right = _buildDetail(l10n);
          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 320, child: SingleChildScrollView(child: left)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: SingleChildScrollView(child: right)),
              ]),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(children: [
              left, const SizedBox(height: AppSpacing.lg), right,
            ]),
          );
        });
      },
    );
  }

  // -- Session list (left panel) --

  Widget _buildSessionList(AppLocalizations l10n, List<GpsQualitySession> sessions,
      Map<int, List<CalibrationSession>> testsBySession) {
    final rtkPoints = ref.watch(rtkPointsProvider).value ?? [];
    return Card(
      key: const Key('session-list-card'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Text(l10n.gpsQualitySessionList, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              key: const Key('create-session-btn'),
              icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
              tooltip: l10n.gpsQualityCreateSession,
              onPressed: () => _showCreateSessionDialog(l10n),
            ),
          ]),
        ),
        ...sessions.map((s) {
          final selected = _selectedSessionId == s.id;
          final tests = testsBySession[s.id] ?? [];
          return InkWell(
            key: ValueKey('session-${s.id}'),
            onTap: () => setState(() {
              _selectedSessionId = s.id;
              _selectedTestId = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySoft : null,
                border: Border(left: BorderSide(width: 3,
                  color: selected ? AppColors.primary : Colors.transparent)),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(s.deviceCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    _statusTag(s.status),
                  ]),
                  const SizedBox(height: 2),
                  Text('${_fmt(s.startedAt)} → ${s.endedAt != null ? _fmt(s.endedAt!) : "..."}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  if (tests.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Wrap(spacing: 3, runSpacing: 2, children: tests.map((t) {
                        final isStatic = t.testType == TestType.static_;
                        final ref = _testRefLabel(t, rtkPoints);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isStatic ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text('${isStatic ? "静" : "动"} $ref',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: isStatic ? const Color(0xFF2563EB) : const Color(0xFFB45309))),
                        );
                      }).toList()),
                    ),
                  if (s.note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(s.note!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ])),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _deleteSession(l10n, s),
                ),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  // -- Detail (right panel) --

  Widget _buildDetail(AppLocalizations l10n) {
    if (_selectedSessionId == null) return const SizedBox();
    final sessions = ref.watch(gpsSessionsProvider).value ?? [];
    final session = sessions.where((s) => s.id == _selectedSessionId).firstOrNull;
    if (session == null) return const SizedBox();

    final testsAsync = ref.watch(sessionTestsProvider(_selectedSessionId!));
    final rtkPoints = ref.watch(rtkPointsProvider).value ?? [];

    return testsAsync.when(
      loading: () => const Card(child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md),
          child: Text('$e', style: const TextStyle(color: AppColors.danger)))),
      data: (tests) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Session header + timeline
        _buildSessionHeader(l10n, session, tests),
        const SizedBox(height: AppSpacing.lg),
        // Test list
        _buildTestList(l10n, session, tests, rtkPoints),
        const SizedBox(height: AppSpacing.lg),
        // Report
        if (_selectedTestId != null)
          _buildReportPanel(l10n)
        else
          Card(child: SizedBox(height: 160, child: Center(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.analytics_outlined, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.sm),
              Text('选择检验查看分析报告', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ])))),
      ]),
    );
  }

  Widget _buildSessionHeader(AppLocalizations l10n, GpsQualitySession session,
      List<CalibrationSession> tests) {
    final rtkPoints = ref.watch(rtkPointsProvider).value ?? [];
    return Card(
      key: const Key('session-header-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${session.deviceCode}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            _statusTag(session.status),
            const Spacer(),
            FilledButton.icon(
              key: const Key('create-test-btn'),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.gpsQualityCreateTest, style: const TextStyle(fontSize: 13)),
              onPressed: () => _showCreateTestDialog(l10n),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${_fmt(session.startedAt)} → ${session.endedAt != null ? _fmt(session.endedAt!) : "..."}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (session.note != null)
            Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(session.note!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          // Timeline
          if (tests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildTimeline(session, tests, rtkPoints),
          ],
        ]),
      ),
    );
  }

  Widget _buildTimeline(GpsQualitySession session, List<CalibrationSession> tests, List<RtkPoint> rtkPoints) {
    final sessionStart = session.startedAt.millisecondsSinceEpoch.toDouble();
    final sessionEnd = (session.endedAt ?? DateTime.now()).millisecondsSinceEpoch.toDouble();
    final totalMs = (sessionEnd - sessionStart).clamp(1.0, double.infinity);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('数据时间轴（检验子时段）', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      Container(
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(children: [
          // Test segments
          ...tests.map((t) {
            final start = t.startedAt.millisecondsSinceEpoch.toDouble();
            final end = (t.endedAt ?? DateTime.now()).millisecondsSinceEpoch.toDouble();
            final leftPct = ((start - sessionStart) / totalMs * 100).clamp(0.0, 100.0);
            final widthPct = ((end - start) / totalMs * 100).clamp(1.0, 100.0 - leftPct);
            final isStatic = t.testType == TestType.static_;
            final isSelected = _selectedTestId == t.id;
            return Positioned(
              left: leftPct,
              top: 2, bottom: 2,
              width: MediaQuery.of(context).size.width * widthPct / 100 * 0.6, // approximate
              child: GestureDetector(
                onTap: () => setState(() => _selectedTestId = t.id),
                child: Tooltip(
                  message: '${isStatic ? "静" : "动"} ${_testRefLabel(t, rtkPoints)}\n${_fmt(t.startedAt)}→${t.endedAt != null ? _fmt(t.endedAt!) : "..."}',
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isStatic ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(4),
                      border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                    ),
                    child: Center(child: Text(
                      isStatic ? '静' : '动',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    )),
                  ),
                ),
              ),
            );
          }),
        ]),
      ),
      const SizedBox(height: 4),
      Row(children: [
        Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF2563EB), borderRadius: BorderRadius.all(Radius.circular(2)))),
        const SizedBox(width: 4),
        const Text('静态段', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFD97706), borderRadius: BorderRadius.all(Radius.circular(2)))),
        const SizedBox(width: 4),
        const Text('动态段', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    ]);
  }

  Widget _buildTestList(AppLocalizations l10n, GpsQualitySession session,
      List<CalibrationSession> tests, List<RtkPoint> rtkPoints) {
    return Card(
      key: const Key('test-list-card'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Text('${l10n.gpsQualityTestList}（${tests.length}）', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        if (tests.isEmpty)
          Padding(padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.science_outlined, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.gpsQualityNoData, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ])))
        else
          ...tests.map((t) => _buildTestCard(l10n, t, rtkPoints)),
      ]),
    );
  }

  Widget _buildTestCard(AppLocalizations l10n, CalibrationSession t, List<RtkPoint> rtkPoints) {
    final selected = _selectedTestId == t.id;
    final isStatic = t.testType == TestType.static_;
    final refLabel = _testRefLabel(t, rtkPoints);
    return InkWell(
      key: ValueKey('test-${t.id}'),
      onTap: () => setState(() => _selectedTestId = t.id),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1)),
          color: selected ? AppColors.primarySoft : null,
        ),
        child: Row(children: [
          Container(width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isStatic ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(isStatic ? Icons.location_on : Icons.directions_walk, size: 18,
              color: isStatic ? const Color(0xFF2563EB) : const Color(0xFFB45309))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${isStatic ? l10n.gpsQualityTestTypeStatic : l10n.gpsQualityTestTypeDynamic} · $refLabel',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${_fmt(t.startedAt)} → ${t.endedAt != null ? _fmt(t.endedAt!) : "..."}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
            visualDensity: VisualDensity.compact,
            onPressed: () => _deleteTest(l10n, t),
          ),
        ]),
      ),
    );
  }

  // -- Report panel --

  Widget _buildReportPanel(AppLocalizations l10n) {
    final tests = ref.watch(sessionTestsProvider(_selectedSessionId!)).value ?? [];
    final test = tests.where((t) => t.id == _selectedTestId).firstOrNull;
    if (test == null) return const SizedBox();

    final isStatic = test.testType == TestType.static_;

    if (isStatic) {
      return _StaticReportCard(testId: test.id);
    } else {
      return _DynamicReportCard(testId: test.id);
    }
  }

  // -- Helpers --

  String _testRefLabel(CalibrationSession t, List<RtkPoint> rtkPoints) {
    if (t.testType == TestType.static_) {
      final rtk = rtkPoints.where((r) => r.id == t.rtkPointId).firstOrNull;
      return rtk != null ? '${rtk.pointLabel}·${rtk.locationName}' : '#${t.rtkPointId}';
    } else {
      final routes = ref.read(dynamicRoutesProvider).value ?? [];
      final route = routes.where((r) => r.id == t.routeId).firstOrNull;
      return route != null ? route.name : '#${t.routeId}';
    }
  }

  String _fmt(DateTime dt) => DateFormat('MM-dd HH:mm').format(dt.toLocal());

  Widget _statusTag(SessionStatus s) {
    final (label, color) = switch (s) {
      SessionStatus.inProgress => ('进行中', AppColors.warning),
      SessionStatus.completed => ('已完成', AppColors.success),
      SessionStatus.canceled => ('已取消', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  // -- Dialogs --

  Future<void> _showCreateSessionDialog(AppLocalizations l10n) async {
    final devices = ref.read(gpsDevicesProvider).value ?? [];
    int? deviceId;
    DateTime startedAt = DateTime.now();
    DateTime? endedAt;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        key: const Key('create-session-dialog'),
        title: Text(l10n.gpsQualityCreateSession),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(
            decoration: InputDecoration(labelText: l10n.gpsQualityDevice),
            value: deviceId,
            items: devices.map((d) => DropdownMenuItem(value: d.id,
              child: Text(d.deviceCode, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setS(() => deviceId = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DateTimeRow(label: l10n.gpsQualityStartTime, value: startedAt,
            onChanged: (v) => setS(() => startedAt = v)),
          const SizedBox(height: AppSpacing.sm),
          _DateTimeRow(label: l10n.gpsQualityEndTime, value: endedAt,
            onChanged: (v) => setS(() => endedAt = v)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.gpsQualityCancelSession)),
          FilledButton(
            onPressed: deviceId == null ? null : () async {
              Navigator.pop(ctx);
              try {
                await ref.read(gpsQualityApiRepositoryProvider).createGpsSession(
                  deviceId: deviceId!, startedAt: startedAt, endedAt: endedAt);
                ref.invalidate(gpsSessionsProvider);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: Text(l10n.gpsQualityCreateSession),
          ),
        ],
      )),
    );
  }

  Future<void> _showCreateTestDialog(AppLocalizations l10n) async {
    if (_selectedSessionId == null) return;
    final points = ref.read(rtkPointsProvider).value ?? [];
    final routes = ref.read(dynamicRoutesProvider).value ?? [];
    var testType = TestType.static_;
    int? rtkPointId;
    int? routeId;
    var testStartedAt = DateTime.now();
    DateTime? testEndedAt;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        key: const Key('create-test-dialog'),
        title: Text(l10n.gpsQualityCreateTest),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: RadioListTile<TestType>(
              dense: true, value: TestType.static_, groupValue: testType,
              title: Text(l10n.gpsQualityTestTypeStatic, style: const TextStyle(fontSize: 13)),
              onChanged: (v) => setS(() => testType = v!),
            )),
            Expanded(child: RadioListTile<TestType>(
              dense: true, value: TestType.dynamic_, groupValue: testType,
              title: Text(l10n.gpsQualityTestTypeDynamic, style: const TextStyle(fontSize: 13)),
              onChanged: (v) => setS(() => testType = v!),
            )),
          ]),
          const SizedBox(height: AppSpacing.sm),
          if (testType == TestType.static_)
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: l10n.gpsQualitySelectRtkPoint),
              value: rtkPointId,
              items: points.map((p) => DropdownMenuItem(value: p.id,
                child: Text('${p.locationName} · ${p.pointLabel}', style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setS(() => rtkPointId = v),
            )
          else
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: l10n.gpsQualitySelectRoute),
              value: routeId,
              items: routes.map((r) => DropdownMenuItem(value: r.id,
                child: Text(r.name, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setS(() => routeId = v),
            ),
          const SizedBox(height: AppSpacing.sm),
          _DateTimeRow(label: l10n.gpsQualityStartTime, value: testStartedAt,
            onChanged: (v) => setS(() => testStartedAt = v)),
          const SizedBox(height: AppSpacing.sm),
          _DateTimeRow(label: l10n.gpsQualityEndTime, value: testEndedAt,
            onChanged: (v) => setS(() => testEndedAt = v)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.gpsQualityCancelSession)),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(gpsQualityApiRepositoryProvider).createTest(
                  sessionId: _selectedSessionId!, testType: testType,
                  rtkPointId: testType == TestType.static_ ? rtkPointId : null,
                  routeId: testType == TestType.dynamic_ ? routeId : null,
                  testStartedAt: testStartedAt, testEndedAt: testEndedAt);
                ref.invalidate(sessionTestsProvider(_selectedSessionId!));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: Text(l10n.gpsQualityCreateTest),
          ),
        ],
      )),
    );
  }

  Future<void> _deleteSession(AppLocalizations l10n, GpsQualitySession s) async {
    final ok = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.gpsQualityDelete),
        content: Text('${s.deviceCode}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.gpsQualityCancelSession)),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.gpsQualityDelete)),
        ])) ?? false;
    if (!ok) return;
    try {
      await ref.read(gpsQualityApiRepositoryProvider).deleteGpsSession(s.id);
      ref.invalidate(gpsSessionsProvider);
      if (_selectedSessionId == s.id) setState(() => _selectedSessionId = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteTest(AppLocalizations l10n, CalibrationSession t) async {
    try {
      await ref.read(gpsQualityApiRepositoryProvider).deleteTest(t.id);
      ref.invalidate(sessionTestsProvider(_selectedSessionId!));
      if (_selectedTestId == t.id) setState(() => _selectedTestId = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

// -- Static report card --

class _StaticReportCard extends ConsumerWidget {
  const _StaticReportCard({required this.testId});
  final int testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportAsync = ref.watch(qualityReportProvider(
      (sessionId: testId, excludeSuspect: true),
    ));

    return Card(
      key: const Key('static-report-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.danger)),
          data: (report) {
            final s = report.stats;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _GradeBadge(grade: report.grade),
                const SizedBox(width: AppSpacing.sm),
                Text('${l10n.gpsQualityTestTypeStatic} · ${report.rtkPoint.pointLabel}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${DateFormat('MM-dd HH:mm').format(report.startedAt.toLocal())} → ${report.endedAt != null ? DateFormat('MM-dd HH:mm').format(report.endedAt!.toLocal()) : "..."}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [
                _StatCard(label: l10n.gpsQualityTipEffectivePoints, value: '${s.effectivePoints}'),
                _StatCard(label: 'P95', value: '${s.p95.toStringAsFixed(1)}m',
                  color: s.p95 <= 10 ? AppColors.success : s.p95 <= 25 ? AppColors.warning : AppColors.danger),
                _StatCard(label: 'P50', value: '${s.p50.toStringAsFixed(1)}m', color: AppColors.info),
                _StatCard(label: l10n.gpsQualityTipMeanError, value: '${s.meanError.toStringAsFixed(1)}m'),
                _StatCard(label: l10n.gpsQualityTipJitterDiameter, value: '${s.jitterDiameter.toStringAsFixed(1)}m'),
                _StatCard(label: l10n.gpsQualityTipMaxError, value: '${s.maxError.toStringAsFixed(1)}m',
                  color: AppColors.warning),
              ]),
            ]);
          },
        ),
      ),
    );
  }
}

// -- Dynamic report card --

class _DynamicReportCard extends ConsumerWidget {
  const _DynamicReportCard({required this.testId});
  final int testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportAsync = ref.watch(dynamicReportProvider(
      (sessionId: testId, threshold: 30.0),
    ));

    return Card(
      key: const Key('dynamic-report-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e', style: const TextStyle(color: AppColors.danger)),
          data: (report) {
            final s = report.stats;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _GradeBadge(grade: report.grade),
                const SizedBox(width: AppSpacing.sm),
                Text('${l10n.gpsQualityTestTypeDynamic} · ${report.routeName}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${DateFormat('MM-dd HH:mm').format(report.startedAt.toLocal())} → ${report.endedAt != null ? DateFormat('MM-dd HH:mm').format(report.endedAt!.toLocal()) : "..."}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [
                _StatCard(label: l10n.gpsQualityRoutePoints, value: '${s.routePointCount}'),
                _StatCard(label: l10n.gpsQualityDynamicMatched, value: '${s.matchedCount}', color: AppColors.success),
                _StatCard(label: l10n.gpsQualityDynamicMissed, value: '${s.missedCount}', color: AppColors.danger),
                _StatCard(label: l10n.gpsQualityDynamicCoverage, value: '${s.coverage.toStringAsFixed(1)}%', color: AppColors.success),
                _StatCard(label: 'P95', value: '${s.p95.toStringAsFixed(1)}m'),
                _StatCard(label: l10n.gpsQualityDynamicAmbiguous, value: '${s.ambiguousCount}', color: AppColors.warning),
              ]),
              if (report.perPoint.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text('逐 RTK 点误差明细', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(scrollDirection: Axis.horizontal,
                  child: DataTable(
                    key: const Key('per-point-table'), columnSpacing: 16,
                    columns: [
                      const DataColumn(label: Text('序号')),
                      DataColumn(label: Text(l10n.gpsQualityPointLabel)),
                      DataColumn(label: Text(l10n.gpsQualityLocationName)),
                      DataColumn(label: Text(l10n.gpsQualityDynamicThreshold)),
                      DataColumn(label: Text(l10n.gpsQualityDynamicError)),
                    ],
                    rows: report.perPoint.map((p) {
                      final status = !p.passed
                        ? l10n.gpsQualityDynamicMissedPoint
                        : p.ambiguous ? l10n.gpsQualityDynamicAmbiguous : l10n.gpsQualityDynamicPassed;
                      final statusColor = !p.passed ? AppColors.danger : p.ambiguous ? AppColors.warning : AppColors.success;
                      return DataRow(key: ValueKey('pp-${p.rtkPointId}-${p.sequenceNo}'), cells: [
                        DataCell(Text('${p.sequenceNo}', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(p.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        DataCell(Text(p.locationName, style: const TextStyle(fontSize: 12))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(status, style: TextStyle(fontSize: 11, color: statusColor)),
                        )),
                        DataCell(Text(p.error != null ? '${p.error!.toStringAsFixed(1)}m' : '-',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: p.error != null ? AppColors.textPrimary : AppColors.textSecondary))),
                      ]);
                    }).toList(),
                  )),
              ],
            ]);
          },
        ),
      ),
    );
  }
}

// -- Shared widgets --

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color = AppColors.textPrimary});
  final String label; final String value; final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110, padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ]),
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
      QualityGrade.unavailable => ('UNAVAILABLE', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return InputDecorator(
      decoration: InputDecoration(labelText: label, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final date = await showDatePicker(context: context, initialDate: value ?? now,
            firstDate: DateTime(now.year - 1), lastDate: now);
          if (date == null || !context.mounted) return;
          final time = await showTimePicker(context: context,
            initialTime: TimeOfDay.fromDateTime(value ?? now));
          if (time == null) return;
          onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
        },
        child: Row(children: [
          const Icon(Icons.event, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Expanded(child: Text(value != null ? fmt.format(value!.toLocal()) : '-',
            style: TextStyle(fontSize: 13, color: value != null ? AppColors.textPrimary : AppColors.textSecondary))),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.onCreate});
  final AppLocalizations l10n;
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.history, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.gpsQualityNoData, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(onPressed: onCreate,
          icon: const Icon(Icons.add, size: 16), label: Text(l10n.gpsQualityCreateSession)),
      ])));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
        const SizedBox(height: AppSpacing.sm),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ])));
  }
}
