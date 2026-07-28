import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/track_line_map.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

/// Standard track line map preview dialog (NIX-68, spec §8.1):
/// left candidate list + right map overlay (selected = green solid,
/// others = gray) + bottom stats strip. Helps select / merge decisions.
class TrackLinePreviewDialog extends ConsumerStatefulWidget {
  const TrackLinePreviewDialog({super.key, required this.initialLineId});

  final int initialLineId;

  @override
  ConsumerState<TrackLinePreviewDialog> createState() =>
      _TrackLinePreviewDialogState();
}

class _TrackLinePreviewDialogState
    extends ConsumerState<TrackLinePreviewDialog> {
  late int _selectedId;

  static const _otherColors = [Color(0xFF9CA3AF), Color(0xFFB6BCC4)];

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialLineId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final linesAsync = ref.watch(trackLinesProvider);

    return Dialog(
      key: const Key('track-line-preview-dialog'),
      child: Container(
        width: 980,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.gpsQualityLinePreviewTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(l10n.gpsQualityLinePreviewHint,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ]),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
          ),
          const Divider(height: 1),
          Flexible(
            child: linesAsync.when(
              loading: () => const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child:
                    Text('$e', style: const TextStyle(color: AppColors.danger)),
              ),
              data: (lines) => _buildBody(l10n, lines),
            ),
          ),
          const Divider(height: 1),
          _buildActions(l10n),
        ]),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, List<StandardTrackLine> lines) {
    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(l10n.gpsQualityTrackLineEmpty,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    final selected = lines
        .where((l) => l.id == _selectedId)
        .firstOrNull ?? lines.first;
    final others = lines.where((l) => l.id != selected.id).toList();

    // Load point lists lazily per candidate (selected green, others gray).
    final polylines = <Polyline>[];
    for (var i = 0; i < others.length; i++) {
      final pts = ref.watch(trackLinePointsProvider(others[i].id)).value;
      if (pts != null && pts.length >= 2) {
        polylines.add(Polyline(
          points: pts.map((p) => LatLng(p.lat, p.lng)).toList(),
          color: _otherColors[i % _otherColors.length],
          strokeWidth: 2,
        ));
      }
    }
    final selectedPts =
        ref.watch(trackLinePointsProvider(selected.id)).value ?? [];
    final selectedLatLngs =
        selectedPts.map((p) => LatLng(p.lat, p.lng)).toList();
    if (selectedLatLngs.length >= 2) {
      polylines.add(Polyline(
        points: selectedLatLngs,
        color: AppColors.primary,
        strokeWidth: 3.5,
      ));
    }
    final markers = <Marker>[
      if (selectedLatLngs.isNotEmpty) ...[
        Marker(
            point: selectedLatLngs.first,
            width: 14,
            height: 14,
            child: const TrackDotMarker(color: AppColors.primary)),
        Marker(
            point: selectedLatLngs.last,
            width: 14,
            height: 14,
            child: const TrackDotMarker(color: AppColors.primary)),
      ],
    ];

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Left: candidate list ─────────────────────────────────
      SizedBox(
        width: 260,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            for (var i = 0; i < lines.length; i++)
              _previewItem(l10n, lines[i], lines[i].id == selected.id,
                  lines[i].id == selected.id
                      ? AppColors.primary
                      : _otherColors[
                          (others.indexOf(lines[i])) % _otherColors.length]),
          ],
        ),
      ),
      const VerticalDivider(width: 1),
      // ── Right: map + stats strip ─────────────────────────────
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TrackLineMap(
              key: const Key('track-line-preview-map'),
              polylines: polylines,
              markers: markers,
              height: 340,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Bottom stats strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.sm,
                children: [
                  _statItem(l10n.gpsQualityLineCurrentLine, selected.name,
                      mono: true),
                  _statItem(
                      l10n.gpsQualityTrackLinePoints, '${selected.pointCount}'),
                  _statItem(l10n.gpsQualityTrackLineLength,
                      '${selected.lengthM.toStringAsFixed(0)} m'),
                  _statItem(
                    l10n.gpsQualityTrackLineStartPoint,
                    '${selected.startLng?.toStringAsFixed(5) ?? '-'}, '
                    '${selected.startLat?.toStringAsFixed(5) ?? '-'}',
                    mono: true,
                  ),
                  _statItem(
                    l10n.gpsQualityTrackLineImportTime,
                    selected.createdAt != null
                        ? DateFormat('yyyy-MM-dd HH:mm')
                            .format(selected.createdAt!)
                        : '-',
                    mono: true,
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _previewItem(
      AppLocalizations l10n, StandardTrackLine l, bool sel, Color dotColor) {
    return InkWell(
      key: ValueKey('preview-item-${l.id}'),
      onTap: () => setState(() => _selectedId = l.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFF0FDFA) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
                color: sel ? AppColors.lineTeal : Colors.transparent,
                width: 3),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(l.name,
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 2),
          Text(
            '${l10n.gpsQualityTrackLinePointLength(l.pointCount, l.lengthM.toStringAsFixed(0))}'
            ' · ${l.selected ? l10n.gpsQualityTrackLineSelected : l10n.gpsQualityTrackLineCandidate}',
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ]),
      ),
    );
  }

  Widget _statItem(String label, String value, {bool mono = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: mono ? 'monospace' : null)),
      Text(label,
          style:
              const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(children: [
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonClose),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton(
          key: const Key('preview-select-btn'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.lineTeal),
          onPressed: () async {
            try {
              await ref
                  .read(gpsQualityApiRepositoryProvider)
                  .selectTrackLine(_selectedId);
              ref.invalidate(trackLinesProvider);
              if (mounted) Navigator.of(context).pop();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$e')));
              }
            }
          },
          child: Text(l10n.gpsQualityLineSelectThis),
        ),
      ]),
    );
  }
}
