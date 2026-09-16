import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Aggregated fence status for the ranch alert tab: answers "what is the
/// situation right now" (livestock × fence, deduped) above the event stream.
class FenceStatusCard extends StatefulWidget {
  const FenceStatusCard({
    super.key,
    required this.alerts,
    this.livestockCodes = const {},
    this.fenceNames = const {},
    required this.onViewAll,
    this.onRowTap,
  });

  /// Active fence-family alerts (FENCE_BREACH / FENCE_APPROACH / ZONE_APPROACH).
  final List<RanchAlertData> alerts;

  /// livestockId -> code (joined from overview markers when available).
  final Map<String, String> livestockCodes;

  /// fenceId -> name.
  final Map<String, String> fenceNames;

  final VoidCallback onViewAll;
  final void Function(RanchAlertData alert)? onRowTap;

  @override
  State<FenceStatusCard> createState() => _FenceStatusCardState();
}

class _FenceStatusCardState extends State<FenceStatusCard> {
  bool _expanded = true;

  /// (livestockId, fenceId) dedup, breach rows first.
  List<_Row> get _rows {
    final seen = <String>{};
    final out = <_Row>[];
    final sorted = [...widget.alerts]..sort((a, b) {
        final aOut = a.type == 'FENCE_BREACH' ? 0 : 1;
        final bOut = b.type == 'FENCE_BREACH' ? 0 : 1;
        if (aOut != bOut) return aOut - bOut;
        return b.id.compareTo(a.id);
      });
    for (final a in sorted) {
      final key = '${a.livestockId ?? ''}|${a.fenceId ?? ''}';
      if (!seen.add(key)) continue;
      out.add(_Row(
        alert: a,
        isOut: a.type == 'FENCE_BREACH',
        code: widget.livestockCodes[a.livestockId ?? ''] ?? a.livestockId ?? '-',
        fenceName: widget.fenceNames[a.fenceId ?? ''],
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.alerts.isEmpty) return const SizedBox.shrink();

    final rows = _rows;
    final outCount = rows.where((r) => r.isOut).map((r) => r.alert.livestockId).toSet().length;
    final nearCount = rows.where((r) => !r.isOut).map((r) => r.alert.livestockId).toSet().length;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Head
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.fence, size: 15, color: AppColors.danger),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.alertFenceStatusTitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          l10n.alertFenceAggSub(outCount, nearCount),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Expanded rows
          if (_expanded) ...[
            Container(height: 1, color: AppColors.border),
            for (final row in rows)
              _AggRow(
                row: row,
                onTap: () => widget.onRowTap?.call(row.alert),
              ),
            // View all
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onViewAll,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: AppColors.primarySoft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.alertFenceViewAll(widget.alerts.length),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Icon(Icons.arrow_forward,
                        size: 10, color: AppColors.primaryDark),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row {
  const _Row({
    required this.alert,
    required this.isOut,
    required this.code,
    this.fenceName,
  });

  final RanchAlertData alert;
  final bool isOut;
  final String code;
  final String? fenceName;
}

class _AggRow extends StatelessWidget {
  const _AggRow({required this.row, required this.onTap});

  final _Row row;
  final VoidCallback onTap;

  String _timeLabel(String? occurredAt) {
    if (occurredAt == null || occurredAt.length < 16) return '';
    // ISO string → 'MM-dd HH:mm' display without pulling in intl
    final s = occurredAt;
    return '${s.substring(5, 7)}-${s.substring(8, 10)} ${s.substring(11, 16)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: row.isOut ? AppColors.danger : AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            SizedBox(
              width: 64,
              child: Text(
                row.code,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${row.fenceName ?? ''} · ${row.isOut ? l10n.alertFenceStateOut : l10n.alertFenceStateNear}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _timeLabel(row.alert.occurredAt),
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 11, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
