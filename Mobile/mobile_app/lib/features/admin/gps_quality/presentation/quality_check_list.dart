import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/create_check_dialog.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/batch_import_dialog.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/scatter_chart.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/route_match_chart.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/edit_retry_dialog.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Tab 1: Quality check list — device-grouped checks with timeline & reports.
///
/// Left panel: devices grouped by EUI, showing check count & type distribution.
/// Right panel: selected device detail (overview + visual timeline + report).
class QualityCheckList extends ConsumerStatefulWidget {
  const QualityCheckList({super.key});

  @override
  ConsumerState<QualityCheckList> createState() => _QualityCheckListState();
}

class _QualityCheckListState extends ConsumerState<QualityCheckList> {
  String? _selectedDeviceCode;
  int? _selectedCheckId;
  String? _statusFilter;
  String? _euiFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checksAsync = ref.watch(checksProvider);

    return checksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(checksProvider),
      ),
      data: (result) {
        if (result.items.isEmpty) {
          return _EmptyState(
            l10n: l10n,
            onCreateCheck: () => _showCreateCheckDialog(l10n),
            onBatchImport: () => _showBatchImportDialog(l10n),
          );
        }

        // Front-end filter: status + EUI/device code substring (case-insensitive)
        final query = (_euiFilter ?? '').trim().toLowerCase();
        final filtered = result.items.where((c) {
          if (_statusFilter != null && c.status != _statusFilter) return false;
          if (query.isNotEmpty &&
              !c.deviceCode.toLowerCase().contains(query)) {
            return false;
          }
          return true;
        }).toList();

        final hasAnyPending =
            result.items.any((c) => c.status == 'DEVICE_PENDING');

        // Group checks by device code (EUI)
        final grouped = <String, List<QualityCheck>>{};
        for (final c in filtered) {
          final key = c.deviceCode.isEmpty ? '(no eui)' : c.deviceCode;
          grouped.putIfAbsent(key, () => []).add(c);
        }

        // Sort groups by latest check time descending
        final sortedGroups = grouped.entries.toList()
          ..sort((a, b) {
            final aLatest = a.value.map((c) => c.startedAt).reduce(
              (x, y) => x.isAfter(y) ? x : y);
            final bLatest = b.value.map((c) => c.startedAt).reduce(
              (x, y) => x.isAfter(y) ? x : y);
            return bLatest.compareTo(aLatest);
          });

        // Select first if none selected, or reset when the selected device
        // is filtered out
        if (sortedGroups.isNotEmpty &&
            (_selectedDeviceCode == null ||
                !grouped.containsKey(_selectedDeviceCode))) {
          _selectedDeviceCode = sortedGroups.first.key;
          final firstChecks = List<QualityCheck>.from(sortedGroups.first.value)
            ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
          _selectedCheckId = firstChecks.first.id;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final left = _buildDeviceGroupList(l10n, sortedGroups);
            final right = _buildDeviceDetail(l10n, grouped, hasAnyPending);
            if (wide) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: SingleChildScrollView(child: left)),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: SingleChildScrollView(child: right)),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(children: [
                left, const SizedBox(height: AppSpacing.lg), right,
              ]),
            );
          },
        );
      },
    );
  }

  // ── Left panel: device-grouped list ─────────────────────────────

  Widget _buildDeviceGroupList(
    AppLocalizations l10n,
    List<MapEntry<String, List<QualityCheck>>> groups,
  ) {
    return Card(
      key: const Key('device-group-list'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header with toolbar
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(l10n.gpsQualityDeviceGroup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  key: const Key('create-check-btn'),
                  icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
                  tooltip: l10n.gpsQualityCreateCheck,
                  onPressed: () => _showCreateCheckDialog(l10n),
                ),
                IconButton(
                  key: const Key('batch-import-btn'),
                  icon: const Icon(Icons.upload_file, color: AppColors.primary, size: 20),
                  tooltip: l10n.gpsQualityBatchImport,
                  onPressed: () => _showBatchImportDialog(l10n),
                ),
              ]),
              const SizedBox(height: AppSpacing.sm),
              // Search (EUI / device code substring) + status filter
              Row(children: [
                Expanded(
                  child: TextField(
                    key: const Key('device-search-field'),
                    controller: _searchController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: l10n.gpsQualitySearchDeviceHint,
                      hintStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => setState(() => _euiFilter = v),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<String>(
                    key: const Key('status-filter-dropdown'),
                    value: _statusFilter,
                    isDense: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textPrimary),
                    items: [
                      DropdownMenuItem(
                          value: null,
                          child: Text(l10n.gpsQualityFilterAllStatus,
                              style: const TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'READY',
                          child: Text(l10n.gpsQualityCheckStatusReady,
                              style: const TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'DEVICE_PENDING',
                          child: Text(l10n.gpsQualityCheckStatusPending,
                              style: const TextStyle(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'FAILED',
                          child: Text(l10n.gpsQualityCheckStatusFailed,
                              style: const TextStyle(fontSize: 12))),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v),
                  ),
                ),
              ]),
            ],
          ),
        ),
        // Device group items
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Text(l10n.gpsQualityNoMatchDevice,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ),
        ...groups.map((entry) {
          final deviceCode = entry.key;
          final checks = entry.value;
          final selected = _selectedDeviceCode == deviceCode;
          final hasPending = checks.any((c) => c.status == 'DEVICE_PENDING');
          final hasFailed = checks.any((c) => c.status == 'FAILED');
          final staticCount = checks.where((c) => c.checkType == 'STATIC').length;
          final dynamicCount = checks.where((c) => c.checkType == 'DYNAMIC').length;

          return InkWell(
            key: ValueKey('device-group-$deviceCode'),
            onTap: () => setState(() {
              _selectedDeviceCode = deviceCode;
              // Auto-select the first check of this device
              final sortedChecks = List<QualityCheck>.from(checks)
                ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
              _selectedCheckId = sortedChecks.isNotEmpty ? sortedChecks.first.id : null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySoft : null,
                border: Border(
                  left: BorderSide(
                    width: 3,
                    color: selected ? AppColors.primary : Colors.transparent,
                  ),
                ),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(deviceCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                    ),
                    if (hasPending) _statusTag(l10n.gpsQualityCheckStatusPending, AppColors.warning),
                    if (hasFailed) _statusTag(l10n.gpsQualityCheckStatusFailed, AppColors.danger),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text('${l10n.gpsQualityChecksCount(checks.length)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    if (staticCount > 0) ...[
                      const SizedBox(width: 6),
                      _typeTag(l10n.gpsQualityStaticChecks, const Color(0xFF2563EB)),
                    ],
                    if (dynamicCount > 0) ...[
                      const SizedBox(width: 4),
                      _typeTag(l10n.gpsQualityDynamicChecks, const Color(0xFFB45309)),
                    ],
                  ]),
                  // Latest check time
                  Text(
                    '${DateFormat('MM-dd HH:mm').format(checks.first.startedAt)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ])),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _statusTag(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _typeTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }

  // ── Right panel: device detail ──────────────────────────────────

  Widget _buildDeviceDetail(AppLocalizations l10n, Map<String, List<QualityCheck>> grouped, bool hasAnyPending) {
    if (_selectedDeviceCode == null) return const SizedBox();
    final checks = grouped[_selectedDeviceCode];
    if (checks == null || checks.isEmpty) return const SizedBox();

    // Sort checks by startedAt ascending for timeline
    final sortedChecks = List<QualityCheck>.from(checks)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final rtkPoints = ref.watch(rtkPointsProvider).value ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Device overview card
      _buildOverview(l10n, _selectedDeviceCode!, checks, hasAnyPending),
      const SizedBox(height: AppSpacing.lg),
      // Timeline
      if (checks.length > 1)
        _buildTimeline(l10n, sortedChecks, rtkPoints),
      const SizedBox(height: AppSpacing.lg),
      // Report for selected check
      if (_selectedCheckId != null)
        _buildReport(l10n, _selectedCheckId!, rtkPoints)
      else
        Card(
          key: const Key('no-check-selected-card'),
          child: SizedBox(
            height: 160,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.analytics_outlined, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.gpsQualityNoData, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            ),
          ),
        ),
    ]);
  }

  Widget _buildOverview(AppLocalizations l10n, String deviceCode, List<QualityCheck> checks, bool hasAnyPending) {
    final hasPending = checks.any((c) => c.status == 'DEVICE_PENDING');
    final hasFailed = checks.any((c) => c.status == 'FAILED');
    final first = checks.first;
    final last = checks.last;

    return Card(
      key: const Key('device-overview-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(deviceCode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${l10n.gpsQualityChecksCount(checks.length)}',
                style: const TextStyle(fontSize: 11, color: AppColors.primary)),
            ),
            const Spacer(),
            // Actions for pending/failed devices
            if (hasAnyPending) ...[
              FilledButton.icon(
                key: const Key('batch-register-btn'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.info),
                icon: const Icon(Icons.wifi_tethering, size: 14),
                label: Text(l10n.gpsQualityBatchRegister, style: const TextStyle(fontSize: 11)),
                onPressed: _registerAllPending,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (hasPending) ...[
              OutlinedButton.icon(
                key: const Key('pending-register-btn'),
                icon: const Icon(Icons.wifi_tethering, size: 14),
                label: Text(l10n.gpsQualityManualRegister, style: const TextStyle(fontSize: 11)),
                onPressed: () => _registerPending(deviceCode),
              ),
              const SizedBox(width: AppSpacing.sm),
              _deleteDeviceButton(l10n, checks,
                  key: const Key('delete-device-btn')),
            ],
          ]),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('yyyy-MM-dd HH:mm').format(first.startedAt)} → ${last.endedAt != null ? DateFormat('MM-dd HH:mm').format(last.endedAt!) : '...'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (hasFailed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 14, color: AppColors.danger),
                  const SizedBox(width: 4),
                  Text(l10n.gpsQualityImportFailed,
                    style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      final failed = checks.where((c) => c.status == 'FAILED').firstOrNull;
                      if (failed != null) _editRetryCheck(failed);
                    },
                    child: Text(l10n.gpsQualityEditAndRetry, style: const TextStyle(fontSize: 11)),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Timeline ────────────────────────────────────────────────────

  Widget _buildTimeline(AppLocalizations l10n, List<QualityCheck> sortedChecks, List<RtkPoint> rtkPoints) {
    if (sortedChecks.isEmpty) return const SizedBox();
    final overallStart = sortedChecks.first.startedAt.millisecondsSinceEpoch.toDouble();
    final overallEnd = (sortedChecks.last.endedAt ?? sortedChecks.last.startedAt).millisecondsSinceEpoch.toDouble();
    final totalMs = (overallEnd - overallStart).clamp(1.0, double.infinity);

    return Card(
      key: const Key('timeline-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.gpsQualityTimeline, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return Container(
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                ...sortedChecks.map((c) {
                  final start = c.startedAt.millisecondsSinceEpoch.toDouble();
                  final end = (c.endedAt ?? DateTime.now()).millisecondsSinceEpoch.toDouble();
                  final leftFrac = ((start - overallStart) / totalMs).clamp(0.0, 1.0);
                  final rightFrac = ((end - overallStart) / totalMs).clamp(0.0, 1.0);
                  final segLeft = leftFrac * barWidth;
                  final segWidth = ((rightFrac - leftFrac) * barWidth).clamp(8.0, barWidth);
                  final isStatic = c.checkType == 'STATIC';
                  final isSelected = _selectedCheckId == c.id;
                  final isFailed = c.status == 'FAILED';
                  return Positioned(
                    left: segLeft,
                    top: 3, bottom: 3,
                    width: segWidth,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCheckId = c.id),
                      child: Tooltip(
                        message: '${isStatic ? "静态" : "动态"} · ${isFailed ? "失败" : "${c.status}"}\n${DateFormat('MM-dd HH:mm').format(c.startedAt)} → ${c.endedAt != null ? DateFormat('MM-dd HH:mm').format(c.endedAt!) : "..."}',
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isFailed
                                ? AppColors.danger
                                : (isStatic ? const Color(0xFF2563EB) : const Color(0xFFD97706)),
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
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
            );
          }),
          const SizedBox(height: 4),
          // Time axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MM-dd HH:mm').format(sortedChecks.first.startedAt),
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text(DateFormat('MM-dd HH:mm').format(sortedChecks.last.endedAt ?? sortedChecks.last.startedAt),
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(children: [
            _timelineLegend(const Color(0xFF2563EB), l10n.gpsQualityTestTypeStatic),
            const SizedBox(width: AppSpacing.md),
            _timelineLegend(const Color(0xFFD97706), l10n.gpsQualityTestTypeDynamic),
            const SizedBox(width: AppSpacing.md),
            _timelineLegend(AppColors.danger, l10n.gpsQualityImportFailed),
          ]),
        ]),
      ),
    );
  }

  Widget _timelineLegend(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }

  // ── Report ──────────────────────────────────────────────────────

  Widget _buildReport(AppLocalizations l10n, int checkId, List<RtkPoint> rtkPoints) {
    // Find the check to determine type
    final allChecks = ref.watch(checksProvider).value?.items ?? [];
    final check = allChecks.where((c) => c.id == checkId).firstOrNull;
    if (check == null) return const SizedBox();

    if (check.status == 'FAILED') {
      return _buildFailedReport(l10n, check);
    }

    if (check.checkType == 'STATIC') {
      return _StaticReportCard(testId: checkId);
    } else {
      return _DynamicReportCard(testId: checkId);
    }
  }

  Widget _buildFailedReport(AppLocalizations l10n, QualityCheck check) {
    final allChecks = ref.watch(checksProvider).value?.items ?? [];
    final deviceChecks =
        allChecks.where((c) => c.deviceCode == check.deviceCode).toList();
    return Card(
      key: const Key('failed-check-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.gpsQualityImportFailed, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.danger)),
          const SizedBox(height: AppSpacing.sm),
          if (check.errorMessage != null)
            Text(check.errorMessage!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          Row(mainAxisSize: MainAxisSize.min, children: [
            FilledButton.icon(
              key: const Key('edit-retry-from-check'),
              icon: const Icon(Icons.edit, size: 16),
              label: Text(l10n.gpsQualityEditAndRetry),
              onPressed: () => _editRetryCheck(check),
            ),
            const SizedBox(width: AppSpacing.sm),
            _deleteDeviceButton(l10n, deviceChecks,
                key: const Key('failed-delete-device-btn')),
          ]),
        ]),
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────

  void _showCreateCheckDialog(AppLocalizations l10n) {
    showDialog(context: context, builder: (_) => const CreateCheckDialog()).then((_) {
      ref.invalidate(checksProvider);
    });
  }

  void _showBatchImportDialog(AppLocalizations l10n) {
    showDialog(context: context, builder: (_) => const BatchImportDialog()).then((_) {
      ref.invalidate(checksProvider);
    });
  }

  void _editRetryCheck(QualityCheck check) {
    showDialog(
      context: context,
      builder: (_) => EditRetryDialog(failedCheck: check),
    ).then((_) {
      ref.invalidate(checksProvider);
    });
  }

  /// Manual register: retry blade registration for this device's pending checks.
  Future<void> _registerPending(String deviceCode) async {
    final checks = ref.read(checksProvider).value?.items ?? [];
    final pendingIds = checks
        .where((c) =>
            c.deviceCode == deviceCode && c.status == 'DEVICE_PENDING')
        .map((c) => c.id)
        .toList();
    final l10n = AppLocalizations.of(context)!;
    if (pendingIds.isEmpty) return;

    try {
      await ref
          .read(gpsQualityApiRepositoryProvider)
          .retryRegistration(checkIds: pendingIds);
    } catch (_) {}
    ref.invalidate(checksProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gpsQualityRegisterSuccess)),
      );
    }
  }

  /// Batch register: retry blade registration for ALL pending checks.
  Future<void> _registerAllPending() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(gpsQualityApiRepositoryProvider).retryRegistration();
    } catch (_) {}
    ref.invalidate(checksProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gpsQualityRegisterSuccess)),
      );
    }
  }

  Widget _deleteDeviceButton(
    AppLocalizations l10n,
    List<QualityCheck> checks, {
    Key? key,
  }) {
    if (!checks.any((c) => c.deviceId != null)) return const SizedBox();
    return OutlinedButton.icon(
      key: key,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: AppColors.danger),
      ),
      icon: const Icon(Icons.delete_outline, size: 14),
      label: Text(l10n.gpsQualityDeleteDevice,
          style: const TextStyle(fontSize: 11)),
      onPressed: () => _deleteDeviceChecks(l10n, checks),
    );
  }

  /// Delete all quality checks of a device (the device itself is kept).
  Future<void> _deleteDeviceChecks(
      AppLocalizations l10n, List<QualityCheck> checks) async {
    final deviceId =
        checks.map((c) => c.deviceId).whereType<int>().firstOrNull;
    if (deviceId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('delete-device-confirm-dialog'),
        title: Text(l10n.gpsQualityDeleteDevice),
        content: Text(l10n.gpsQualityDeleteDeviceConfirm(checks.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('delete-device-confirm-btn'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final deleted = await ref
          .read(gpsQualityApiRepositoryProvider)
          .deleteChecksByDevice(deviceId);
      if (!mounted) return;
      setState(() {
        _selectedDeviceCode = null;
        _selectedCheckId = null;
      });
      ref.invalidate(checksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gpsQualityDeleteDeviceSuccess(deleted))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

// ── Static report card (reused from session_test_tab.dart) ──────────

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
                Text('${DateFormat('MM-dd HH:mm').format(report.startedAt)} → ${report.endedAt != null ? DateFormat('MM-dd HH:mm').format(report.endedAt!) : "..."}',
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
              // Scatter chart
              if (report.scatter.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.gpsQualityScatterChart, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: GpsScatterChart(
                    key: const Key('scatter-chart'),
                    points: report.scatter,
                    p50: s.p50,
                    p95: s.p95,
                    rtkLatitude: report.rtkPoint.latitude,
                    rtkLongitude: report.rtkPoint.longitude,
                  ),
                ),
              ],
              // Distance distribution bars
              const SizedBox(height: AppSpacing.md),
              _DistanceDistribution(stats: s),
            ]);
          },
        ),
      ),
    );
  }
}

