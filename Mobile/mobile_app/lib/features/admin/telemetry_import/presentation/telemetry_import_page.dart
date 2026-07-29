import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/web_file_utils.dart';
import 'package:hkt_livestock_agentic/features/admin/telemetry_import/domain/telemetry_import_models.dart';
import 'package:hkt_livestock_agentic/features/admin/telemetry_import/presentation/telemetry_import_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Telemetry file import page (NIX-79, spec §5.3).
/// Page-embedded 3-step flow: upload xlsx -> parse preview -> import result.
class TelemetryImportPage extends ConsumerStatefulWidget {
  const TelemetryImportPage({super.key, @visibleForTesting this.debugFileBytes});

  /// Test-only hook: pre-set the uploaded file bytes so the flow can be
  /// driven without the platform file picker.
  @visibleForTesting
  final Uint8List? debugFileBytes;

  @override
  ConsumerState<TelemetryImportPage> createState() =>
      _TelemetryImportPageState();
}

class _TelemetryImportPageState extends ConsumerState<TelemetryImportPage> {
  bool _uploadHover = false;

  @override
  void initState() {
    super.initState();
    final debugBytes = widget.debugFileBytes;
    if (debugBytes != null) {
      // Defer past the first frame: provider state must not change mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(telemetryImportControllerProvider.notifier)
            .selectFile('test-telemetry-import.xlsx', debugBytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = ref.watch(telemetryImportControllerProvider).value ??
        const TelemetryImportState();
    return Scaffold(
      key: const Key('telemetry-import-page'),
      appBar: AppBar(title: Text(l10n.telemetryImportTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(l10n, s.step),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: switch (s.step) {
                    1 => _buildPreviewStep(l10n, s),
                    2 => _buildResultStep(l10n, s),
                    _ => _buildUploadStep(l10n, s),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step indicator ───────────────────────────────────────────────

  Widget _buildStepIndicator(AppLocalizations l10n, int step) {
    return Row(children: [
      _stepItem(0, l10n.telemetryImportStepUpload, step),
      _stepLine(step >= 1),
      _stepItem(1, l10n.telemetryImportStepPreview, step),
      _stepLine(step >= 2),
      _stepItem(2, l10n.telemetryImportStepResult, step),
    ]);
  }

  Widget _stepItem(int idx, String label, int step) {
    final done = idx < step;
    final active = idx == step;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? AppColors.primary : AppColors.surfaceAlt,
          border: Border.all(
            color: (active || done) ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: done
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : Text('${idx + 1}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColors.primary
                        : AppColors.textSecondary)),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color:
                  active ? AppColors.primary : AppColors.textSecondary)),
    ]);
  }

  Widget _stepLine(bool done) => Container(
        width: 32,
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        color: done ? AppColors.primary : AppColors.border,
      );

  // ── Step 0: Upload ───────────────────────────────────────────────

  Widget _buildUploadStep(AppLocalizations l10n, TelemetryImportState s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _uploadHover = true),
        onExit: (_) => setState(() => _uploadHover = false),
        child: GestureDetector(
          key: const Key('telemetry-import-upload-zone'),
          onTap: s.busy ? null : _pickFile,
          child: CustomPaint(
            painter: _DashedRRectPainter(
                color:
                    _uploadHover ? AppColors.primary : AppColors.border),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: 36),
              decoration: BoxDecoration(
                color: _uploadHover
                    ? AppColors.primarySoft
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                const Text('🛰️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.telemetryImportUploadTitle,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(l10n.telemetryImportUploadHint,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                if (s.fileName != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(s.fileName!,
                      key: const Key('telemetry-import-file-name'),
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ],
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  key: const Key('telemetry-import-pick-file'),
                  onPressed: s.busy ? null : _pickFile,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: Text(s.fileName == null
                      ? l10n.telemetryImportPickFile
                      : l10n.telemetryImportRePickFile),
                ),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.telemetryImportFormatTitle,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      _buildFormatTable(l10n),
      const SizedBox(height: AppSpacing.lg),
      _noteBar(
          bg: const Color(0xFFEFF6FB),
          bar: AppColors.info,
          fg: const Color(0xFF33566B),
          text: l10n.telemetryImportDecodeNote),
      const SizedBox(height: AppSpacing.md),
      _noteBar(
          bg: const Color(0xFFFFFBEB),
          bar: AppColors.warning,
          fg: const Color(0xFF7A5A18),
          text: l10n.telemetryImportRulesNote),
      const SizedBox(height: AppSpacing.xl),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FilledButton(
          key: const Key('telemetry-import-next-btn'),
          onPressed: (s.fileBytes == null || s.busy) ? null : _runParse,
          child: Text(l10n.telemetryImportNextParse),
        ),
      ]),
    ]);
  }

  Future<void> _pickFile() async {
    final picked = await pickFileBytesWithName(['xlsx']);
    if (picked == null) return;
    ref
        .read(telemetryImportControllerProvider.notifier)
        .selectFile(picked.name, Uint8List.fromList(picked.bytes));
  }

  Widget _buildFormatTable(AppLocalizations l10n) {
    Widget row(String col, String name, bool required, String note) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 20,
              child: Text(col,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
          SizedBox(
              width: 90,
              child: Text(name, style: const TextStyle(fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: required
                  ? const Color(0xFFFEE2E2)
                  : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
                required
                    ? l10n.telemetryImportRequired
                    : l10n.telemetryImportOptional,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color:
                        required ? AppColors.danger : AppColors.primary)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(note,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary))),
        ]),
      );
    }

    return Column(children: [
      row('A', l10n.telemetryImportColDataType, true,
          l10n.telemetryImportColDataTypeNote),
      row('B', l10n.telemetryImportColFrameCounter, false,
          l10n.telemetryImportColFrameCounterNote),
      row('C', l10n.telemetryImportColData, true,
          l10n.telemetryImportColDataNote),
      row('D', l10n.telemetryImportColRssi, false,
          l10n.telemetryImportColRssiNote),
      row('E', l10n.telemetryImportColSnr, false,
          l10n.telemetryImportColSnrNote),
      row('F', l10n.telemetryImportColCreateTime, true,
          l10n.telemetryImportColCreateTimeNote),
    ]);
  }

  Widget _noteBar(
      {required Color bg,
      required Color bar,
      required Color fg,
      required String text}) {
    // Left accent bar is a stretched widget (not a BorderSide) because
    // BorderRadius cannot be painted with a non-uniform Border.
    return Container(
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 3, color: bar),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child:
                    Text(text, style: TextStyle(fontSize: 12, color: fg, height: 1.8)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Step 1: Parse preview ────────────────────────────────────────

  Widget _buildPreviewStep(AppLocalizations l10n, TelemetryImportState s) {
    if (s.busy && s.parseResult == null) {
      return const SizedBox(
          height: 240, child: Center(child: CircularProgressIndicator()));
    }
    final r = s.parseResult;
    if (r == null) return const SizedBox();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildStats(l10n, r),
      const SizedBox(height: AppSpacing.lg),
      _buildDeviceCard(l10n, r.device),
      const SizedBox(height: AppSpacing.xl),
      Text(l10n.telemetryImportPreviewTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.sm),
      _buildPreviewTable(l10n, r),
      if (r.rows.length > 8) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.telemetryImportPreviewNote(r.totalRows),
            key: const Key('telemetry-import-preview-note'),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
      const SizedBox(height: AppSpacing.xl),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        OutlinedButton(
          key: const Key('telemetry-import-back-btn'),
          onPressed: s.busy
              ? null
              : () => ref
                  .read(telemetryImportControllerProvider.notifier)
                  .backToUpload(),
          child: Text(l10n.commonBack),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton(
          key: const Key('telemetry-import-import-btn'),
          onPressed:
              (!r.device.matched || s.busy) ? null : _runImport,
          child: Text(r.device.matched
              ? l10n.telemetryImportConfirmAction(r.importableRows)
              : l10n.telemetryImportConfirmDisabled),
        ),
      ]),
    ]);
  }

  Widget _buildStats(AppLocalizations l10n, TelemetryParseResult r) {
    return Container(
      key: const Key('telemetry-import-stats'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        _stat('total', '${r.totalRows}', l10n.telemetryImportStatTotal),
        _stat('uplink', '${r.uplinkRows}', l10n.telemetryImportStatUplink,
            color: AppColors.info),
        _stat('decodable', '${r.decodableRows}',
            l10n.telemetryImportStatDecodable),
        _stat('importable', '${r.importableRows}',
            l10n.telemetryImportStatImportable,
            color: AppColors.success),
        _stat('duplicate', '${r.duplicateRows}',
            l10n.telemetryImportStatDuplicate,
            color: AppColors.warning),
        _stat('skipped', '${r.skippedRows}',
            l10n.telemetryImportStatSkipped),
      ]),
    );
  }

  Widget _stat(String name, String value, String label, {Color? color}) {
    return Expanded(
      key: Key('telemetry-import-stat-$name'),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: color),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildDeviceCard(AppLocalizations l10n, TelemetryDeviceMatch d) {
    final matched = d.matched;
    // Left accent bar is a stretched widget (not a BorderSide) because
    // BorderRadius cannot be painted with a non-uniform Border.
    return Container(
      key: const Key('telemetry-import-device-card'),
      decoration: BoxDecoration(
        color: matched ? AppColors.surfaceAlt : const Color(0xFFFEF6F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
                width: 4,
                color: matched ? AppColors.success : AppColors.danger),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(children: [
                  Text(matched ? '🐄' : '⚠️',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                                child: Text(d.devEui,
                                    style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13))),
                            const SizedBox(width: AppSpacing.sm),
                            _deviceTag(l10n, matched),
                          ]),
                          const SizedBox(height: 4),
                          if (matched)
                            _matchedMeta(l10n, d)
                          else
                            Text(_unmatchedReason(l10n, d),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.7)),
                        ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _deviceTag(AppLocalizations l10n, bool matched) {
    return Container(
      key: const Key('telemetry-import-device-tag'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:
            matched ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
          matched
              ? l10n.telemetryImportDeviceMatched
              : l10n.telemetryImportDeviceNotMatched,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: matched
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626))),
    );
  }

  Widget _matchedMeta(AppLocalizations l10n, TelemetryDeviceMatch d) {
    final spans = <InlineSpan>[];
    void add(String label, String value) {
      if (value.isEmpty) return;
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(TextSpan(text: '$label '));
      spans.add(TextSpan(
          text: value,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)));
    }

    add(l10n.telemetryImportMetaCode, d.deviceCode);
    add(l10n.telemetryImportMetaType, _deviceTypeLabel(l10n, d.deviceType));
    add(l10n.telemetryImportMetaLivestock, d.livestockName);
    add(l10n.telemetryImportMetaFarm, d.farmName);
    return Text.rich(TextSpan(children: spans),
        style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary, height: 1.7));
  }

  String _deviceTypeLabel(AppLocalizations l10n, String raw) => switch (raw) {
        'TRACKER' || 'GPS' => l10n.deviceTypeGps,
        'RUMEN_CAPSULE' => l10n.deviceTypeRumenCapsule,
        _ => raw,
      };

  /// Maps a backend device-match error key to localized text; unknown keys
  /// are shown as-is (spec §4.8).
  String _unmatchedReason(AppLocalizations l10n, TelemetryDeviceMatch d) {
    final key = d.error;
    if (key == null) return l10n.telemetryImportFileBlocked;
    final mapped = switch (key) {
      'error.telemetryImport.deviceNotRegistered' =>
        l10n.telemetryImportErrorDeviceNotRegistered(d.devEui),
      'error.telemetryImport.deviceNotActive' =>
        l10n.telemetryImportErrorDeviceNotActive(d.devEui),
      'error.telemetryImport.unsupportedDeviceType' =>
        l10n.telemetryImportErrorUnsupportedDeviceType(d.deviceType),
      _ => key,
    };
    return '$mapped · ${l10n.telemetryImportFileBlocked}';
  }

  /// Maps a row-level backend error key to localized text; unknown keys are
  /// shown as-is (spec §4.8).
  String _mapRowError(AppLocalizations l10n, String key) => switch (key) {
        'error.telemetryImport.invalidTime' =>
          l10n.telemetryImportErrorInvalidTime,
        'error.telemetryImport.invalidHex' =>
          l10n.telemetryImportErrorInvalidHex,
        _ => key,
      };

  Widget _buildPreviewTable(AppLocalizations l10n, TelemetryParseResult r) {
    const th = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary);
    const mono = TextStyle(fontSize: 12, fontFamily: 'monospace');
    final timeFmt = DateFormat('MM-dd HH:mm:ss');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('telemetry-import-preview-table'),
        headingRowHeight: 36,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 40,
        columnSpacing: AppSpacing.xl,
        columns: [
          const DataColumn(label: Text('#', style: th)),
          DataColumn(
              label: Text(l10n.telemetryImportColFrameCounter, style: th)),
          DataColumn(label: Text(l10n.telemetryImportColTime, style: th)),
          DataColumn(label: Text(l10n.telemetryImportColBattery, style: th)),
          DataColumn(label: Text(l10n.telemetryImportColLatitude, style: th)),
          DataColumn(
              label: Text(l10n.telemetryImportColLongitude, style: th)),
          DataColumn(label: Text(l10n.telemetryImportColSteps, style: th)),
          DataColumn(label: Text(l10n.telemetryImportColStatus, style: th)),
        ],
        rows: r.rows
            .take(8)
            .map((row) => DataRow(cells: [
                  DataCell(Text('${row.rowNo}', style: mono)),
                  DataCell(Text(
                      row.frameCounter.isEmpty ? '—' : row.frameCounter,
                      style: mono)),
                  DataCell(Text(
                      row.recordTime == null
                          ? '—'
                          : timeFmt.format(row.recordTime!),
                      style: mono)),
                  DataCell(Text(row.battery?.toString() ?? '—', style: mono)),
                  DataCell(Text(
                      row.latitude == null
                          ? '—'
                          : row.latitude!.toStringAsFixed(6),
                      style: mono)),
                  DataCell(Text(
                      row.longitude == null
                          ? '—'
                          : row.longitude!.toStringAsFixed(6),
                      style: mono)),
                  DataCell(
                      Text(row.stepCount?.toString() ?? '—', style: mono)),
                  DataCell(_statusTag(l10n, row)),
                ]))
            .toList(),
      ),
    );
  }

  Widget _statusTag(AppLocalizations l10n, TelemetryRowPreview row) {
    final (bg, fg, text) = switch (row.status) {
      TelemetryRowStatus.importable => (
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
          l10n.telemetryImportRowWillImport
        ),
      TelemetryRowStatus.duplicate => (
          const Color(0xFFFFF7ED),
          const Color(0xFFC2410C),
          l10n.telemetryImportRowDuplicate
        ),
      TelemetryRowStatus.skippedDownlink => (
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
          l10n.telemetryImportRowSkipDownlink
        ),
      TelemetryRowStatus.skippedUnsupported => (
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
          l10n.telemetryImportRowSkipUnsupported
        ),
      TelemetryRowStatus.invalid => (
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          l10n.telemetryImportRowInvalid
        ),
      TelemetryRowStatus.unknown => (
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
          row.status.name
        ),
    };
    final tag = Container(
      key: Key('telemetry-import-row-status-${row.rowNo}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
    final error = row.error;
    if (row.status == TelemetryRowStatus.invalid && error != null) {
      return Tooltip(message: _mapRowError(l10n, error), child: tag);
    }
    return tag;
  }

  // ── Step 2: Import result ────────────────────────────────────────

  Widget _buildResultStep(AppLocalizations l10n, TelemetryImportState s) {
    if (s.busy && s.importResult == null) {
      return const SizedBox(
          height: 240, child: Center(child: CircularProgressIndicator()));
    }
    final r = s.importResult;
    if (r == null) return const SizedBox();
    final device = s.parseResult?.device;
    final metaParts = [
      if (device != null && device.livestockName.isNotEmpty)
        device.livestockName,
      if (device != null && device.farmName.isNotEmpty) device.farmName,
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        key: const Key('telemetry-import-result-banner'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF7EF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 3, color: AppColors.success),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                              l10n.telemetryImportDone(
                                  r.telemetryCreated, r.gpsCreated),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2F5D3A),
                                  height: 1.8)),
                        ),
                      ]),
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(l10n.telemetryImportResultDetailTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.sm),
      Container(
        key: const Key('telemetry-import-result-card'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Text('🐄', style: TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.devEui,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  if (metaParts.isNotEmpty)
                    Text(metaParts.join(' · '),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.7)),
                ]),
          ),
          _resultNum('${r.telemetryCreated}',
              l10n.telemetryImportResultTelemetry),
          _resultNum('${r.gpsCreated}', l10n.telemetryImportResultGps),
          _resultNum('${r.duplicateSkipped}',
              l10n.telemetryImportStatDuplicate,
              color: AppColors.warning),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(l10n.telemetryImportResultSuccess,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A))),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.lg),
      _noteBar(
          bg: const Color(0xFFEFF6FB),
          bar: AppColors.info,
          fg: const Color(0xFF33566B),
          text: l10n.telemetryImportResultHint),
      const SizedBox(height: AppSpacing.xl),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        OutlinedButton(
          key: const Key('telemetry-import-another-btn'),
          onPressed: () =>
              ref.read(telemetryImportControllerProvider.notifier).reset(),
          child: Text(l10n.telemetryImportImportAnother),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton(
          key: const Key('telemetry-import-done-btn'),
          onPressed: () =>
              ref.read(telemetryImportControllerProvider.notifier).reset(),
          child: Text(l10n.commonDone),
        ),
      ]),
    ]);
  }

  Widget _resultNum(String value, String label, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────

  Future<void> _runParse() async {
    try {
      await ref.read(telemetryImportControllerProvider.notifier).parse();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _runImport() async {
    try {
      await ref
          .read(telemetryImportControllerProvider.notifier)
          .importTelemetry();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

/// Dashed rounded-rect border for the upload zone (spec §5.3: 2px dashed).
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color});

  final Color color;

  static const _radius = 12.0;
  static const _stroke = 2.0;
  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(_radius))
            .deflate(_stroke / 2);
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
