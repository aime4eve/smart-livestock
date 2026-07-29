import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/track_line_import_dialog.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/track_line_preview_dialog.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Truth-reference sub-tab 3 (NIX-68): standard track line candidates.
/// Toolbar (import / merge-phase2) + candidate table + management rules.
class StandardTracksPanel extends ConsumerStatefulWidget {
  const StandardTracksPanel({super.key});

  @override
  ConsumerState<StandardTracksPanel> createState() =>
      _StandardTracksPanelState();
}

class _StandardTracksPanelState extends ConsumerState<StandardTracksPanel> {
  final Set<int> _checkedIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final linesAsync = ref.watch(trackLinesProvider);

    return Card(
      key: const Key('standard-tracks-panel'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Toolbar ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Text(l10n.gpsQualityTrackLines,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (_checkedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  l10n.gpsQualityLineMergeSelectedCount(_checkedIds.length),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            // Merge is phase-2: entry + interaction only (spec D3/§10).
            OutlinedButton.icon(
              key: const Key('merge-track-lines-btn'),
              icon: const Icon(Icons.merge_type, size: 16),
              label: Text(l10n.gpsQualityLineMerge,
                  style: const TextStyle(fontSize: 12)),
              onPressed:
                  _checkedIds.length >= 2 ? () => _showMergePhase2(l10n) : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              key: const Key('import-track-line-btn'),
              icon: const Icon(Icons.satellite_alt, size: 16),
              label: Text(l10n.gpsQualityTrackLineImportBtn,
                  style: const TextStyle(fontSize: 12)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const TrackLineImportDialog(),
                ).then((_) => ref.invalidate(trackLinesProvider));
              },
            ),
          ]),
        ),
        // ── Management rules callout (append-only, spec D3/D4) ───
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
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
                    child: Text(l10n.gpsQualityTrackLineRules,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ),
              ]),
            ),
          ),
        ),
        // ── Candidate table ──────────────────────────────────────
        linesAsync.when(
          loading: () => const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('$e', style: const TextStyle(color: AppColors.danger)),
          ),
          data: (lines) {
            if (lines.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.route,
                        size: 40, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.gpsQualityTrackLineEmpty,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ]),
                ),
              );
            }
            // SELECTED lines first (★ pinned, spec §8.4), then by import time.
            final sorted = List<StandardTrackLine>.from(lines)
              ..sort((a, b) {
                if (a.selected != b.selected) return a.selected ? -1 : 1;
                return (b.createdAt ?? DateTime(2000))
                    .compareTo(a.createdAt ?? DateTime(2000));
              });
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                key: const Key('track-lines-table'),
                columnSpacing: 16,
                columns: [
                  const DataColumn(label: Text('')),
                  DataColumn(label: Text(l10n.gpsQualityTrackLineName)),
                  DataColumn(label: Text(l10n.gpsQualityTrackLinePoints)),
                  DataColumn(label: Text(l10n.gpsQualityTrackLineLength)),
                  DataColumn(label: Text(l10n.gpsQualityTrackLineImportTime)),
                  DataColumn(label: Text(l10n.gpsQualityStatus)),
                  DataColumn(label: Text(l10n.gpsQualityTrackLineActions)),
                ],
                rows: sorted.map((l) => _buildRow(l10n, l)).toList(),
              ),
            );
          },
        ),
      ]),
    );
  }

  DataRow _buildRow(AppLocalizations l10n, StandardTrackLine l) {
    final checked = _checkedIds.contains(l.id);
    return DataRow(
      key: ValueKey('track-line-${l.id}'),
      cells: [
        DataCell(Checkbox(
          key: ValueKey('track-line-check-${l.id}'),
          value: checked,
          activeColor: AppColors.lineTeal,
          onChanged: (v) => setState(() {
            if (v == true) {
              _checkedIds.add(l.id);
            } else {
              _checkedIds.remove(l.id);
            }
          }),
        )),
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l.name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
            Text(
              '${l10n.gpsQualityTrackLineStartPoint} '
              '${l.startLng?.toStringAsFixed(5) ?? '-'},'
              '${l.startLat?.toStringAsFixed(5) ?? '-'}'
              '${l.sourceFile != null ? ' ｜ ${l.sourceFile}' : ''}',
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace'),
            ),
          ],
        )),
        DataCell(Text('${l.pointCount}',
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
        DataCell(Text('${l.lengthM.toStringAsFixed(0)} m',
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
        DataCell(Text(
          l.createdAt != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(l.createdAt!)
              : '-',
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        )),
        DataCell(_statusBadge(l10n, l)),
        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
          TextButton(
            key: ValueKey('track-line-preview-${l.id}'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => TrackLinePreviewDialog(initialLineId: l.id),
              ).then((_) => ref.invalidate(trackLinesProvider));
            },
            child: Text(l10n.gpsQualityTrackLinePreview,
                style: const TextStyle(fontSize: 12)),
          ),
          TextButton(
            key: ValueKey('track-line-select-${l.id}'),
            onPressed: () => _toggleSelect(l),
            child: Text(
              l.selected
                  ? l10n.gpsQualityTrackLineUnselect
                  : l10n.gpsQualityTrackLineSelect,
              style: TextStyle(
                  fontSize: 12,
                  color: l.selected ? AppColors.warning : AppColors.lineTeal),
            ),
          ),
          IconButton(
            key: ValueKey('track-line-delete-${l.id}'),
            icon: const Icon(Icons.delete_outline,
                size: 16, color: AppColors.danger),
            tooltip: l10n.gpsQualityDelete,
            visualDensity: VisualDensity.compact,
            onPressed: () => _deleteLine(l10n, l),
          ),
        ])),
      ],
    );
  }

  Widget _statusBadge(AppLocalizations l10n, StandardTrackLine l) {
    final (label, bg, fg) = l.selected
        ? (
            l10n.gpsQualityTrackLineSelected,
            const Color(0xFFCCFBF1),
            AppColors.lineTeal,
          )
        : (
            l10n.gpsQualityTrackLineCandidate,
            const Color(0xFFF1F5F9),
            const Color(0xFF475569),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Future<void> _toggleSelect(StandardTrackLine l) async {
    try {
      final repo = ref.read(gpsQualityApiRepositoryProvider);
      if (l.selected) {
        await repo.unselectTrackLine(l.id);
      } else {
        await repo.selectTrackLine(l.id);
      }
      ref.invalidate(trackLinesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _deleteLine(AppLocalizations l10n, StandardTrackLine l) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            key: const Key('delete-track-line-dialog'),
            title: Text(l10n.gpsQualityDelete),
            content: Text(l10n.gpsQualityTrackLineDeleteConfirm(l.name)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.commonCancel)),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.gpsQualityDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await ref.read(gpsQualityApiRepositoryProvider).deleteTrackLine(l.id);
      _checkedIds.remove(l.id);
      ref.invalidate(trackLinesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  /// Phase-2 merge entry (spec §10): interaction only, no algorithm yet.
  void _showMergePhase2(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('merge-phase2-dialog'),
        title: Text(l10n.gpsQualityLineMerge),
        content: Text(l10n.gpsQualityLineMergePhase2(_checkedIds.length)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }
}
