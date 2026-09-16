import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/file/pick_file.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/data/fence_track_parse_repository.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_to_envelope_converter.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/import_wizard_shell.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// 载入围栏表单的结果：WGS-84 顶点 + 默认名称（来自 GPX <name>/文件名）。
class FenceTrackImportResult {
  const FenceTrackImportResult({
    required this.vertices,
    required this.defaultName,
    required this.multiArea,
  });

  final List<LatLng> vertices;
  final String defaultName;

  /// 检测到多片区域（丢弃环 ≥1），UI 据此提示。
  final bool multiArea;
}

/// 围栏"导入 GPX"三步向导（NIX-213）：上传 → 解析预览 → 包络结果。
///
/// 交互与数据契约借鉴 GPS 质量检验的 track-lines 导入；差异：解析结果在
/// 客户端跑外包络管线，终点是"载入围栏表单"而非服务端落库。
class FenceTrackImportDialog extends StatefulWidget {
  const FenceTrackImportDialog({
    super.key,
    this.debugFileBytes,
    this.parseOverride,
  });

  /// 测试钩子：预置选取的文件内容，跳过系统文件选择器。
  final ({String name, List<int> bytes})? debugFileBytes;

  /// 测试钩子：替换服务端解析调用。
  final Future<FenceTrackParseResult> Function(List<int> bytes, String fileName)?
      parseOverride;

  @override
  State<FenceTrackImportDialog> createState() => _FenceTrackImportDialogState();
}

class _FenceTrackImportDialogState extends State<FenceTrackImportDialog> {
  static const _extensions = ['gpx', 'xml', 'xlsx'];

  int _step = 0;
  bool _busy = false;
  String? _fileName;
  FenceTrackParseResult? _parseResult;
  TrackToEnvelopeResult? _envelope;

  Future<FenceTrackParseResult> _parse(
          List<int> bytes, String fileName) =>
      widget.parseOverride?.call(bytes, fileName) ??
          parseFenceTrackGpx(bytes, fileName);

  Future<void> _pickAndParse() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = widget.debugFileBytes ??
        await pickFileBytesWithName(_extensions);
    if (picked == null || !mounted) return;
    setState(() {
      _fileName = picked.name;
      _busy = true;
    });
    try {
      final result = await _parse(picked.bytes, picked.name);
      if (!mounted) return;
      setState(() {
        _parseResult = result;
        _step = 1;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fenceImportGpxFailed(e.toString()))),
      );
    }
  }

  void _buildEnvelope() {
    final l10n = AppLocalizations.of(context)!;
    final parse = _parseResult;
    if (parse == null) return;
    final envelope = TrackToEnvelopeConverter.convert(parse.trackPoints);
    if (!envelope.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            envelope.failure == EnvelopeFailure.degenerate
                ? l10n.fenceTrackDegenerate
                : l10n.fenceTrackTooFewPoints,
          ),
        ),
      );
      return;
    }
    setState(() {
      _envelope = envelope;
      _step = 2;
    });
  }

  void _apply() {
    final envelope = _envelope;
    final parse = _parseResult;
    if (envelope == null || parse == null) return;
    Navigator.of(context).pop(FenceTrackImportResult(
      vertices: envelope.vertices,
      defaultName: parse.defaultName,
      multiArea: envelope.ringsDropped > 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      key: const Key('fence-track-import-dialog'),
      title: Text(l10n.fenceImportGpxTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: ImportWizardShell(
            step: _step,
            stepCount: 3,
            stepLabels: [
              l10n.fenceImportStepUpload,
              l10n.fenceImportStepPreview,
              l10n.fenceImportStepResult,
            ],
            child: _buildStep(l10n),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('fence-import-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        if (_step == 0)
          FilledButton(
            key: const Key('fence-import-pick-file'),
            onPressed: _busy ? null : _pickAndParse,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.fenceImportPickFile),
          ),
        if (_step == 1)
          FilledButton(
            key: const Key('fence-import-generate'),
            onPressed:
                (_parseResult?.pointCount ?? 0) < 3 ? null : _buildEnvelope,
            child: Text(l10n.fenceImportGenerate),
          ),
        if (_step == 2)
          FilledButton(
            key: const Key('fence-import-apply'),
            onPressed: _apply,
            child: Text(l10n.fenceImportApply),
          ),
      ],
    );
  }

  Widget _buildStep(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.fenceImportFormatHint,
              key: const Key('fence-import-format-hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_fileName != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _fileName!,
                key: const Key('fence-import-file-name'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        );
      case 1:
        final parse = _parseResult!;
        return Column(
          key: const Key('fence-import-preview'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _statRow(l10n.fenceImportRawPoints, '${parse.rawPointCount}'),
            _statRow(l10n.fenceImportCleanPoints, '${parse.pointCount}'),
            _statRow(l10n.fenceImportRemovedDuplicates,
                '${parse.removedDuplicates}'),
            _statRow(l10n.fenceImportLength,
                l10n.fenceImportMeters(parse.lengthMeters.toStringAsFixed(1))),
            if (parse.metadataWarning != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                parse.metadataWarning!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.warning),
              ),
            ],
          ],
        );
      default:
        final envelope = _envelope!;
        final parse = _parseResult!;
        return Column(
          key: const Key('fence-import-result'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.fenceTrackVertices(envelope.vertexCount),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              envelope.method == HullMethod.concave
                  ? l10n.fenceImportMethodConcave
                  : l10n.fenceImportMethodConvex,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (envelope.outliersDropped > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.fenceTrackOutliersRemoved(envelope.outliersDropped),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (envelope.ringsDropped > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.fenceTrackMultiArea,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.warning),
              ),
            ],
            if (parse.defaultName.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                parse.defaultName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
    }
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            key: Key('fence-import-stat-$label'),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
