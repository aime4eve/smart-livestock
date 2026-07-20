import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/web_file_utils.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/edit_retry_dialog.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// 3-step batch GPS quality check import wizard.
/// Step 1: Upload .xlsx file
/// Step 2: Preview parsed rows
/// Step 3: Results with actions for pending/failed items
class BatchImportDialog extends ConsumerStatefulWidget {
  const BatchImportDialog({super.key, @visibleForTesting this.debugFileBytes});

  /// Test-only hook: pre-set the uploaded file bytes so the preview step can
  /// be driven without the platform file picker.
  @visibleForTesting
  final Uint8List? debugFileBytes;

  @override
  ConsumerState<BatchImportDialog> createState() => _BatchImportDialogState();
}

class _BatchImportDialogState extends ConsumerState<BatchImportDialog> {
  int _step = 0;
  bool _loading = false;
  String? _fileName;
  Uint8List? _fileBytes;

  // Preview data (parsed server-side via POST /batch/parse)
  BatchParseResult? _parseResult;
  final Set<int> _excludedRows = {};

  // Result data (after submit)
  BatchImportResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.debugFileBytes != null) {
      _fileBytes = widget.debugFileBytes;
      _fileName = 'test-import.xlsx';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      key: const Key('batch-import-dialog'),
      child: Container(
        width: 720,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Row(children: [
                Expanded(child: Text(l10n.gpsQualityBatchImport, style: Theme.of(context).textTheme.titleMedium)),
                // Step indicator
                _stepIndicator(l10n),
              ]),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildStepContent(l10n),
              ),
            ),
            const Divider(height: 1),
            _buildActions(l10n),
          ],
        ),
      ),
    );
  }

  Widget _stepIndicator(AppLocalizations l10n) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _stepDot(0, l10n.gpsQualityImportStepUpload),
      const SizedBox(width: 4),
      Container(width: 20, height: 1, color: _step >= 1 ? AppColors.primary : AppColors.border),
      _stepDot(1, l10n.gpsQualityImportStepPreview),
      const SizedBox(width: 4),
      Container(width: 20, height: 1, color: _step >= 2 ? AppColors.primary : AppColors.border),
      _stepDot(2, l10n.gpsQualityImportStepResult),
    ]);
  }

  Widget _stepDot(int idx, String label) {
    final active = idx <= _step;
    final filled = idx < _step;
    return Tooltip(
      message: label,
      child: Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.primary : (active ? Colors.white : AppColors.surface),
          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 2),
        ),
        alignment: Alignment.center,
        child: filled
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : Text('${idx + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: active ? AppColors.primary : AppColors.textSecondary)),
      ),
    );
  }

  // ── Step content ─────────────────────────────────────────────────

  Widget _buildStepContent(AppLocalizations l10n) {
    switch (_step) {
      case 0: return _buildUploadStep(l10n);
      case 1: return _buildPreviewStep(l10n);
      case 2: return _buildResultStep(l10n);
      default: return const SizedBox();
    }
  }

  // ── Step 0: Upload ───────────────────────────────────────────────

  Widget _buildUploadStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag-drop / upload area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2, strokeAlign: BorderSide.strokeAlignInside),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.primarySoft,
          ),
          child: Column(children: [
            const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.gpsQualityUploadExcel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            _fileName != null
                ? Text(_fileName!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                : Text('.xlsx', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const Key('batch-import-pick-file'),
              icon: const Icon(Icons.folder_open, size: 18),
              label: Text(l10n.commonConfirm),
              onPressed: _pickFile,
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        // Template download
        Center(
          child: OutlinedButton.icon(
            key: const Key('batch-import-download-template'),
            icon: const Icon(Icons.download, size: 16),
            label: Text(l10n.gpsQualityDownloadTemplate),
            onPressed: () async {
              try {
                await ref.read(gpsQualityApiRepositoryProvider).downloadBatchTemplate();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final bytes = await pickFileBytes(['xlsx']);
    if (bytes == null || bytes.isEmpty) return;
    setState(() {
      _fileBytes = Uint8List.fromList(bytes);
      _fileName = 'gps-quality-import.xlsx';
    });
  }

  // ── Step 1: Preview ──────────────────────────────────────────────

  Widget _buildPreviewStep(AppLocalizations l10n) {
    final result = _parseResult;
    if (result == null) {
      return Center(child: Text(l10n.gpsQualityNoData));
    }
    // ERROR rows are auto-excluded and cannot be restored; manually excluded
    // rows are removed from the table entirely.
    final visibleRows = result.rows
        .where((r) =>
            r.preStatus == 'ERROR' || !_excludedRows.contains(r.rowIndex))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Row(children: [
          _summaryCard(l10n.gpsQualityImportTotalRows, '${result.totalRows}', AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          _summaryCard(l10n.gpsQualityImportOkRows, '${result.okCount}', AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          _summaryCard(l10n.gpsQualityDevicePending, '${result.warnCount}', AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          _summaryCard(l10n.gpsQualityImportFailed, '${result.errorCount}', AppColors.danger),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.gpsQualityDeleteRowsHint,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        // Table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            key: const Key('preview-table'),
            columnSpacing: 12,
            columns: [
              DataColumn(label: Text(l10n.gpsQualityRowIndex, style: const TextStyle(fontSize: 11))),
              DataColumn(label: Text(l10n.gpsQualityDeviceEui, style: const TextStyle(fontSize: 11))),
              DataColumn(label: Text(l10n.gpsQualityDeviceCode, style: const TextStyle(fontSize: 11))),
              DataColumn(label: Text(l10n.gpsQualityTestType, style: const TextStyle(fontSize: 11))),
              DataColumn(label: Text(l10n.gpsQualityTruthRef, style: const TextStyle(fontSize: 11))),
              DataColumn(label: Text(l10n.gpsQualityTimeRange, style: const TextStyle(fontSize: 11))),
              DataColumn(label: Text(l10n.gpsQualityStatus, style: const TextStyle(fontSize: 11))),
              DataColumn(label: Text('', style: const TextStyle(fontSize: 11))),
            ],
            rows: visibleRows.map((r) {
              final isError = r.preStatus == 'ERROR';
              final timeRange = r.startedAt != null
                  ? '${DateFormat('MM-dd HH:mm').format(r.startedAt!)} → ${r.endedAt != null ? DateFormat('MM-dd HH:mm').format(r.endedAt!) : '...'}'
                  : '-';
              return DataRow(
                color: isError ? WidgetStateProperty.all(AppColors.danger.withValues(alpha: 0.04)) : null,
                cells: [
                  DataCell(Text('${r.rowIndex}', style: const TextStyle(fontSize: 12))),
                  DataCell(Text(r.eui, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isError ? AppColors.danger : AppColors.textPrimary))),
                  DataCell(Text(r.deviceCode ?? '-', style: const TextStyle(fontSize: 12))),
                  DataCell(_typeTag(r.testType, l10n)),
                  DataCell(Text(r.refName.isEmpty ? '-' : r.refName, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(timeRange, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                  DataCell(_preStatusTag(r, l10n)),
                  DataCell(isError
                    ? Text(l10n.gpsQualityRowExcluded,
                        key: Key('preview-excluded-${r.rowIndex}'),
                        style: const TextStyle(fontSize: 10, color: AppColors.danger))
                    : IconButton(
                        key: Key('preview-remove-row-${r.rowIndex}'),
                        icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                        visualDensity: VisualDensity.compact,
                        tooltip: l10n.commonDelete,
                        onPressed: () => setState(() => _excludedRows.add(r.rowIndex)),
                      )),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _typeTag(String testType, AppLocalizations l10n) {
    final isStatic = testType == 'STATIC';
    final color = isStatic ? const Color(0xFF2563EB) : const Color(0xFFB45309);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        isStatic ? l10n.gpsQualityTestTypeStatic : l10n.gpsQualityTestTypeDynamic,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }

  Widget _preStatusTag(BatchParseRow row, AppLocalizations l10n) {
    final (label, color) = switch (row.preStatus) {
      'OK' => (l10n.gpsQualityImportOkRows, AppColors.success),
      'WARN' => (l10n.gpsQualityDevicePending, AppColors.warning),
      _ => (l10n.gpsQualityImportFailed, AppColors.danger),
    };
    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
    if (row.message != null && row.message!.isNotEmpty) {
      return Tooltip(message: row.message!, child: tag);
    }
    return tag;
  }

  // ── Step 2: Results ──────────────────────────────────────────────

  Widget _buildResultStep(AppLocalizations l10n) {
    if (_result == null) return const Center(child: Text('No result'));
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Row(children: [
          _summaryCard(l10n.gpsQualityImportResult, '${r.totalRows}', AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          _summaryCard(l10n.gpsQualityRegisterSuccess, '${r.totalSuccess}', AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          _summaryCard(l10n.gpsQualityDevicePending, '${r.totalPending}', AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          _summaryCard(l10n.gpsQualityImportFailed, '${r.totalFailed}', AppColors.danger),
        ]),
        const SizedBox(height: AppSpacing.md),
        if (r.rows.isNotEmpty) ...[
          const Text('详情', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              columns: [
                DataColumn(label: Text(l10n.gpsQualityRowIndex, style: const TextStyle(fontSize: 11))),
                DataColumn(label: Text(l10n.gpsQualityDeviceEui, style: const TextStyle(fontSize: 11))),
                DataColumn(label: Text(l10n.gpsQualityStatus, style: const TextStyle(fontSize: 11))),
                DataColumn(label: Text(l10n.commonMessage, style: const TextStyle(fontSize: 11))),
                DataColumn(label: Text(l10n.commonAction, style: const TextStyle(fontSize: 11))),
              ],
              rows: r.rows.map((row) {
                final isPending = row.status == 'DEVICE_PENDING';
                final isFailed = row.status == 'FAILED';
                return DataRow(cells: [
                  DataCell(Text('${row.rowIndex}', style: const TextStyle(fontSize: 12))),
                  DataCell(Text(row.eui, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  DataCell(_statusTag(row.status, l10n)),
                  DataCell(Text(row.message ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isPending)
                      TextButton.icon(
                        key: Key('batch-row-register-${row.rowIndex}'),
                        icon: const Icon(Icons.wifi_tethering, size: 14),
                        label: Text(l10n.gpsQualityManualRegister, style: const TextStyle(fontSize: 11)),
                        onPressed: () => _retrySingle(row),
                      ),
                    if (isFailed)
                      TextButton.icon(
                        key: Key('batch-row-edit-retry-${row.rowIndex}'),
                        icon: const Icon(Icons.edit, size: 14),
                        label: Text(l10n.gpsQualityEditAndRetry, style: const TextStyle(fontSize: 11)),
                        onPressed: () => _editRetry(row),
                      ),
                  ])),
                ]);
              }).toList(),
            ),
          ),
          // Pending group action
          if (r.totalPending > 0) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: const Key('batch-register-all-btn'),
              icon: const Icon(Icons.wifi_tethering, size: 16),
              label: Text(l10n.gpsQualityRegisterAll),
              onPressed: _loading ? null : () => _retryAllPending(r),
            ),
          ],
        ],
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _statusTag(String status, AppLocalizations l10n) {
    final (label, color) = switch (status) {
      'READY' => (l10n.gpsQualityCheckStatusReady, AppColors.success),
      'DEVICE_PENDING' => (l10n.gpsQualityCheckStatusPending, AppColors.warning),
      'FAILED' => (l10n.gpsQualityCheckStatusFailed, AppColors.danger),
      _ => (status, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ── Actions row ──────────────────────────────────────────────────

  Widget _buildActions(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(children: [
        if (_step == 2 && _result?.batchId != null)
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
            label: Text(l10n.commonDelete, style: const TextStyle(color: AppColors.danger)),
            onPressed: () => _deleteBatch(l10n),
          ),
        const Spacer(),
        if (_step > 0)
          TextButton(
            onPressed: _loading ? null : () => setState(() => _step--),
            child: Text(l10n.commonBack),
          ),
       const SizedBox(width: AppSpacing.sm),
       // Step-specific primary action
       if (_step == 0)
         FilledButton.icon(
           key: const Key('batch-import-preview-btn'),
           onPressed: (_fileBytes == null) ? null : _parsePreview,
           icon: const Icon(Icons.visibility_outlined, size: 18),
           label: Text(l10n.gpsQualityImportStepPreview),
         ),
       if (_step == 1)
         FilledButton.icon(
           key: const Key('batch-import-submit-btn'),
           onPressed: _loading ? null : _submit,
           icon: _loading
               ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
               : const Icon(Icons.upload_file, size: 18),
           label: Text(l10n.gpsQualityBatchImport),
         ),
       if (_step == 2)
         FilledButton.icon(
           onPressed: () => Navigator.pop(context),
           icon: const Icon(Icons.check, size: 18),
           label: Text(l10n.commonClose),
         ),
     ]),
   );
  }

  // ── Business logic ───────────────────────────────────────────────

  /// Parse the uploaded file server-side (parse-only) into preview rows.
  Future<void> _parsePreview() async {
    if (_fileBytes == null) return;
    setState(() => _loading = true);
    try {
      final result = await ref.read(gpsQualityApiRepositoryProvider).parseBatch(
        _fileBytes!.toList(),
        _fileName ?? 'import.xlsx',
      );
      if (!mounted) return;
      setState(() {
        _parseResult = result;
        // ERROR rows are auto-excluded and cannot be restored
        _excludedRows
          ..clear()
          ..addAll(result.rows
              .where((r) => r.preStatus == 'ERROR')
              .map((r) => r.rowIndex));
        _step = 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_fileBytes == null) return;
    setState(() => _loading = true);
    try {
      final excludeRows = _excludedRows.toList()..sort();
      final result = await ref.read(gpsQualityApiRepositoryProvider).batchImport(
        _fileBytes!.toList(),
        _fileName ?? 'import.xlsx',
        excludeRows: excludeRows,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _step = 2;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Batch register blade for ALL pending checks.
  Future<void> _retryAllPending(BatchImportResult r) async {
    setState(() => _loading = true);
    try {
      await ref.read(gpsQualityApiRepositoryProvider).retryRegistration();
      if (!mounted) return;
      ref.invalidate(checksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n().gpsQualityRegisterSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  AppLocalizations l10n() => AppLocalizations.of(context)!;

  /// Manual register blade for a single pending row's check.
  Future<void> _retrySingle(RowResult row) async {
    setState(() => _loading = true);
    try {
      await ref.read(gpsQualityApiRepositoryProvider).retryRegistration(
        checkIds: row.checkId != null ? [row.checkId!] : null,
      );
      if (!mounted) return;
      ref.invalidate(checksProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n().gpsQualityRegisterSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _editRetry(RowResult row) async {
    await showDialog(
      context: context,
      builder: (_) => EditRetryDialog(rowResult: row),
    );
  }

  Future<void> _deleteBatch(AppLocalizations l10n) async {
    if (_result?.batchId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text(l10n.gpsQualityBatchConfirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(gpsQualityApiRepositoryProvider).deleteBatch(_result!.batchId!);
      if (!mounted) return;
      ref.invalidate(checksProvider);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
