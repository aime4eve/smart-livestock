import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/web_file_utils.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// 3-step RTK trajectory import wizard (NIX-22).
/// Step 1: Upload .csv/.xlsx file (6-column format)
/// Step 2: Parse + pairing preview (tolerance adjustable, re-parses)
/// Step 3: Per-device import results
class TrajectoryImportDialog extends ConsumerStatefulWidget {
  const TrajectoryImportDialog({super.key, @visibleForTesting this.debugFileBytes});

  /// Test-only hook: pre-set the uploaded file bytes so the preview step can
  /// be driven without the platform file picker.
  @visibleForTesting
  final Uint8List? debugFileBytes;

  @override
  ConsumerState<TrajectoryImportDialog> createState() =>
      _TrajectoryImportDialogState();
}

class _TrajectoryImportDialogState extends ConsumerState<TrajectoryImportDialog> {
  int _step = 0;
  bool _loading = false;
  String? _fileName;
  Uint8List? _fileBytes;
  int _toleranceSec = 60;

  TrajectoryParseResult? _parseResult;
  TrajectoryImportResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.debugFileBytes != null) {
      _fileBytes = widget.debugFileBytes;
      _fileName = 'test-trajectory.csv';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      key: const Key('trajectory-import-dialog'),
      child: Container(
        width: 860,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Row(children: [
                Expanded(
                  child: Text(l10n.gpsQualityTrajectoryImport,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primarySoft,
        ),
        child: Column(children: [
          const Icon(Icons.satellite_alt, size: 48, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.gpsQualityTrajectoryUploadTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _fileName ?? l10n.gpsQualityTrajectoryUploadHint,
            key: const Key('trajectory-file-name'),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('trajectory-pick-file'),
            icon: const Icon(Icons.folder_open, size: 18),
            label: Text(l10n.commonConfirm),
            onPressed: _pickFile,
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      Center(
        child: OutlinedButton.icon(
          key: const Key('trajectory-download-template'),
          icon: const Icon(Icons.download, size: 16),
          label: Text(l10n.gpsQualityDownloadTemplate),
          onPressed: () async {
            try {
              await ref
                  .read(gpsQualityApiRepositoryProvider)
                  .downloadTrajectoryTemplate();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$e')));
              }
            }
          },
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      _buildFormatTable(l10n),
      const SizedBox(height: AppSpacing.sm),
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FB),
          borderRadius: BorderRadius.circular(8),
          border: const Border(left: BorderSide(color: Color(0xFF4A7F9D), width: 3)),
        ),
        child: Text(l10n.gpsQualityTrajectoryClockNote,
            style: const TextStyle(fontSize: 12, color: Color(0xFF33566B))),
      ),
    ]);
  }

  Widget _buildFormatTable(AppLocalizations l10n) {
    Widget row(String col, String field, bool required, String note) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 24, child: Text(col, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          SizedBox(width: 110, child: Text(field, style: const TextStyle(fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: required ? const Color(0xFFFEE2E2) : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              required ? l10n.gpsQualityTrajectoryRequired : l10n.gpsQualityTrajectoryOptional,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: required ? AppColors.danger : AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(note, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.gpsQualityTrajectoryFormatTitle,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      row('A', l10n.gpsQualityTrajectoryColEui, true, l10n.gpsQualityTrajectoryColEuiNote),
      row('B', l10n.gpsQualityTrajectoryColTime, true, l10n.gpsQualityTrajectoryColTimeNote),
      row('C', l10n.gpsQualityTrajectoryColRtkLat, true, ''),
      row('D', l10n.gpsQualityTrajectoryColRtkLng, true, ''),
      row('E', l10n.gpsQualityTrajectoryColDevLat, false, l10n.gpsQualityTrajectoryColDevNote),
      row('F', l10n.gpsQualityTrajectoryColDevLng, false, ''),
    ]);
  }

  Future<void> _pickFile() async {
    final picked = await pickFileBytesWithName(['csv', 'xlsx']);
    if (picked == null) return;
    setState(() {
      _fileBytes = Uint8List.fromList(picked.bytes);
      _fileName = picked.name;
    });
  }

  // ── Step 1: Preview ──────────────────────────────────────────────

  Widget _buildPreviewStep(AppLocalizations l10n) {
    if (_loading && _parseResult == null) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    final r = _parseResult;
    if (r == null) return const SizedBox();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Stats strip
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          _stat('${r.totalRows}', l10n.gpsQualityTrajectoryStatRows),
          _stat('${r.validRows}', l10n.gpsQualityTrajectoryStatValid, color: AppColors.success),
          _stat('${r.invalidRows}', l10n.gpsQualityTrajectoryStatInvalid,
              color: r.invalidRows > 0 ? AppColors.danger : null),
          _stat('${r.deviceCount}', l10n.gpsQualityTrajectoryStatDevices),
          _stat('${r.filePaired}', l10n.gpsQualityFilePaired, color: const Color(0xFF7C3AED)),
          _stat('${r.logPaired}', l10n.gpsQualityLogPaired, color: AppColors.warning),
          _stat('${r.unpaired}', l10n.gpsQualityUnpaired,
             color: r.unpaired > 0 ? AppColors.warning : null),
         if (r.autoRegisteredEuis.isNotEmpty)
           _stat('${r.autoRegisteredEuis.length}', l10n.gpsQualityTrajectoryAutoRegistered,
               color: const Color(0xFF0EA5E9)),
       ]),
      ),
      const SizedBox(height: AppSpacing.md),
      // Tolerance setting
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Text(l10n.gpsQualityPairTolerance,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: AppSpacing.md),
          Text('±', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 4),
          SizedBox(
            width: 70,
            child: TextField(
              key: const Key('trajectory-tolerance-input'),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              controller: TextEditingController(text: '$_toleranceSec'),
              onSubmitted: (v) {
                final parsed = int.tryParse(v.trim());
                if (parsed != null && parsed >= 1 && parsed <= 3600) {
                  setState(() => _toleranceSec = parsed);
                  _runParse();
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          Text(l10n.gpsQualityPairToleranceSec,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(l10n.gpsQualityPairToleranceNote,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
          if (_loading)
            const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      _buildRowsTable(l10n, r.rows),
    ]);
  }

  Widget _stat(String value, String label, {Color? color}) {
    return Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildRowsTable(AppLocalizations l10n, List<TrajectoryParseRow> rows) {
    final timeFmt = DateFormat('MM-dd HH:mm:ss');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('trajectory-preview-table'),
        headingRowHeight: 32,
        dataRowMinHeight: 30,
        dataRowMaxHeight: 36,
        columnSpacing: 16,
        columns: [
          DataColumn(label: Text('#', style: _th)),
          DataColumn(label: Text(l10n.gpsQualityTrajectoryColEui, style: _th)),
          DataColumn(label: Text(l10n.gpsQualityTrajectoryColTime, style: _th)),
          DataColumn(label: Text(l10n.gpsQualityTrajectoryColRtkLat, style: _th)),
          DataColumn(label: Text(l10n.gpsQualityTrajectoryColRtkLng, style: _th)),
          DataColumn(label: Text(l10n.gpsQualityTrajectoryColDevLat, style: _th)),
          DataColumn(label: Text(l10n.gpsQualityTrajectoryColDevLng, style: _th)),
          DataColumn(label: Text(l10n.gpsQualityTrajectoryMatchMode, style: _th)),
          DataColumn(label: Text(l10n.gpsQualityTrajectoryCheck, style: _th)),
        ],
        rows: rows.map((row) {
          final invalid = row.matchMode == 'INVALID';
          final mono = TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: invalid ? AppColors.danger : null,
          );
          return DataRow(cells: [
            DataCell(Text('${row.rowNo}', style: mono)),
            DataCell(Text(_shortEui(row.deviceEui), style: mono)),
            DataCell(Text(row.collectedAt != null ? timeFmt.format(row.collectedAt!) : '—', style: mono)),
            DataCell(Text(row.rtkLatitude?.toStringAsFixed(5) ?? '—', style: mono)),
            DataCell(Text(row.rtkLongitude?.toStringAsFixed(5) ?? '—', style: mono)),
            DataCell(Text(row.deviceLatitude?.toStringAsFixed(5) ?? '—', style: mono)),
            DataCell(Text(row.deviceLongitude?.toStringAsFixed(5) ?? '—', style: mono)),
            DataCell(_matchTag(l10n, row)),
            DataCell(invalid
                ? _invalidCell(l10n, row)
                : const Icon(Icons.check_circle, size: 14, color: AppColors.success)),
          ]);
        }).toList(),
      ),
    );
  }

  static const _th = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

  String _shortEui(String eui) =>
      eui.length > 8 ? '…${eui.substring(eui.length - 8)}' : eui;

  Widget _matchTag(AppLocalizations l10n, TrajectoryParseRow row) {
    final (label, color) = switch (row.matchMode) {
      'FILE' => (l10n.gpsQualityTrajectoryMatchFile, const Color(0xFF7C3AED)),
      'GPS_LOG' => (l10n.gpsQualityTrajectoryMatchLog, const Color(0xFF4A7F9D)),
      'UNPAIRED' => (l10n.gpsQualityTrajectoryMatchUnpaired, AppColors.warning),
      _ => (l10n.gpsQualityTrajectoryStatInvalid, AppColors.danger),
    };
    final suffix = row.matchMode == 'GPS_LOG' && row.timeDiffSec != null
        ? ' ±${row.timeDiffSec}s'
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text('$label$suffix',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ── Step 2: Result ───────────────────────────────────────────────

  Widget _buildResultStep(AppLocalizations l10n) {
    if (_loading && _result == null) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    final r = _result;
    if (r == null) return const SizedBox();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF7EF),
          borderRadius: BorderRadius.circular(8),
          border: const Border(left: BorderSide(color: AppColors.success, width: 3)),
        ),
        child: Text(
          l10n.gpsQualityTrajectoryImportDone(r.createdCount, r.skippedCount),
          key: const Key('trajectory-import-done'),
          style: const TextStyle(fontSize: 13, color: Color(0xFF2F5D3A)),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      ...r.devices.map((d) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Expanded(
                child: Text(d.deviceEui,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace',
                        fontWeight: FontWeight.w600)),
              ),
              Text(l10n.gpsQualityTrajectoryDevicePoints(d.totalPoints),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.md),
              _countChip(l10n.gpsQualityTrajectoryMatchFile, d.filePaired, const Color(0xFF7C3AED)),
              const SizedBox(width: 4),
              _countChip(l10n.gpsQualityTrajectoryMatchLog, d.logPaired, const Color(0xFF4A7F9D)),
              const SizedBox(width: 4),
              if (d.unpaired > 0) ...[
                _countChip(l10n.gpsQualityTrajectoryMatchUnpaired, d.unpaired, AppColors.warning),
                const SizedBox(width: 4),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: d.status == 'CREATED'
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  d.status == 'CREATED'
                      ? l10n.gpsQualityTrajectoryCreated
                      : l10n.gpsQualityTrajectorySkippedDuplicate,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: d.status == 'CREATED'
                          ? const Color(0xFF16A34A)
                          : AppColors.warning),
                ),
              ),
            ]),
          )),
      const SizedBox(height: AppSpacing.sm),
      Text(l10n.gpsQualityTrajectoryUnpairedNote,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }

  Widget _countChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text('$label $count',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────

  Widget _buildActions(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(children: [
        const Spacer(),
        if (_step < 2)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
        if (_step == 1) ...[
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: _loading ? null : () => setState(() => _step = 0),
            child: Text(l10n.commonBack),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        if (_step == 0)
          FilledButton(
            key: const Key('trajectory-next-btn'),
            onPressed: (_fileBytes == null || _loading) ? null : _runParse,
            child: Text(l10n.commonNext),
          ),
        if (_step == 1)
          FilledButton(
            key: const Key('trajectory-import-btn'),
            onPressed: (_parseResult == null || _parseResult!.validRows == 0 || _loading)
                ? null
                : _runImport,
            child: Text(l10n.gpsQualityTrajectoryImportAction),
          ),
        if (_step == 2)
          FilledButton(
            key: const Key('trajectory-done-btn'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonDone),
          ),
      ]),
    );
  }

  Future<void> _runParse() async {
    setState(() {
      _loading = true;
      _step = 1;
    });
    try {
      final result = await ref
          .read(gpsQualityApiRepositoryProvider)
          .parseTrajectory(_fileBytes!, _fileName!, _toleranceSec);
      if (mounted) setState(() => _parseResult = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runImport() async {
    setState(() {
      _loading = true;
      _step = 2;
    });
    try {
      final result = await ref
          .read(gpsQualityApiRepositoryProvider)
          .importTrajectory(_fileBytes!, _fileName!, _toleranceSec);
      if (mounted) setState(() => _result = result);
      ref.invalidate(checksProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _invalidCell(AppLocalizations l10n, TrajectoryParseRow row) {
    final isRegFailed = row.error != null && row.error!.contains('注册');
    if (!isRegFailed) {
      return Text(row.error ?? '',
          style: const TextStyle(fontSize: 11, color: AppColors.danger));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(row.error ?? '',
          style: const TextStyle(fontSize: 10, color: AppColors.danger)),
      const SizedBox(width: 4),
      InkWell(
        key: Key('manual-register-${row.rowNo}'),
        onTap: () => _showManualRegisterDialog(l10n, row.deviceEui),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(l10n.gpsQualityTrajectoryManualRegister,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
      ),
    ]);
  }

  void _showManualRegisterDialog(AppLocalizations l10n, String eui) {
    showDialog(
      context: context,
      builder: (ctx) {
        var deviceCode = '';
        return AlertDialog(
          title: Text(l10n.gpsQualityTrajectoryManualRegister),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${l10n.gpsQualityTrajectoryColEui}: $eui',
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('manual-register-device-code'),
              decoration: InputDecoration(
                labelText: l10n.gpsQualityTrajectoryColEuiNote,
                hintText: 'GPS-$eui',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => deviceCode = v,
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
            FilledButton(
              key: const Key('manual-register-confirm'),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(gpsQualityApiRepositoryProvider)
                      .registerTrajectoryDevice(eui, deviceCode.isEmpty ? null : deviceCode);
                  if (mounted) _runParse();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );
  }
}