// ── Dynamic report card ─────────────────────────────────────────────

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
            // Assemble route RTK points (with coordinates & match outcome)
            // for the route match chart.
            final routePoints =
                ref.watch(routePointsProvider(report.routeId)).value ?? [];
            final rtkPoints = ref.watch(rtkPointsProvider).value ?? [];
            final matchPoints = routePoints.map((rp) {
              final rtk =
                  rtkPoints.where((p) => p.id == rp.rtkPointId).firstOrNull;
              if (rtk == null) return null;
              final summary = report.perPoint
                  .where((p) => p.rtkPointId == rp.rtkPointId)
                  .firstOrNull;
              final status = summary == null || !summary.passed
                  ? RouteMatchStatus.missed
                  : summary.ambiguous
                      ? RouteMatchStatus.ambiguous
                      : RouteMatchStatus.matched;
              return RouteMatchPoint(
                sequenceNo: rp.sequenceNo,
                latitude: rtk.latitude,
                longitude: rtk.longitude,
                status: status,
              );
            }).whereType<RouteMatchPoint>().toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _GradeBadge(grade: report.grade),
                const SizedBox(width: AppSpacing.sm),
                Text('${l10n.gpsQualityTestTypeDynamic} · ${report.routeName}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${DateFormat('MM-dd HH:mm').format(report.startedAt)} → ${report.endedAt != null ? DateFormat('MM-dd HH:mm').format(report.endedAt!) : "..."}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [
                _StatCard(label: l10n.gpsQualityRoutePoints, value: '${s.routePointCount}'),
                _StatCard(label: l10n.gpsQualityDynamicMatched, value: '${s.matchedCount}', color: AppColors.success),
                _StatCard(label: l10n.gpsQualityDynamicMissed, value: '${s.missedCount}', color: AppColors.danger),
                _StatCard(label: l10n.gpsQualityDynamicCoverage, value: '${s.coverage.toStringAsFixed(1)}%', color: AppColors.success),
                _StatCard(label: l10n.gpsQualityDynamicAmbiguous, value: '${s.ambiguousCount}', color: AppColors.warning),
                _StatCard(label: l10n.gpsQualityDynamicOrderOk, value: s.inOrder ? '✅' : '❌'),
                _StatCard(label: l10n.gpsQualityTipMeanError, value: '${s.meanError.toStringAsFixed(1)}m'),
                _StatCard(label: 'P50', value: '${s.p50.toStringAsFixed(1)}m', color: AppColors.info),
                _StatCard(label: 'P95', value: '${s.p95.toStringAsFixed(1)}m'),
              ]),
              // Route match chart
              if (matchPoints.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.gpsQualityRouteMatchChart, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: RouteMatchChart(
                    key: const Key('route-match-chart'),
                    points: matchPoints,
                    passes: report.passes,
                  ),
                ),
              ],
              if (report.perPoint.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.gpsQualityDynamicThreshold, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(scrollDirection: Axis.horizontal,
                  child: DataTable(
                    key: const Key('per-point-table'), columnSpacing: 16,
                    columns: [
                      DataColumn(label: Text(l10n.gpsQualityDynamicSequenceNo)),
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

// ── Shared widgets ─────────────────────────────────────────────────


class _DistanceDistribution extends StatelessWidget {
  const _DistanceDistribution({required this.stats});
  final GpsQualityStats stats;

  @override
  Widget build(BuildContext context) {
    final w15 = stats.within15m.clamp(0.0, 100.0);
    final w25 = stats.within25m.clamp(0.0, 100.0);
    final w40 = stats.within40m.clamp(0.0, 100.0);
    final b1 = w15;
    final b2 = (w25 - w15).clamp(0.0, 100.0);
    final b3 = (w40 - w25).clamp(0.0, 100.0);
    final b4 = (100.0 - w40).clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('误差分布', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        _distBar('0-15m', b1, const Color(0xFF66BB6A)),
        const SizedBox(height: AppSpacing.xs),
        _distBar('15-25m', b2, const Color(0xFF2563EB)),
        const SizedBox(height: AppSpacing.xs),
        _distBar('25-40m', b3, const Color(0xFFF59E0B)),
        const SizedBox(height: AppSpacing.xs),
        _distBar('>40m', b4, const Color(0xFFDC2626)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text('≤25m 累计: ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('${w25.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(width: AppSpacing.lg),
            Text('≤40m 累计: ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('${w40.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
          ],
        ),
      ],
    );
  }

  Widget _distBar(String label, double percent, Color color) {
    final clamped = percent.clamp(0.0, 100.0);
    return Row(
      children: [
        SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped / 100.0,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 16,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: 40, child: Text('${clamped.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11))),
      ],
    );
  }
}

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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.onCreateCheck, required this.onBatchImport});
  final AppLocalizations l10n;
  final VoidCallback onCreateCheck;
  final VoidCallback onBatchImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.checklist, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.gpsQualityNoChecks, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: AppSpacing.lg),
          Row(mainAxisSize: MainAxisSize.min, children: [
            FilledButton.icon(
              key: const Key('empty-create-check-btn'),
              onPressed: onCreateCheck,
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.gpsQualityCreateCheck),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              key: const Key('empty-batch-import-btn'),
              onPressed: onBatchImport,
              icon: const Icon(Icons.upload_file, size: 16),
              label: Text(l10n.gpsQualityBatchImport),
            ),
          ]),
        ]),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      ),
    );
  }
}
