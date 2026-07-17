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

        return LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final left = _buildSessionList(l10n, sessions);
          final right = _buildDetail(l10n);
          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 320, child: left),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: right),
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

  Widget _buildSessionList(AppLocalizations l10n, List<GpsQualitySession> sessions) {
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
                  Text(s.deviceCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${_fmt(s.startedAt)} → ${s.endedAt != null ? _fmt(s.endedAt!) : "..."}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Row(children: [
                    _statusTag(s.status),
                    const SizedBox(width: 4),
                    if (s.note != null)
                      Flexible(child: Text(s.note!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
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
    final testsAsync = ref.watch(sessionTestsProvider(_selectedSessionId!));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Session header + create test button
      Card(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Text(l10n.gpsQualityTestList, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            FilledButton.icon(
              key: const Key('create-test-btn'),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.gpsQualityCreateTest, style: const TextStyle(fontSize: 13)),
              onPressed: () => _showCreateTestDialog(l10n),
            ),
          ]),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      // Test list
      testsAsync.when(
        loading: () => const Card(child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))),
        error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('$e', style: const TextStyle(color: AppColors.danger)))),
        data: (tests) {
          if (tests.isEmpty) {
            return Card(child: SizedBox(height: 160, child: Center(child: Column(
              mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.science_outlined, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.gpsQualityNoData, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]))));
          }
          return Card(child: Column(children: tests.map((t) => _buildTestCard(l10n, t)).toList()));
        },
      ),
    ]);
  }

  Widget _buildTestCard(AppLocalizations l10n, CalibrationSession t) {
    final selected = _selectedTestId == t.id;
    final isStatic = t.testType == TestType.static_;
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
            Text('${isStatic ? l10n.gpsQualityTestTypeStatic : l10n.gpsQualityTestTypeDynamic} #${t.id}',
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
          // Type toggle
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
          // Truth ref
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
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  // -- Helpers --

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
