import 'package:excel/excel.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/web_file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';

import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// One editable row in the batch-create table.
class _BatchRow {
  _BatchRow({this.rtkPointId, this.deviceId, this.startedAt, this.endedAt});
  int? rtkPointId;
  int? deviceId;
  DateTime? startedAt; // null = use common time
  DateTime? endedAt; // null = use common time
  String? error; // validation / creation error
}

/// Batch-create dialog for RTK calibration sessions.
///
/// Supports manual row entry and Excel (.xlsx) import/export.
/// Each row pairs a device with an RTK point; the common start/end time
/// at the top applies to all rows unless a row has its own time (from
/// Excel import).
class BatchCreateSessionDialog extends ConsumerStatefulWidget {
  const BatchCreateSessionDialog({
    super.key,
    required this.defaultPoint,
    required this.points,
    required this.devices,
  });

  final RtkPoint defaultPoint;
  final List<RtkPoint> points;
  final List<DeviceBrief> devices;

  @override
  ConsumerState<BatchCreateSessionDialog> createState() =>
      _BatchCreateSessionDialogState();
}

class _BatchCreateSessionDialogState
    extends ConsumerState<BatchCreateSessionDialog> {
  final _rows = <_BatchRow>[];
  DateTime _commonStartedAt = DateTime.now();
  DateTime? _commonEndedAt;
  bool _saving = false;
  int _progressDone = 0;
  int _progressTotal = 0;

  // Lookup maps for Excel import
  late final Map<String, int> _deviceByCode;
  late final Map<String, int> _pointByLabel;

  @override
  void initState() {
    super.initState();
    _rows.add(_BatchRow(rtkPointId: widget.defaultPoint.id));
    _deviceByCode = {
      for (final d in widget.devices) d.deviceCode: d.id,
    };
    _pointByLabel = {
      for (final p in widget.points) p.pointLabel: p.id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      key: const Key('batch-create-session-dialog'),
      child: Container(
        width: 820,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title + toolbar ──────────────────────────────
              Row(
                children: [
                  Text(l10n.gpsQualityBatchCreate,
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  OutlinedButton.icon(
                    key: const Key('import-excel-btn'),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(l10n.gpsQualityImportExcel),
                    onPressed: _saving ? null : _importExcel,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  OutlinedButton.icon(
                    key: const Key('download-template-btn'),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(l10n.gpsQualityDownloadTemplate),
                    onPressed: _downloadTemplate,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  OutlinedButton.icon(
                    key: const Key('add-row-btn'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.gpsQualityAddRow),
                    onPressed: _saving ? null : _addRow,
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),

              // ── Common time ──────────────────────────────────
              _buildCommonTime(l10n),
              const Divider(height: AppSpacing.lg),

              // ── Table header ─────────────────────────────────
              _buildTableHeader(l10n),

              // ── Scrollable rows ──────────────────────────────
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _rows.length,
                  itemBuilder: (ctx, i) => _buildRow(l10n, i),
                ),
              ),

              // ── Actions ──────────────────────────────────────
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.gpsQualityCancelSession),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    key: const Key('batch-submit-btn'),
                    onPressed: _saving || _rows.isEmpty ? null : _submit,
                    child: _saving
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.gpsQualityBatchProgress(
                                  _progressDone, _progressTotal)),
                            ],
                          )
                        : Text(l10n.gpsQualityBatchCreateN(_rows.length)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Common time section ──────────────────────────────────────

  Widget _buildCommonTime(AppLocalizations l10n) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return Row(
      children: [
        Expanded(
          child: _CompactTimeField(
            label: l10n.gpsQualityStartTime,
            value: _commonStartedAt,
            onChanged: (v) => setState(() => _commonStartedAt = v),
            isRequired: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CompactTimeField(
            label: l10n.gpsQualityEndTime,
            value: _commonEndedAt,
            onChanged: (v) => setState(() => _commonEndedAt = v),
          ),
        ),
      ],
    );
  }

  // ── Table header ─────────────────────────────────────────────

  Widget _buildTableHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(l10n.gpsQualitySelectRtkPointShort,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(flex: 3, child: Text(l10n.gpsQualitySelectDeviceShort,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          const SizedBox(width: 40), // delete button column
        ],
      ),
    );
  }

  // ── Table row ────────────────────────────────────────────────

  Widget _buildRow(AppLocalizations l10n, int index) {
    final row = _rows[index];
    final hasCustomTime = row.startedAt != null || row.endedAt != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // RTK point dropdown
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  key: Key('row-$index-point'),
                  value: row.rtkPointId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                  items: widget.points
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                                '${p.locationName} · ${p.pointLabel}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => row.rtkPointId = v),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Device dropdown
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  key: Key('row-$index-device'),
                  value: row.deviceId != null &&
                          widget.devices.any((d) => d.id == row.deviceId)
                      ? row.deviceId
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    errorText: null, // shown below
                  ),
                  items: widget.devices
                      .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.deviceCode,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => row.deviceId = v),
                ),
              ),
              // Custom time indicator
              if (hasCustomTime)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: row.startedAt != null
                        ? '${l10n.gpsQualityStartTime}: ${DateFormat('MM-dd HH:mm').format(row.startedAt!.toLocal())}'
                        : '',
                    child: const Icon(Icons.schedule,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),
              // Delete button
              IconButton(
                key: Key('row-$index-delete'),
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.danger),
                onPressed: _saving ? null : () => _removeRow(index),
                tooltip: l10n.gpsQualityDeleteRow,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (row.error != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2, bottom: 4),
              child: Text(
                row.error!,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  // ── Row management ───────────────────────────────────────────

  void _addRow() {
    setState(() {
      _rows.add(_BatchRow(rtkPointId: widget.defaultPoint.id));
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index);
    });
  }

  // ── Excel import ─────────────────────────────────────────────

  Future<void> _importExcel() async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = await pickFileBytes(['xlsx']);
    if (bytes == null || bytes.isEmpty) return;

    late final Excel xlsx;
    try {
      xlsx = Excel.decodeBytes(bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gpsQualityBatchEmpty)),
      );
      return;
    }
    final sheet = xlsx.tables[xlsx.tables.keys.first];
    if (sheet == null) return;

    final newRows = <_BatchRow>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      // skip header row (index 0)
      final sheetRow = sheet.rows[i];
      final deviceCode = _cellStr(sheetRow, 0)?.trim();
      if (deviceCode == null || deviceCode.isEmpty) continue;

      final row = _BatchRow();

      // Match device
      final deviceId = _deviceByCode[deviceCode];
      if (deviceId == null) {
        row.error = l10n.gpsQualityDeviceNotFound(deviceCode);
      } else {
        row.deviceId = deviceId;
      }

      // Match RTK point
      final pointLabel = _cellStr(sheetRow, 1)?.trim();
      if (pointLabel != null && pointLabel.isNotEmpty) {
        final pointId = _pointByLabel[pointLabel];
        if (pointId == null) {
          row.error = (row.error ?? '') + l10n.gpsQualityPointNotFound(pointLabel);
        } else {
          row.rtkPointId = pointId;
        }
      } else {
        row.rtkPointId = widget.defaultPoint.id;
      }

      // Parse optional times
      final startStr = _cellStr(sheetRow, 2)?.trim();
      if (startStr != null && startStr.isNotEmpty) {
        row.startedAt = _tryParseDateTime(startStr);
      }
      final endStr = _cellStr(sheetRow, 3)?.trim();
      if (endStr != null && endStr.isNotEmpty) {
        row.endedAt = _tryParseDateTime(endStr);
      }

      newRows.add(row);
    }

    if (newRows.isEmpty) return;
    setState(() {
      _rows.addAll(newRows);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.gpsQualityImportRows(newRows.length))),
    );
  }

  String? _cellStr(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final cell = row[index];
    if (cell == null || cell.value == null) return null;
    final v = cell.value!;
    // TextCellValue.value is excel's TextSpan, not a plain String
    if (v is TextCellValue) return v.value.toString();
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    if (v is DateCellValue || v is DateTimeCellValue) return v.toString();
    return v.toString();
  }

  DateTime? _tryParseDateTime(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      for (final fmt in [
        'yyyy-MM-dd HH:mm',
        'yyyy-MM-dd HH:mm:ss',
        'yyyy/MM/dd HH:mm',
        'MM/dd/yyyy HH:mm',
      ]) {
        try {
          return DateFormat(fmt).parse(s);
        } catch (_) {}
      }
      return null;
    }
  }

  // ── Template download ────────────────────────────────────────

  void _downloadTemplate() {
    final l10n = AppLocalizations.of(context)!;
    final xlsx = Excel.createExcel();
    final sheet = xlsx['Sheet1'];
    sheet.appendRow([
      TextCellValue(l10n.gpsQualityDevice),
      TextCellValue(l10n.gpsQualityPointLabel),
      TextCellValue(l10n.gpsQualityStartTime),
      TextCellValue(l10n.gpsQualityEndTime),
    ]);
    // Example row
    sheet.appendRow([
      TextCellValue(widget.devices.isNotEmpty
          ? widget.devices.first.deviceCode
          : '285fd'),
      TextCellValue(widget.points.isNotEmpty
          ? widget.points.first.pointLabel
          : '11号点'),
      TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
      TextCellValue(''),
    ]);
    final bytes = xlsx.encode();
    if (bytes != null) {
      downloadBytes('gps_quality_batch_template.xlsx', bytes);
    }
  }

  // ── Submit ───────────────────────────────────────────────────

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    // Clear previous errors
    for (final r in _rows) {
      r.error = null;
    }

    // Validate rows
    final validEntries = <MapEntry<int, BatchSessionRequest>>[];
    bool hasError = false;
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      if (row.rtkPointId == null) {
        row.error = l10n.gpsQualitySelectRtkPointShort;
        hasError = true;
        continue;
      }
      if (row.deviceId == null) {
        row.error = l10n.gpsQualitySelectDeviceShort;
        hasError = true;
        continue;
      }
      final startedAt = row.startedAt ?? _commonStartedAt;
      final endedAt = row.endedAt ?? _commonEndedAt;
      if (startedAt.isAfter(now)) {
        row.error = l10n.gpsQualityStartedAtFutureError;
        hasError = true;
        continue;
      }
      if (endedAt != null && endedAt.isAfter(now)) {
        row.error = l10n.gpsQualityEndedAtFutureError;
        hasError = true;
        continue;
      }
      validEntries.add(MapEntry(
          i,
          BatchSessionRequest(
            rtkPointId: row.rtkPointId!,
            deviceId: row.deviceId!,
            startedAt: startedAt,
            endedAt: endedAt,
          )));
    }

    if (hasError) {
      setState(() {});
      return;
    }
    if (validEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gpsQualityBatchEmpty)),
      );
      return;
    }

    // Submit sequentially
    setState(() {
      _saving = true;
      _progressDone = 0;
      _progressTotal = validEntries.length;
    });

    final repo = ref.read(gpsQualityApiRepositoryProvider);
    int succeeded = 0;
    int failed = 0;

    for (var i = 0; i < validEntries.length; i++) {
      setState(() => _progressDone = i);
      final entry = validEntries[i];
      try {
        await repo.createSession(
          rtkPointId: entry.value.rtkPointId,
          deviceId: entry.value.deviceId,
          startedAt: entry.value.startedAt,
          endedAt: entry.value.endedAt,
        );
        succeeded++;
      } catch (e) {
        _rows[entry.key].error = e.toString();
        failed++;
      }
    }
    setState(() => _progressDone = validEntries.length);

    // Invalidate affected providers
    final affectedPointIds = <int>{};
    for (final entry in validEntries) {
      affectedPointIds.add(entry.value.rtkPointId);
    }
    for (final pid in affectedPointIds) {
      ref.invalidate(calibrationSessionsProvider(pid));
      ref.invalidate(comparisonProvider(pid));
    }

    if (!mounted) return;

    if (failed == 0) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ ${l10n.gpsQualityBatchResult(0, succeeded)}')),
      );
    } else {
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '⚠️ ${l10n.gpsQualityBatchResult(failed, succeeded)}')),
      );
    }
  }
}

/// Compact date-time picker field for the common time section.
class _CompactTimeField extends StatelessWidget {
  const _CompactTimeField({
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
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: InkWell(
        onTap: () => _pick(context),
        child: Row(
          children: [
            const Icon(Icons.event, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
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
    onChanged(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}
