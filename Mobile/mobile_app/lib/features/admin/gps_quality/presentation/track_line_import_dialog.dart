import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/web_file_utils.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// 3-step standard track line import wizard (NIX-68, spec §8.2).
/// Step 1: Upload RTK handset XLSX (single sheet「线路追踪」, 8 columns)
/// Step 2: Parse preview (raw/deduped points, computed length, first 8 pts)
/// Step 3: Import result (one new CANDIDATE candidate, append-only)
class TrackLineImportDialog extends ConsumerStatefulWidget {
  const TrackLineImportDialog({super.key, @visibleForTesting this.debugFileBytes});

  /// Test-only hook: pre-set the uploaded file bytes so the preview step can
  /// be driven without the platform file picker.
  @visibleForTesting
  final Uint8List? debugFileBytes;

  @override
  ConsumerState<TrackLineImportDialog> createState() =>
      _TrackLineImportDialogState();
}

class _TrackLineImportDialogState
    extends ConsumerState<TrackLineImportDialog> {
  int _step = 0;
  bool _loading = false;
  String? _fileName;
  Uint8List? _fileBytes;

  TrackLineParseResult? _parseResult;
  StandardTrackLine? _imported;
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.debugFileBytes != null) {
      _fileBytes = widget.debugFileBytes;
      _fileName = 'test-track-line.xlsx';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      key: const Key('track-line-import-dialog'),
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
                  child: Text(l10n.gpsQualityLineImport,
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
      Container(
          width: 20,
          height: 1,
          color: _step >= 1 ? AppColors.primary : AppColors.border),
      _stepDot(1, l10n.gpsQualityImportStepPreview),
      const SizedBox(width: 4),
      Container(
          width: 20,
          height: 1,
          color: _step >= 2 ? AppColors.primary : AppColors.border),
      _stepDot(2, l10n.gpsQualityImportStepResult),
    ]);
  }

  Widget _stepDot(int idx, String label) {
    final active = idx <= _step;
    final filled = idx < _step;
    return Tooltip(
      message: label,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? AppColors.primary
              : (active ? Colors.white : AppColors.surface),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border, width: 2),
        ),
        alignment: Alignment.center,
        child: filled
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : Text('${idx + 1}',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color:
                        active ? AppColors.primary : AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildStepContent(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return _buildUploadStep(l10n);
      case 1:
        return _buildPreviewStep(l10n);
      case 2:
        return _buildResultStep(l10n);
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Upload ───────────────────────────────────────────────

  Widget _buildUploadStep(AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.lineTeal.withValues(alpha: 0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.lineTeal.withValues(alpha: 0.05),
        ),
        child: Column(children: [
          const Icon(Icons.route, size: 48, color: AppColors.lineTeal),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.gpsQualityLineUploadTitle,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _fileName ?? l10n.gpsQualityLineUploadHint,
            key: const Key('track-line-file-name'),
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('track-line-pick-file'),
            icon: const Icon(Icons.folder_open, size: 18),
            label: Text(l10n.gpsQualityLinePickFile),
            onPressed: _pickFile,
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.gpsQualityLineFormatTitle,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      _buildFormatTable(l10n),
      const SizedBox(height: AppSpacing.md),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.lineTeal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        // Left accent bar via stretched container: a non-uniform Border is
        // not allowed together with borderRadius (paint-time assertion).
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 3, color: AppColors.lineTeal),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(l10n.gpsQualityLineCleanRules,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildFormatTable(AppLocalizations l10n) {
    Widget row(String col, String field, String usage, Color usageColor,
        String note) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 24,
              child: Text(col,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
          SizedBox(
              width: 110,
              child: Text(field, style: const TextStyle(fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: usageColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(usage,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: usageColor)),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(note,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary))),
        ]),
      );
    }

    final used = l10n.gpsQualityLineColUsed;
    final ignored = l10n.gpsQualityLineColIgnored;
    final untrusted = l10n.gpsQualityLineColUntrusted;
    return Column(children: [
      row('A', l10n.gpsQualityLineColName, used, AppColors.primary,
          l10n.gpsQualityLineColNameNote),
      row('B', l10n.gpsQualityLineColCategory, ignored,
          AppColors.textSecondary, ''),
      row('C', l10n.gpsQualityLineColStartTime, untrusted, AppColors.warning,
          l10n.gpsQualityLineColTimeNote),
      row('D', l10n.gpsQualityLineColEndTime, untrusted, AppColors.warning,
          l10n.gpsQualityLineColTimeNote),
      row('E', l10n.gpsQualityLineColLength, untrusted, AppColors.warning,
          l10n.gpsQualityLineColLengthNote),
      row('F', l10n.gpsQualityLineColRemark, ignored,
          AppColors.textSecondary, ''),
      row('G', l10n.gpsQualityLineColLineType, ignored,
          AppColors.textSecondary, ''),
      row('H', l10n.gpsQualityLineColCoords, used, AppColors.primary,
          l10n.gpsQualityLineColCoordsNote),
    ]);
  }

  Future<void> _pickFile() async {
    final picked = await pickFileBytesWithName(['xlsx']);
    if (picked == null) return;
    setState(() {
      _fileBytes = Uint8List.fromList(picked.bytes);
      _fileName = picked.name;
    });
  }

  // ── Step 1: Preview ──────────────────────────────────────────────

  Widget _buildPreviewStep(AppLocalizations l10n) {
    if (_loading && _parseResult == null) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
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
          _stat('${r.rawPointCount}', l10n.gpsQualityLineStatRaw),
          _stat('${r.pointCount}', l10n.gpsQualityLineStatDedup,
              color: AppColors.success),
          _stat('${r.removedDuplicates}', l10n.gpsQualityLineStatRemoved,
              color: r.removedDuplicates > 0 ? AppColors.warning : null),
          _stat('${r.lengthMeters.toStringAsFixed(0)} m',
              l10n.gpsQualityLineStatLength,
              color: AppColors.lineTeal),
          _stat(
              '${r.startLng?.toStringAsFixed(5) ?? '-'}, ${r.startLat?.toStringAsFixed(5) ?? '-'}',
              l10n.gpsQualityLineStatStart,
              small: true),
          _stat(
              '${r.endLng?.toStringAsFixed(5) ?? '-'}, ${r.endLat?.toStringAsFixed(5) ?? '-'}',
              l10n.gpsQualityLineStatEnd,
              small: true),
        ]),
      ),
      if (r.invalidPoints > 0 || r.metadataWarning != null) ...[
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF6EA),
            borderRadius: BorderRadius.circular(8),
          ),
          // Left accent bar via stretched container: a non-uniform Border is
          // not allowed together with borderRadius (paint-time assertion).
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(width: 3, color: AppColors.warning),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      [
                        if (r.metadataWarning != null) r.metadataWarning!,
                        if (r.invalidPoints > 0)
                          l10n.gpsQualityLineInvalidPoints(r.invalidPoints),
                      ].join('\n'),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7A5416)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      Text(l10n.gpsQualityLinePreviewPoints,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          key: const Key('track-line-preview-table'),
          headingRowHeight: 32,
          dataRowMinHeight: 30,
          dataRowMaxHeight: 36,
          columnSpacing: 24,
          columns: [
            DataColumn(label: Text(l10n.gpsQualityLineColSeq, style: _th)),
            DataColumn(label: Text(l10n.gpsQualityLongitude, style: _th)),
            DataColumn(label: Text(l10n.gpsQualityLatitude, style: _th)),
          ],
          rows: r.previewPoints.map((p) {
            const mono = TextStyle(fontSize: 11, fontFamily: 'monospace');
            return DataRow(cells: [
              DataCell(Text('${p.sequenceNo}', style: mono)),
              DataCell(Text(p.lng.toStringAsFixed(8), style: mono)),
              DataCell(Text(p.lat.toStringAsFixed(8), style: mono)),
            ]);
          }).toList(),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      // Naming row (default from the file「名称」column)
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Text(l10n.gpsQualityLineNameLabel,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 260,
            child: TextField(
              key: const Key('track-line-name-input'),
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(l10n.gpsQualityLineNameHint,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ),
        ]),
      ),
    ]);
  }

  static const _th = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

  Widget _stat(String value, String label, {Color? color, bool small = false}) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: small ? 12 : 20,
                fontWeight: FontWeight.w700,
                fontFamily: small ? 'monospace' : null,
                color: color),
            textAlign: TextAlign.center),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Step 2: Result ───────────────────────────────────────────────

  Widget _buildResultStep(AppLocalizations l10n) {
    if (_loading && _imported == null) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }
    final r = _imported;
    if (r == null) return const SizedBox();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF7EF),
          borderRadius: BorderRadius.circular(8),
        ),
        // Left accent bar via stretched container: a non-uniform Border is
        // not allowed together with borderRadius (paint-time assertion).
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 3, color: AppColors.success),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.gpsQualityLineImportDone(
                        r.pointCount, r.lengthM.toStringAsFixed(0)),
                    key: const Key('track-line-import-done'),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2F5D3A)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Expanded(
            child: Text(r.name,
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600)),
          ),
          Text(
            l10n.gpsQualityTrackLinePointLength(
                r.pointCount, r.lengthM.toStringAsFixed(0)),
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(l10n.gpsQualityTrackLineCandidate,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569))),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.lineTeal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        // Left accent bar via stretched container: a non-uniform Border is
        // not allowed together with borderRadius (paint-time assertion).
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 3, color: AppColors.lineTeal),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(l10n.gpsQualityLineAppendNote,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
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
            key: const Key('track-line-next-btn'),
            onPressed: (_fileBytes == null || _loading) ? null : _runParse,
            child: Text(l10n.commonNext),
          ),
        if (_step == 1)
          FilledButton(
            key: const Key('track-line-import-btn'),
            onPressed:
                (_parseResult == null || _parseResult!.pointCount < 2 || _loading)
                    ? null
                    : _runImport,
            child: Text(l10n.gpsQualityLineImportAction),
          ),
        if (_step == 2)
          FilledButton(
            key: const Key('track-line-done-btn'),
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
          .parseTrackLine(_fileBytes!, _fileName!);
      if (mounted) {
        setState(() {
          _parseResult = result;
          _nameCtrl.text = result.defaultName;
        });
      }
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
          .importTrackLine(_fileBytes!, _fileName!,
              name: _nameCtrl.text.trim());
      if (mounted) setState(() => _imported = result);
      ref.invalidate(trackLinesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
