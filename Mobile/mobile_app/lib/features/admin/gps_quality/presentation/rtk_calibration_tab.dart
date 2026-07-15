import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Tab 1: RTK calibration management.
///
/// Left sidebar: location-grouped accordion of RTK points.
/// Right panel: calibration sessions for the selected point.
class RtkCalibrationTab extends ConsumerStatefulWidget {
  const RtkCalibrationTab({super.key});

  @override
  ConsumerState<RtkCalibrationTab> createState() => _RtkCalibrationTabState();
}

class _RtkCalibrationTabState extends ConsumerState<RtkCalibrationTab> {
  int? _selectedPointId;
  final Set<String> _expandedLocations = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pointsAsync = ref.watch(rtkPointsProvider);

    return pointsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(rtkPointsProvider),
      ),
      data: (points) {
        final locations = _groupByLocation(points);
        if (_selectedPointId == null && points.isNotEmpty) {
          _selectedPointId = points.first.id;
          _expandedLocations.add(points.first.locationName);
        }
        final selected = _findPoint(points, _selectedPointId);

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final sidebar = _buildSidebar(l10n, locations);
            final detail = selected == null
                ? _buildEmptyDetail(l10n)
                : _buildDetail(l10n, selected);
            if (wide) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: sidebar),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: detail),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  sidebar,
                  const SizedBox(height: AppSpacing.lg),
                  detail,
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Sidebar (accordion) ──────────────────────────────────────────

  Widget _buildSidebar(
      AppLocalizations l10n, Map<String, List<RtkPoint>> locations) {
    return Card(
      key: const Key('rtk-sidebar-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.gpsQualityRtkPointList,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  key: const Key('add-rtk-point-btn'),
                  icon: const Icon(Icons.add_location_alt,
                      color: AppColors.primary, size: 20),
                  tooltip: l10n.gpsQualityAddRtkPoint,
                  onPressed: () => _showCreatePointDialog(l10n),
                ),
              ],
            ),
            const Divider(height: AppSpacing.sm),
            if (locations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(l10n.gpsQualityNoData,
                    style: const TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...locations.entries.map((entry) {
                final expanded = _expandedLocations.contains(entry.key);
                return _AccordionItem(
                  locationName: entry.key,
                  points: entry.value,
                  expanded: expanded,
                  selectedPointId: _selectedPointId,
                  onToggle: () => setState(() {
                    if (expanded) {
                      _expandedLocations.remove(entry.key);
                    } else {
                      _expandedLocations.add(entry.key);
                    }
                  }),
                  onSelect: (id) => setState(() => _selectedPointId = id),
                  onDelete: (id) => _deletePoint(l10n, id),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── Detail (sessions table) ──────────────────────────────────────

  Widget _buildEmptyDetail(AppLocalizations l10n) {
    return Card(
      child: SizedBox(
        height: 240,
        child: Center(
          child: Text(l10n.gpsQualityNoData,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildDetail(AppLocalizations l10n, RtkPoint point) {
    final sessionsAsync =
        ref.watch(calibrationSessionsProvider(point.id));
    return Card(
      key: const Key('rtk-sessions-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(point.pointLabel,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${point.locationName} · ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('add-session-btn'),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.gpsQualityAddSession),
                  onPressed: () => _showCreateSessionDialog(l10n, point),
                ),
              ],
            ),
          ),
          // table
          sessionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorView(
              message: '$e',
              onRetry: () => ref
                  .invalidate(calibrationSessionsProvider(point.id)),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(l10n.gpsQualityNoData,
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                );
              }
              return _SessionsTable(
                sessions: sessions,
                onEnd: (s) => _confirmEndSession(l10n, s),
                onDelete: (s) => _deleteSession(l10n, s),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────

  Future<void> _deletePoint(AppLocalizations l10n, int id) async {
    final ok = await ref.read(rtkPointsProvider.notifier).deletePoint(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '✅' : '❌')),
    );
    if (ok && _selectedPointId == id) {
      setState(() => _selectedPointId = null);
    }
  }

  Future<void> _confirmEndSession(
      AppLocalizations l10n, CalibrationSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('end-session-dialog'),
        title: Text(l10n.gpsQualityEndSession),
        content: Text(l10n.gpsQualityEndSessionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.gpsQualityCancelSession),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.gpsQualityEndSession),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(calibrationSessionsProvider(session.rtkPointId).notifier)
        .endSession(session.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '✅' : '❌')),
    );
  }

  Future<void> _deleteSession(
      AppLocalizations l10n, CalibrationSession session) async {
    final ok = await ref
        .read(calibrationSessionsProvider(session.rtkPointId).notifier)
        .deleteSession(session.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '✅' : '❌')),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────

  Future<void> _showCreatePointDialog(AppLocalizations l10n) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _CreatePointDialog(l10n: l10n, ref: ref),
    );
  }

  Future<void> _showCreateSessionDialog(
      AppLocalizations l10n, RtkPoint point) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) =>
          _CreateSessionDialog(l10n: l10n, ref: ref, defaultPoint: point),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Map<String, List<RtkPoint>> _groupByLocation(List<RtkPoint> points) {
    final map = <String, List<RtkPoint>>{};
    for (final p in points) {
      map.putIfAbsent(p.locationName, () => []).add(p);
    }
    return map;
  }

  RtkPoint? _findPoint(List<RtkPoint> points, int? id) {
    if (id == null) return null;
    for (final p in points) {
      if (p.id == id) return p;
    }
    return null;
  }
}

// ── Accordion item ─────────────────────────────────────────────────

class _AccordionItem extends StatelessWidget {
  const _AccordionItem({
    required this.locationName,
    required this.points,
    required this.expanded,
    required this.selectedPointId,
    required this.onToggle,
    required this.onSelect,
    required this.onDelete,
  });

  final String locationName;
  final List<RtkPoint> points;
  final bool expanded;
  final int? selectedPointId;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            key: Key('location-header-$locationName'),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              child: Row(
                children: [
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: AppColors.textSecondary),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(locationName,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Text('${points.length}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          if (expanded)
            Column(
              children: points.map((p) {
                final selected = p.id == selectedPointId;
                return InkWell(
                  key: Key('rtk-point-${p.id}'),
                  onTap: () => onSelect(p.id),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                        32, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primarySoft : null,
                      border: const Border(
                          top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.pointLabel,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textPrimary)),
                              const SizedBox(height: 1),
                              Text(
                                '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: AppColors.textSecondary),
                          tooltip: 'Delete',
                          onPressed: () => onDelete(p.id),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ── Sessions table ─────────────────────────────────────────────────

class _SessionsTable extends StatelessWidget {
  const _SessionsTable({
    required this.sessions,
    required this.onEnd,
    required this.onDelete,
  });

  final List<CalibrationSession> sessions;
  final ValueChanged<CalibrationSession> onEnd;
  final ValueChanged<CalibrationSession> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('MM-dd HH:mm');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('sessions-table'),
        columnSpacing: 20,
        columns: [
          DataColumn(label: Text(l10n.gpsQualityDevice)),
          DataColumn(label: Text(l10n.gpsQualityStartTime)),
          DataColumn(label: Text(l10n.gpsQualityEndTime)),
          DataColumn(label: Text(l10n.gpsQualityStatus)),
          const DataColumn(label: Text('')),
        ],
        rows: sessions.map((s) {
          return DataRow(
            key: ValueKey('session-row-${s.id}'),
            cells: [
              DataCell(Text(s.deviceCode,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(fmt.format(s.startedAt.toLocal()),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
              DataCell(Text(
                s.endedAt != null
                    ? fmt.format(s.endedAt!.toLocal())
                    : '—',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              )),
              DataCell(_statusPill(l10n, s.status)),
              DataCell(_buildActions(l10n, s)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions(AppLocalizations l10n, CalibrationSession s) {
    if (s.status == CalibrationStatus.inProgress) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.tonal(
            key: Key('end-session-${s.id}'),
            onPressed: () => onEnd(s),
            child: Text(l10n.gpsQualityEndSession),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: l10n.gpsQualityCancelSession,
            onPressed: () => onDelete(s),
          ),
        ],
      );
    }
    return IconButton(
      icon: const Icon(Icons.delete_outline, size: 18),
      tooltip: l10n.gpsQualityCancelSession,
      onPressed: () => onDelete(s),
    );
  }
}

Widget _statusPill(AppLocalizations l10n, CalibrationStatus status) {
  switch (status) {
    case CalibrationStatus.inProgress:
      return _pill(l10n.gpsQualityStatusInProgress, AppColors.info,
          const Color(0xFFDBEAFE));
    case CalibrationStatus.completed:
      return _pill(l10n.gpsQualityStatusCompleted, AppColors.success,
          const Color(0xFFDCFCE7));
    case CalibrationStatus.canceled:
      return _pill(l10n.gpsQualityStatusCanceled, AppColors.textSecondary,
          const Color(0xFFF1F5F9));
  }
}

Widget _pill(String label, Color fg, Color bg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
  );
}

// ── Error view ─────────────────────────────────────────────────────

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
            const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Create point dialog ────────────────────────────────────────────

class _CreatePointDialog extends ConsumerStatefulWidget {
  const _CreatePointDialog({required this.l10n, required this.ref});
  final AppLocalizations l10n;
  final WidgetRef ref;

  @override
  ConsumerState<_CreatePointDialog> createState() => _CreatePointDialogState();
}

class _CreatePointDialogState extends ConsumerState<_CreatePointDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _locationName;
  late TextEditingController _locationCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _locationCtrl = TextEditingController();
    _labelCtrl = TextEditingController();
    _latCtrl = TextEditingController();
    _lngCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _labelCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      key: const Key('create-point-dialog'),
      title: Text(l10n.gpsQualityAddRtkPoint),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _locationCtrl,
                key: const Key('point-location-input'),
                decoration: InputDecoration(labelText: l10n.gpsQualityLocationName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.gpsQualityLocationName : null,
                onChanged: (v) => _locationName = v,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _labelCtrl,
                key: const Key('point-label-input'),
                decoration: InputDecoration(labelText: l10n.gpsQualityPointLabel),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.gpsQualityPointLabel : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      key: const Key('point-lat-input'),
                      decoration: InputDecoration(labelText: l10n.gpsQualityLatitude),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: _validateDouble(l10n.gpsQualityLatitude),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _lngCtrl,
                      key: const Key('point-lng-input'),
                      decoration: InputDecoration(labelText: l10n.gpsQualityLongitude),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: _validateDouble(l10n.gpsQualityLongitude),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.gpsQualityCancelSession),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(l10n.gpsQualityAddRtkPoint),
        ),
      ],
    );
  }

  String? Function(String?) _validateDouble(String fieldName) {
    return (v) {
      if (v == null || v.isEmpty) return fieldName;
      if (double.tryParse(v) == null) return fieldName;
      return null;
    };
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final location = _locationName ?? _locationCtrl.text.trim();
    if (location.isEmpty) return;
    setState(() => _saving = true);
    final ok = await ref.read(rtkPointsProvider.notifier).createPoint(
          locationName: location,
          pointLabel: _labelCtrl.text.trim(),
          latitude: double.parse(_latCtrl.text.trim()),
          longitude: double.parse(_lngCtrl.text.trim()),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '✅' : '❌')),
    );
  }
}

// ── Create session dialog ──────────────────────────────────────────

class _CreateSessionDialog extends ConsumerStatefulWidget {
  const _CreateSessionDialog({
    required this.l10n,
    required this.ref,
    required this.defaultPoint,
  });
  final AppLocalizations l10n;
  final WidgetRef ref;
  final RtkPoint defaultPoint;

  @override
  ConsumerState<_CreateSessionDialog> createState() =>
      _CreateSessionDialogState();
}

class _CreateSessionDialogState extends ConsumerState<_CreateSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _rtkPointId;
  int? _deviceId;
  DateTime? _startedAt;
  DateTime? _endedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rtkPointId = widget.defaultPoint.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final pointsAsync = ref.watch(rtkPointsProvider);
    final devicesAsync = ref.watch(gpsDevicesProvider);
    return AlertDialog(
      key: const Key('create-session-dialog'),
      title: Text(l10n.gpsQualityAddSession),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              pointsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (points) => DropdownButtonFormField<int>(
                  key: const Key('session-rtk-point-field'),
                  decoration: InputDecoration(labelText: l10n.gpsQualitySelectRtkPoint),
                  value: _rtkPointId,
                  items: points
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.locationName} · ${p.pointLabel}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _rtkPointId = v ?? _rtkPointId),
                  validator: (v) => v == null ? l10n.gpsQualitySelectRtkPoint : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              devicesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (devices) => DropdownButtonFormField<int>(
                  key: const Key('session-device-field'),
                  decoration: InputDecoration(labelText: l10n.gpsQualitySelectDevice),
                  value: _deviceId,
                  items: devices
                      .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.deviceCode),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _deviceId = v),
                  validator: (v) => v == null ? l10n.gpsQualitySelectDevice : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _DateTimeField(
                      key: const Key('session-start-field'),
                      label: l10n.gpsQualityStartTime,
                      value: _startedAt,
                      onChanged: (v) => setState(() => _startedAt = v),
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DateTimeField(
                      key: const Key('session-end-field'),
                      label: l10n.gpsQualityEndTime,
                      value: _endedAt,
                      onChanged: (v) => setState(() => _endedAt = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.gpsQualityCancelSession),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(l10n.gpsQualityAddSession),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_deviceId == null || _startedAt == null) return;
    setState(() => _saving = true);
    final ok = await ref
        .read(calibrationSessionsProvider(_rtkPointId).notifier)
        .createSession(
          deviceId: _deviceId!,
          startedAt: _startedAt!,
          endedAt: _endedAt,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '✅' : '❌')),
    );
  }
}

/// Date+time picker field.
class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return FormField<DateTime>(
      validator: (v) {
        if (isRequired && value == null) return label;
        return null;
      },
      builder: (state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: state.errorText,
          ),
          child: InkWell(
            onTap: () => _pick(context),
            child: Row(
              children: [
                const Icon(Icons.event, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    value != null ? fmt.format(value!.toLocal()) : l10n.gpsQualityNoData,
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
      },
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
      initialTime: TimeOfDay.fromDateTime(value ?? now),
    );
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}
