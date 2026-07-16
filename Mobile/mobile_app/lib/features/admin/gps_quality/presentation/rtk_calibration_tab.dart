import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Tab 1: RTK calibration management (location-centric, matching prototype).
///
/// Left sidebar: location-grouped accordion. Selecting a location (or any
/// point within it) selects the whole location.
/// Right panel: merged table of all points + their sessions for that location.
class RtkCalibrationTab extends ConsumerStatefulWidget {
  const RtkCalibrationTab({super.key});

  @override
  ConsumerState<RtkCalibrationTab> createState() => _RtkCalibrationTabState();
}

class _RtkCalibrationTabState extends ConsumerState<RtkCalibrationTab> {
  String? _selectedLocation;
  final Set<String> _expandedLocations = {};
  bool _showUncalibrated = false;

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
        if (_selectedLocation == null && locations.isNotEmpty) {
          _selectedLocation = locations.keys.first;
          _expandedLocations.add(_selectedLocation!);
        }

        // Pre-fetch sessions for all points in the selected location
        // (ref.watch in a loop inside build — must be here, not in helper)
        final selectedPoints = locations[_selectedLocation] ?? [];
        final pointSessions = <int, List<CalibrationSession>>{};
        for (final p in selectedPoints) {
          final asyncVal = ref.watch(calibrationSessionsProvider(p.id));
          pointSessions[p.id] = asyncVal.value ?? [];
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final sidebar = _buildSidebar(l10n, locations);
            final detail = _buildDetail(l10n, selectedPoints, pointSessions);
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
                  child: Text(l10n.gpsQualityRtkPointList,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
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
              ...locations.entries.map((entry) => _AccordionItem(
                    locationName: entry.key,
                    points: entry.value,
                    expanded: _expandedLocations.contains(entry.key),
                    selected: _selectedLocation == entry.key,
                    onToggle: () => setState(() {
                      if (_expandedLocations.contains(entry.key)) {
                        _expandedLocations.remove(entry.key);
                      } else {
                        _expandedLocations.add(entry.key);
                      }
                      _selectedLocation = entry.key;
                    }),
                    onSelectPoint: (id) => setState(() {
                      // Clicking a point selects its location
                      final point = entry.value.firstWhere((p) => p.id == id);
                      _selectedLocation = point.locationName;
                    }),
                    onDelete: (id) => _deletePoint(l10n, id),
                  )),
          ],
        ),
      ),
    );
  }

  // ── Detail (merged location-level table) ────────────────────────

  Widget _buildDetail(AppLocalizations l10n, List<RtkPoint> locationPoints,
      Map<int, List<CalibrationSession>> pointSessions) {
    if (locationPoints.isEmpty) {
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

    final locName = locationPoints.first.locationName;

    // Collect sessions for all points in this location
    final sessionRows = <_SessionRow>[];
    final uncalibratedPoints = <RtkPoint>[];

    for (final point in locationPoints) {
      final sessions = pointSessions[point.id] ?? [];
      if (sessions.isEmpty) {
        uncalibratedPoints.add(point);
      } else {
        for (final s in sessions) {
          sessionRows.add(_SessionRow(point: point, session: s));
        }
      }
    }

    final hasAnySession = sessionRows.isNotEmpty;

    return Card(
      key: Key('rtk-detail-$locName'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: location name + point count + create button
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(locName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${locationPoints.length} ${l10n.gpsQualityPointLabel.contains("点位") ? "个点位" : "points"}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary)),
                ),
                const Spacer(),
                FilledButton.icon(
                  key: const Key('add-session-btn'),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l10n.gpsQualityAddSession),
                  onPressed: () =>
                      _showCreateSessionDialog(l10n, locationPoints.first),
                ),
              ],
            ),
          ),
          // Merged sessions table
          if (!hasAnySession)
            Padding(
              key: const Key('empty-sessions'),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_outlined,
                      size: 40, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.gpsQualityNoData,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            )
          else
            _buildMergedTable(l10n, sessionRows),
          // Collapsible uncalibrated points
          if (uncalibratedPoints.isNotEmpty) _buildUncalibratedSection(l10n, uncalibratedPoints),
        ],
      ),
    );
  }

  Widget _buildMergedTable(AppLocalizations l10n, List<_SessionRow> rows) {
    final fmt = DateFormat('MM-dd HH:mm');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('merged-sessions-table'),
        columnSpacing: 16,
        columns: [
          DataColumn(label: Text(l10n.gpsQualityPointLabel)),
          const DataColumn(label: Text('RTK')),
          DataColumn(label: Text(l10n.gpsQualityDevice)),
          DataColumn(label: Text(l10n.gpsQualityStartTime)),
          DataColumn(label: Text(l10n.gpsQualityStatus)),
          const DataColumn(label: Text('')),
        ],
        rows: rows.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          final isFirstForPoint =
              idx == 0 || rows[idx - 1].point.id != row.point.id;
          return DataRow(
            key: ValueKey('merged-row-${row.session.id}'),
            color: row.session.status == CalibrationStatus.canceled
                ? WidgetStateProperty.all(AppColors.surface)
                : null,
            cells: [
              DataCell(Text(isFirstForPoint ? row.point.pointLabel : '',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(
                  isFirstForPoint
                      ? '${row.point.latitude.toStringAsFixed(5)}, ${row.point.longitude.toStringAsFixed(5)}'
                      : '',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary))),
              DataCell(Text(row.session.deviceCode,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: row.session.status == CalibrationStatus.canceled
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: row.session.status == CalibrationStatus.canceled
                          ? AppColors.textSecondary
                          : AppColors.textPrimary))),
              DataCell(Text(
                  '${fmt.format(row.session.startedAt.toLocal())} → ${row.session.endedAt != null ? fmt.format(row.session.endedAt!.toLocal()) : '...'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
              DataCell(_statusPill(l10n, row.session.status)),
              DataCell(_buildActions(l10n, row.session)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUncalibratedSection(
      AppLocalizations l10n, List<RtkPoint> points) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showUncalibrated = !_showUncalibrated),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
              child: Row(
                children: [
                  Icon(
                      _showUncalibrated
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 16,
                      color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text('${points.length} uncalibrated',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          if (_showUncalibrated)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: points
                    .map((p) => Chip(
                          label: Text(p.pointLabel,
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(AppLocalizations l10n, CalibrationSession s) {
    switch (s.status) {
      case CalibrationStatus.inProgress:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              key: const Key('end-session-btn'),
              onPressed: () => _confirmEndSession(l10n, s),
              icon: const Icon(Icons.stop, size: 14),
              label: Text(l10n.gpsQualityEndSession, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: AppSpacing.xs),
            OutlinedButton(
              key: const Key('cancel-session-btn'),
              onPressed: () => _confirmCancelSession(l10n, s),
              child: Text(l10n.gpsQualityCancelSession, style: const TextStyle(fontSize: 12)),
            ),
          ],
        );
      case CalibrationStatus.completed:
        return OutlinedButton(
          key: const Key('delete-completed-btn'),
          onPressed: () => _confirmDeleteSession(l10n, s),
          child: Text(l10n.gpsQualityDelete, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
        );
      case CalibrationStatus.canceled:
        return OutlinedButton(
          key: const Key('delete-canceled-btn'),
          onPressed: () => _confirmDeleteSession(l10n, s),
          child: Text(l10n.gpsQualityDelete, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
        );
    }
  }

  Widget _statusPill(AppLocalizations l10n, CalibrationStatus status) {
    switch (status) {
      case CalibrationStatus.inProgress:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(l10n.gpsQualityStatusInProgress,
              style: const TextStyle(fontSize: 11, color: AppColors.warning)),
        );
      case CalibrationStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(l10n.gpsQualityStatusCompleted,
              style: const TextStyle(fontSize: 11, color: AppColors.success)),
        );
      case CalibrationStatus.canceled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(l10n.gpsQualityStatusCanceled,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        );
    }
  }

  // ── Actions ──────────────────────────────────────────────────────

  Future<void> _deletePoint(AppLocalizations l10n, int id) async {
    final ok = await ref.read(rtkPointsProvider.notifier).deletePoint(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '✅' : '❌')),
    );
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
    ref.invalidate(calibrationSessionsProvider(session.rtkPointId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '✅' : '❌')),
    );
  }

  Future<void> _confirmCancelSession(
      AppLocalizations l10n, CalibrationSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('cancel-session-dialog'),
        title: Text(l10n.gpsQualityCancelSession),
        content: Text(l10n.gpsQualityEndSessionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.gpsQualityCancelSession),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(calibrationSessionsProvider(session.rtkPointId).notifier)
        .deleteSession(session.id);
    if (!mounted) return;
    ref.invalidate(calibrationSessionsProvider(session.rtkPointId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '✅' : '❌')),
    );
  }

  Future<void> _confirmDeleteSession(
      AppLocalizations l10n, CalibrationSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('delete-session-dialog'),
        title: Text(l10n.gpsQualityDelete),
        content: Text(l10n.gpsQualityDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.gpsQualityDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(calibrationSessionsProvider(session.rtkPointId).notifier)
        .deleteSession(session.id);
    if (!mounted) return;
    ref.invalidate(calibrationSessionsProvider(session.rtkPointId));
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
    // After dialog closes, invalidate all session providers for points in
    // the current location so the merged table refreshes.
    if (mounted) {
      final points = _groupByLocation(
          ref.read(rtkPointsProvider).value ?? []);
      final locPoints = points[_selectedLocation] ?? [];
      for (final p in locPoints) {
        ref.invalidate(calibrationSessionsProvider(p.id));
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Map<String, List<RtkPoint>> _groupByLocation(List<RtkPoint> points) {
    final map = <String, List<RtkPoint>>{};
    for (final p in points) {
      map.putIfAbsent(p.locationName, () => []).add(p);
    }
    return map;
  }
}

// ── Accordion item (location) ─────────────────────────────────────

class _AccordionItem extends StatelessWidget {
  const _AccordionItem({
    required this.locationName,
    required this.points,
    required this.expanded,
    required this.selected,
    required this.onToggle,
    required this.onSelectPoint,
    required this.onDelete,
  });

  final String locationName;
  final List<RtkPoint> points;
  final bool expanded;
  final bool selected;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelectPoint;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
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
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary)),
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
                return InkWell(
                  key: Key('rtk-point-${p.id}'),
                  onTap: () => onSelectPoint(p.id),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                        32, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                    decoration: const BoxDecoration(
                        border:
                            Border(top: BorderSide(color: AppColors.border))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.pointLabel,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary)),
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

/// A merged row linking a point to one of its sessions.
class _SessionRow {
  const _SessionRow({required this.point, required this.session});
  final RtkPoint point;
  final CalibrationSession session;
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
