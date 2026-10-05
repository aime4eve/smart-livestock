import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_models.dart';
import 'package:hkt_livestock_agentic/features/physiology/presentation/physiology_controller.dart';
import 'package:hkt_livestock_agentic/features/physiology/presentation/widgets/physiology_entry_sheet.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Physiology record card for the livestock detail page (NIX-256, spec:
/// physiology-record-card.md, prototype v1.2).
///
/// Six states: normal / empty / loading skeleton / error / role-downgraded
/// (add button hidden) / active-window chip on open illness rows.
///
/// The app-wide [Card] theme (r16 + margin 8 + elevation shadow) does not
/// match the spec card values (r12, shadow-card, padding 12), so the
/// container is built inline per the frozen prototype CSS.
class PhysiologyRecordCard extends ConsumerWidget {
  const PhysiologyRecordCard({super.key, required this.livestockId});

  final String livestockId;

  static bool canWriteRole(UserRole? role) {
    return role == UserRole.owner ||
        role == UserRole.b2bAdmin ||
        role == UserRole.worker;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(physiologyEventsControllerProvider(livestockId));
    final role = ref.watch(sessionControllerProvider.select((s) => s.role));

    return Container(
      key: const Key('physiology-record-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          // --shadow-card: 0 1px 3px rgba(38,49,38,.06), 0 1px 2px rgba(38,49,38,.04)
          BoxShadow(
            color: Color(0x0F263126),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x0A263126),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: async.when(
        // States ③/④ keep the card header (title only, no stage chip) so
        // the card keeps its identity mid-load and on failure — same shape
        // as the drinking-card five-state convention (spec §10 A3).
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardHeader(),
            SizedBox(height: 8),
            _SkeletonLines(),
          ],
        ),
        error: (e, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardHeader(),
            const SizedBox(height: 8),
            _ErrorBlock(livestockId: livestockId),
          ],
        ),
        data: (data) => _buildContent(context, ref, data, canWriteRole(role)),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PhysiologyEventListResponse data,
    bool canWrite,
  ) {
    final recent = [...data.items]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardHeader(stage: data.stage),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          const _EmptyState()
        else
          for (var i = 0; i < recent.length && i < 3; i++)
            _EventRow(
              item: recent[i],
              isLast: i == 2 || i == recent.length - 1,
              // Row-level edit / delete: MANUAL rows only (M7). The
              // backend rejects DISPOSITION / ALERT_CONFIRM rows with
              // 409, so those rows get no actions at all.
              canEdit: canWrite && recent[i].isEditableRow,
              onEdit: () =>
                  showPhysiologyEntrySheet(context, livestockId, editing: recent[i]),
              onDelete: () => _confirmDelete(context, ref, recent[i]),
            ),
        if (canWrite) ...[
          const SizedBox(height: 9),
          _AddRecordButton(livestockId: livestockId),
        ],
      ],
    );
  }

  /// Confirm-then-delete for one MANUAL row (M7). Shows the server-side
  /// i18n message on API failures; never leaks raw technical strings
  /// (lesson #25).
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PhysiologyEventItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.healthPhysiologyDeleteTitle,
          key: const ValueKey('physiology-delete-dialog-title'),
        ),
        content: Text(
          l10n.healthPhysiologyDeleteConfirm,
          key: const ValueKey('physiology-delete-dialog-message'),
        ),
        actions: [
          TextButton(
            key: const Key('physiology-delete-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const Key('physiology-delete-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.healthPhysiologyDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(physiologyEventsControllerProvider(livestockId).notifier)
          .deleteEvent(eventId: item.id!);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.healthPhysiologySaveFailed)),
      );
    }
  }
}

/// Card header row (sec): 8×8 brand-green dot + "生理记录" (fs12 fw700),
/// plus the stage chip on the right when data is available.
class _CardHeader extends StatelessWidget {
  const _CardHeader({this.stage});

  final PhysiologyStageProjection? stage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.healthPhysiologyTitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (stage != null) _StageChip(stage: stage!),
      ],
    );
  }
}

/// Spec state ③: three static gradient skeleton lines (100/82/60).
class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final width in const [1.0, 0.82, 0.60])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: FractionallySizedBox(
              widthFactor: width,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(
                    // linear-gradient(90deg, surface 25%, #ECE9E1 50%, surface 75%)
                    colors: [
                      AppColors.surface,
                      Color(0xFFECE9E1),
                      AppColors.surface,
                    ],
                    stops: [0.25, 0.5, 0.75],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Idle stage chip: 「泌乳期 · 第 N 天」/「干奶期」(chip.idle, spec B5).
class _StageChip extends StatelessWidget {
  const _StageChip({required this.stage});

  final PhysiologyStageProjection stage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (stage.type) {
      PhysiologyStageType.lactating => l10n.healthPhysiologyStageLactating(
        _lactationDayCount(stage.since),
      ),
      PhysiologyStageType.dry => l10n.healthPhysiologyStageDry,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Day N = whole days between since and today (local) + 1.
  static int _lactationDayCount(DateTime sinceUtc) {
    final since = sinceUtc.toLocal();
    final now = DateTime.now();
    final start = DateTime.utc(since.year, since.month, since.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    final days = today.difference(start).inDays + 1;
    return days < 1 ? 1 : days;
  }
}

/// One event row (ev-row): 30×30 icon + name/source + date or window chip.
/// MANUAL rows editable by the current role end with small edit / delete
/// icon buttons (M7).
class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.item,
    required this.isLast,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  final PhysiologyEventItem item;
  final bool isLast;

  /// True when the row is MANUAL and the role may write — gates both
  /// trailing actions.
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (emoji, name) = _eventLabel(l10n, item.eventType);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _sourceLine(l10n, item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (item.active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                // rgba(217,123,41,.12) on --fever text (chip.disp, spec B5)
                color: AppColors.fever.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.healthPhysiologyWindowActive,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fever,
                ),
              ),
            )
          else
            Text(
              _formatLocalDate(item.occurredAt),
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          if (canEdit) ...[
            const SizedBox(width: 6),
            _RowIconButton(
              key: Key('physiology-edit-${item.id}'),
              icon: Icons.edit,
              tooltip: l10n.healthPhysiologyEditSheetTitle,
              onTap: onEdit,
            ),
            _RowIconButton(
              key: Key('physiology-delete-${item.id}'),
              icon: Icons.delete_outline,
              tooltip: l10n.healthPhysiologyDeleteTitle,
              onTap: onDelete,
            ),
          ],
        ],
      ),
    );
  }

  static (String, String) _eventLabel(
    AppLocalizations l10n,
    PhysiologyEventType type,
  ) {
    return switch (type) {
      PhysiologyEventType.calving => ('🐮', l10n.healthPhysiologyEventCalving),
      PhysiologyEventType.breeding => ('❤️', l10n.healthPhysiologyEventBreeding),
      PhysiologyEventType.pregnancyCheck => (
        '🤰',
        l10n.healthPhysiologyEventPregnancyCheck
      ),
      PhysiologyEventType.dryOff => ('⏸️', l10n.healthPhysiologyEventDryOff),
      PhysiologyEventType.illness => ('💊', l10n.healthPhysiologyEventIllness),
      PhysiologyEventType.recovery => ('✅', l10n.healthPhysiologyEventRecovery),
    };
  }

  static String _sourceLine(AppLocalizations l10n, PhysiologyEventItem item) {
    switch (item.source) {
      case PhysiologySource.disposition:
        return l10n.healthPhysiologySourceDisposition(item.refId ?? 0);
      case PhysiologySource.alertConfirm:
        return item.note == null || item.note!.isEmpty
            ? l10n.healthPhysiologySourceAlertConfirm
            : '${item.note} · ${l10n.healthPhysiologySourceAlertConfirm}';
      case PhysiologySource.manual:
        return item.note == null || item.note!.isEmpty
            ? l10n.healthPhysiologySourceManual
            : '${item.note} · ${l10n.healthPhysiologySourceManual}';
    }
  }

  /// yyyy-MM-dd in the device timezone. occurredAt arrives as a UTC
  /// instant; no extra toUtc() round-trip (lesson #17).
  static String _formatLocalDate(DateTime utcInstant) {
    final local = utcInstant.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Small trailing row action (M7): 16px secondary-colored icon in a
/// 24×24 tap target, lightweight like the drinking marking-loop buttons.
class _RowIconButton extends StatelessWidget {
  const _RowIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Primary add-record button (add-btn): brand green, r8, padding 8×0.
class _AddRecordButton extends StatelessWidget {
  const _AddRecordButton({required this.livestockId});

  final String livestockId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: const Key('physiology-add-record'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => showPhysiologyEntrySheet(context, livestockId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            l10n.healthPhysiologyAddRecord,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Spec state ②: dashed-border empty state.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CustomPaint(
      foregroundPainter: _DashedRoundedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            const Text('📋', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 5),
            Text(
              l10n.healthPhysiologyEmptyTitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              l10n.healthPhysiologyEmptyHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1px dashed rounded-8 border in --border (state-empty container).
class _DashedRoundedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.border;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final segmentLength = draw ? 4.0 : 3.0;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + segmentLength),
            paint,
          );
        }
        distance += segmentLength;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      false;
}

/// Spec state ④: error block with danger heading + retry.
class _ErrorBlock extends ConsumerWidget {
  const _ErrorBlock({required this.livestockId});

  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.healthPhysiologyErrorTitle,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          l10n.healthPhysiologyErrorDesc,
          style: const TextStyle(
            fontSize: 9.5,
            height: 1.55,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
        Material(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            key: const Key('physiology-retry'),
            borderRadius: BorderRadius.circular(6),
            onTap: () => ref
                .read(physiologyEventsControllerProvider(livestockId).notifier)
                .refresh(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                l10n.healthPhysiologyRetry,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
