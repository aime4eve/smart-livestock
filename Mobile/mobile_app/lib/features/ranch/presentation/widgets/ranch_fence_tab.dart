import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/fence_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/fence_delete_dialog.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_polygon_contains.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/ranch_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/fence_sandbox_painter.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/ranch_summary_tile.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Fence list tab content for the ranch bottom sheet.
/// Shows fence items with edit/delete, and an expandable detail card.
class RanchFenceTab extends ConsumerStatefulWidget {
  const RanchFenceTab({
    super.key,
    required this.fences,
    required this.alerts,
    required this.noGpsCount,
    required this.outsideFenceCount,
    required this.totalLivestock,
    required this.fenceUnread,
    required this.fenceStatusMap,
    required this.livestockMarkers,
    required this.selectedFenceId,
    required this.onFenceSelected,
    this.canManage = false,
  });

  final List<RanchFenceData> fences;
  final List<RanchAlertData> alerts;

  /// Livestock without a GPS fix — counted in no fence. Together with
  /// [outsideFenceCount] this reconciles the per-fence counts with the
  /// overview total: total = inside + outside + no GPS.
  final int noGpsCount;
  final int outsideFenceCount;

  /// Total livestock on the farm (livestock summary tile).
  final int totalLivestock;

  /// Unread fence alerts (summary tile badge).
  final int fenceUnread;

  /// Per-livestock fence status (SAFE / APPROACH / BREACH), built by
  /// RanchPage and shared with the map markers.
  final Map<String, String> fenceStatusMap;

  /// Livestock positions used to render the per-fence sandbox dots.
  final List<RanchLivestockMarker> livestockMarkers;

  final String? selectedFenceId;
  final void Function(String fenceId) onFenceSelected;
  final bool canManage;

  @override
  ConsumerState<RanchFenceTab> createState() => _RanchFenceTabState();
}

class _RanchFenceTabState extends ConsumerState<RanchFenceTab>
    with SingleTickerProviderStateMixin {
  /// Shared 22.8s master loop (Spec §3.2/§6): scan 6 cycles, watch 12,
  /// alert 19 — integer phases so nothing jumps at the wrap.
  late final AnimationController _sandboxClock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 22800),
  )..repeat();

  static const Color _tileGreen1 = Color(0xFF2F6B3B);
  static const Color _tileGreen2 = Color(0xFF3E7F4C);
  static const Color _tileRed1 = Color(0xFFB3453B);
  static const Color _tileRed2 = Color(0xFFC9664F);

  static const Set<String> _fenceAlertTypes = {
    'FENCE_BREACH',
    'FENCE_APPROACH',
    'ZONE_APPROACH',
  };

  @override
  void dispose() {
    _sandboxClock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedId = widget.selectedFenceId;
    final selectedFence = selectedId == null
        ? null
        : widget.fences.where((f) => f.id == selectedId).firstOrNull;

    // Per-fence active fence alert counts drive the alert tile and chips.
    final activeByFence = <String, int>{};
    for (final alert in widget.alerts) {
      if (alert.status != 'ACTIVE' ||
          !_fenceAlertTypes.contains(alert.type) ||
          (alert.fenceId ?? '').isEmpty) {
        continue;
      }
      activeByFence[alert.fenceId!] = (activeByFence[alert.fenceId!] ?? 0) + 1;
    }
    final fenceAlertTotal = activeByFence.values.fold(0, (a, b) => a + b);
    final involvedFences = activeByFence.length;
    final activeFenceCount = widget.fences.where((f) => f.active).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecHead(
            title: l10n.alertFenceStatusTitle,
            sub: l10n.fenceStatusSummary(
              widget.fences.length,
              widget.totalLivestock,
            ),
          ),
          const SizedBox(height: 7),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RanchSummaryTile(
                    colored: widget.fences.isNotEmpty,
                    c1: _tileGreen1,
                    c2: _tileGreen2,
                    label: l10n.tileFence,
                    big: '${widget.fences.length}',
                    sub: l10n.fenceTileActiveSub(activeFenceCount),
                    subColor: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: RanchSummaryTile(
                    colored: false,
                    c1: _tileGreen1,
                    c2: _tileGreen2,
                    label: l10n.fenceTileLivestock,
                    big: '${widget.totalLivestock}',
                    sub: widget.noGpsCount > 0
                        ? l10n.fenceTileLivestockSubGps(widget.noGpsCount)
                        : l10n.fenceTileLivestockSubOk,
                    subColor: widget.noGpsCount > 0
                        ? AppColors.textSecondary
                        : AppColors.success,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: RanchSummaryTile(
                    colored: fenceAlertTotal > 0,
                    c1: _tileRed1,
                    c2: _tileRed2,
                    label: l10n.ranchTabAlerts,
                    big: '$fenceAlertTotal',
                    sub: involvedFences > 0
                        ? l10n.fenceTileAlertSub(involvedFences)
                        : l10n.fenceTileAlertClear,
                    subColor: involvedFences > 0
                        ? AppColors.textSecondary
                        : AppColors.success,
                    badge: widget.fenceUnread,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          if (selectedFence == null) ...[
            _SecHead(
              dotColor: AppColors.danger,
              title: l10n.alertFenceListTitle,
              sub: widget.canManage ? l10n.fenceListHint : null,
              trailing: widget.canManage
                  ? _AddFenceButton(
                      onCreated: () {
                        ref.read(ranchControllerProvider.notifier).refresh();
                      },
                    )
                  : null,
            ),
            const SizedBox(height: 7),
          ],
          if (selectedFence != null) ...[
            _SecHead(
              title: selectedFence.name,
              trailing: _CollapseFenceButton(
                onTap: () => widget.onFenceSelected(''),
              ),
            ),
            const SizedBox(height: 7),
            _FenceDetailCard(
              fence: selectedFence,
              alerts: widget.alerts,
              livestockMarkers: widget.livestockMarkers,
              fenceStatusMap: widget.fenceStatusMap,
              progress: _sandboxClock,
              canManage: widget.canManage,
              onDelete: () => _deleteFence(selectedFence),
              onEdit: () => _openFullEditor(selectedFence.id),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          // Fence items
          for (final fence in widget.fences)
            _FenceListItem(
              fence: fence,
              isSelected: fence.id == selectedId,
              isDimmed: selectedId != null && fence.id != selectedId,
              activeAlerts: activeByFence[fence.id] ?? 0,
              livestockMarkers: widget.livestockMarkers,
              fenceStatusMap: widget.fenceStatusMap,
              progress: _sandboxClock,
              canManage: widget.canManage,
              onTap: () {
                if (selectedId == fence.id) {
                  widget.onFenceSelected('');
                } else {
                  widget.onFenceSelected(fence.id);
                }
              },
              onEdit: () => _openFullEditor(fence.id),
              onDelete: () => _deleteFence(fence),
            ),
          // Reconciliation line: explains why per-fence counts may be lower
          // than the overview "livestock total" (animals with no GPS fix or
          // outside every active fence belong to no fence).
          if (widget.noGpsCount + widget.outsideFenceCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  l10n.ranchFenceLocationGap(
                    widget.noGpsCount,
                    widget.outsideFenceCount,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 打开围栏页的完整编辑模式（拖拽顶点/整体平移/增删顶点）。
  /// fenceController 在 ranch 页可能尚未初始化，需先确保围栏列表加载完成，
  /// 否则 startEditing 找不到目标围栏会静默失败。
  Future<void> _openFullEditor(String fenceId) async {
    final known = ref
        .read(fenceControllerProvider)
        .fences
        .any((f) => f.id == fenceId);
    if (!known) {
      await ref.read(fenceControllerProvider.notifier).ensureLoaded();
    }
    if (!mounted) return;
    ref.read(fenceControllerProvider.notifier).startEditing(fenceId);
    if (!mounted) return;
    await context.push(AppRoute.fence.path);
    // 编辑（或放弃）返回后同步牧场概览数据
    if (mounted) ref.read(ranchControllerProvider.notifier).refresh();
  }

  Future<void> _deleteFence(RanchFenceData fence) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showFenceDeleteConfirmDialog(
      context,
      fenceName: fence.name,
    );
    if (choice == null || !mounted) return;
    final deleteAlerts = choice == FenceDeleteAlertsChoice.deleteWithAlerts;
    try {
      final result = await ApiClient.instance.farmDeleteJson(
        '/fences/${fence.id}?deleteAlerts=$deleteAlerts',
      );
      if (!mounted) return;
      widget.onFenceSelected('');
      ref.read(ranchControllerProvider.notifier).refresh();
      final deletedAlerts = (result['deletedAlerts'] as num?)?.toInt() ?? 0;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              deleteAlerts && deletedAlerts > 0
                  ? l10n.ranchFenceDeletedWithAlerts(fence.name, deletedAlerts)
                  : l10n.ranchFenceDeleted(fence.name),
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.commonDeleteFailed(e.toString()))),
        );
    }
  }
}

// ── Fence list item ──

List<FenceSandboxDot> _fenceDotsFor(
  RanchFenceData fence,
  List<RanchLivestockMarker> livestockMarkers,
  Map<String, String> fenceStatusMap,
) {
  if (fence.points.length < 3) {
    return const [];
  }
  return [
    for (final m in livestockMarkers)
      if (fencePolygonContainsLatLng(m.toLatLng(), fence.points))
        FenceSandboxDot(
          id: m.livestockId,
          position: m.toLatLng(),
          status: switch (fenceStatusMap[m.livestockId]) {
            'BREACH' => FenceDotStatus.alert,
            'APPROACH' => FenceDotStatus.watch,
            _ => FenceDotStatus.safe,
          },
        ),
  ];
}

class _FenceListItem extends StatelessWidget {
  const _FenceListItem({
    required this.fence,
    required this.isSelected,
    required this.isDimmed,
    required this.activeAlerts,
    required this.livestockMarkers,
    required this.fenceStatusMap,
    required this.progress,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final RanchFenceData fence;
  final bool isSelected;
  final bool isDimmed;
  final int activeAlerts;
  final List<RanchLivestockMarker> livestockMarkers;
  final Map<String, String> fenceStatusMap;
  final Animation<double> progress;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ringColor = Color(fence.colorValue);
    // Selected state wins: dimmed cards are 0.5; otherwise an inactive
    // fence renders at 0.6 (Spec §3.2).
    final opacity = isDimmed ? 0.5 : (fence.active ? 1.0 : 0.6);
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F263126),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x0A263126),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: ringColor),
                  _FenceSandboxThumb(
                    fence: fence,
                    livestockMarkers: livestockMarkers,
                    fenceStatusMap: fenceStatusMap,
                    ringColor: ringColor,
                    progress: progress,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fence.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              _tagPill(
                                text: _fenceTypeLabel(fence.type, l10n),
                                bg: AppColors.info.withValues(alpha: 0.1),
                                fg: AppColors.info,
                              ),
                              if (!fence.active) ...[
                                const SizedBox(width: 4),
                                _tagPill(
                                  text: l10n.ranchFenceInactive,
                                  bg: AppColors.textSecondary.withValues(
                                    alpha: 0.1,
                                  ),
                                  fg: AppColors.textSecondary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${l10n.ranchFenceInFenceCount(fence.livestockCount)} · ${l10n.alertFenceArea(fence.areaHectares.toStringAsFixed(1))}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (activeAlerts > 0)
                                _alertChip(
                                  text:
                                      '⚠ ${l10n.alertFenceAlertCount(activeAlerts)}',
                                  bg: AppColors.danger.withValues(alpha: 0.1),
                                  fg: AppColors.danger,
                                )
                              else
                                _alertChip(
                                  text: '✓ ${l10n.tileDeviceNormal}',
                                  bg: AppColors.success.withValues(alpha: 0.1),
                                  fg: AppColors.success,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (canManage)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FenceIconAction(
                            icon: Icons.edit_outlined,
                            onTap: onEdit,
                          ),
                          const SizedBox(height: 4),
                          _FenceIconAction(
                            icon: Icons.delete_outline,
                            danger: true,
                            onTap: onDelete,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _tagPill({required String text, required Color bg, required Color fg}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}

Widget _alertChip({
  required String text,
  required Color bg,
  required Color fg,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: fg),
    ),
  );
}

String _fenceTypeLabel(String type, AppLocalizations l10n) {
  return switch (type.toUpperCase()) {
    'POLYGON' => l10n.fenceTypePolygon,
    'RECTANGLE' || 'RECT' => l10n.fenceTypeRectangle,
    'CIRCLE' => l10n.fenceTypeCircle,
    _ => l10n.fenceTypeUnknown,
  };
}

class _FenceIconAction extends StatelessWidget {
  const _FenceIconAction({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: danger
              ? AppColors.danger.withValues(alpha: 0.1)
              : AppColors.textSecondary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 13,
          color: danger ? AppColors.danger : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SecHead extends StatelessWidget {
  const _SecHead({
    required this.title,
    this.dotColor = AppColors.primary,
    this.sub,
    this.trailing,
  });

  final String title;
  final Color dotColor;
  final String? sub;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          flex: 6,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        if (sub != null)
          Expanded(
            flex: 4,
            child: Text(
              sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class _FenceSandboxThumb extends StatelessWidget {
  const _FenceSandboxThumb({
    required this.fence,
    required this.livestockMarkers,
    required this.fenceStatusMap,
    required this.ringColor,
    required this.progress,
  });

  final RanchFenceData fence;
  final List<RanchLivestockMarker> livestockMarkers;
  final Map<String, String> fenceStatusMap;
  final Color ringColor;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final dots = _fenceDotsFor(fence, livestockMarkers, fenceStatusMap);
    return Container(
      width: 92,
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_sandboxTop, _sandboxBottom],
        ),
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: fence.points.length < 3
          ? Center(
              child: Icon(
                Icons.crop_free,
                size: 22,
                color: AppColors.textSecondary.withValues(alpha: 0.45),
              ),
            )
          : AnimatedBuilder(
              animation: progress,
              builder: (context, _) => RepaintBoundary(
                child: CustomPaint(
                  painter: FenceSandboxPainter(
                    data: FenceSandboxData(
                      ring: fence.points,
                      dots: dots,
                      mode: FenceSandboxMode.list,
                      progress: progress.value,
                    ),
                    ringColor: ringColor,
                  ),
                ),
              ),
            ),
    );
  }
}

const Color _sandboxTop = Color(0xFFEAF3E6);
const Color _sandboxBottom = Color(0xFFDCE8D5);

class _AddFenceButton extends StatelessWidget {
  const _AddFenceButton({required this.onCreated});

  final VoidCallback onCreated;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => context.push(AppRoute.fenceForm.path).then((saved) {
        if (saved == true) {
          onCreated();
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.info,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 10, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              l10n.alertFenceAddBtn,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapseFenceButton extends StatelessWidget {
  const _CollapseFenceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          l10n.commonCollapse,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Fence detail card ──

class _FenceDarkCanvas extends StatelessWidget {
  const _FenceDarkCanvas({
    required this.fence,
    required this.dots,
    required this.ringColor,
    required this.progress,
    required this.badgeText,
    required this.hasShape,
    required this.hasAlerts,
  });

  final RanchFenceData fence;
  final List<FenceSandboxDot> dots;
  final Color ringColor;
  final Animation<double> progress;
  final String badgeText;
  final bool hasShape;
  final bool hasAlerts;

  @override
  Widget build(BuildContext context) {
    String? coordText;
    if (hasShape) {
      var minLat = fence.points.first.latitude;
      var maxLat = minLat;
      var minLng = fence.points.first.longitude;
      var maxLng = minLng;
      for (final p in fence.points) {
        minLat = math.min(minLat, p.latitude);
        maxLat = math.max(maxLat, p.latitude);
        minLng = math.min(minLng, p.longitude);
        maxLng = math.max(maxLng, p.longitude);
      }
      final lng = (minLng + maxLng) / 2;
      final lat = (minLat + maxLat) / 2;
      coordText = '${lng.toStringAsFixed(3)}°E ${lat.toStringAsFixed(3)}°N';
    }
    return Container(
      height: 108,
      color: const Color(0xFF14251A),
      child: Stack(
        children: [
          Positioned.fill(
            child: hasShape
                ? AnimatedBuilder(
                    animation: progress,
                    builder: (context, _) => CustomPaint(
                      painter: FenceSandboxPainter(
                        data: FenceSandboxData(
                          ring: fence.points,
                          dots: dots,
                          mode: FenceSandboxMode.detail,
                          progress: progress.value,
                        ),
                        ringColor: ringColor,
                        drawGrid: true,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: FenceSandboxPainter(
                      data: const FenceSandboxData(ring: []),
                      ringColor: ringColor,
                      drawGrid: true,
                    ),
                  ),
          ),
          if (hasShape)
            AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                final phase = (progress.value * 6) % 1;
                // Travel from -2 to 108 so the line fully leaves the canvas
                // at both ends (no wrap jump).
                return Positioned(
                  top: phase * 110 - 2,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0x008FD694),
                          Color(0xA68FD694),
                          Color(0x008FD694),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          if (coordText != null)
            Positioned(
              left: 8,
              bottom: 6,
              child: Text(
                coordText,
                style: const TextStyle(
                  fontSize: 6.5,
                  fontFamily: 'monospace',
                  color: Color(0x668FD694),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasAlerts
                    ? AppColors.danger
                    : AppColors.success.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: hasAlerts ? Colors.white : const Color(0xFF8FD694),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FenceDetailCard extends StatelessWidget {
  const _FenceDetailCard({
    required this.fence,
    required this.alerts,
    required this.livestockMarkers,
    required this.fenceStatusMap,
    required this.progress,
    required this.canManage,
    required this.onDelete,
    required this.onEdit,
  });

  final RanchFenceData fence;
  final List<RanchAlertData> alerts;
  final List<RanchLivestockMarker> livestockMarkers;
  final Map<String, String> fenceStatusMap;
  final Animation<double> progress;
  final bool canManage;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ringColor = Color(fence.colorValue);
    final activeAlerts = alerts
        .where((a) => a.fenceId == fence.id && a.status == 'ACTIVE')
        .length;
    final dots = _fenceDotsFor(fence, livestockMarkers, fenceStatusMap);
    final hasShape = fence.points.length >= 3;
    final nearCount = alerts
        .where(
          (a) =>
              a.fenceId == fence.id &&
              a.status == 'ACTIVE' &&
              (a.type == 'FENCE_APPROACH' || a.type == 'ZONE_APPROACH'),
        )
        .map((a) => a.livestockId)
        .whereType<String>()
        .toSet()
        .length;
    // Green badge for shapeless fences regardless of alerts (Spec §3.3).
    final hasAlerts = hasShape && activeAlerts > 0;
    final badgeText = hasAlerts
        ? '${l10n.alertFenceAlertCount(activeAlerts)}'
              '${nearCount > 0 ? ' · ${l10n.fenceNearBoundary(nearCount)}' : ''}'
        : '✓ ${l10n.tileDeviceNormal}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F263126),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FenceDarkCanvas(
              fence: fence,
              dots: dots,
              ringColor: ringColor,
              progress: progress,
              badgeText: badgeText,
              hasShape: hasShape,
              hasAlerts: hasAlerts,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: ringColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          fence.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      _tagPill(
                        text: _fenceTypeLabel(fence.type, l10n),
                        bg: AppColors.info.withValues(alpha: 0.1),
                        fg: AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Metadata grid 2x2
                  Row(
                    children: [
                      Expanded(
                        child: _DetailField(
                          label: l10n.alertFenceAreaLabel,
                          value: l10n.alertFenceArea(
                            fence.areaHectares.toStringAsFixed(1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailField(
                          label: l10n.alertFenceTypeLabel,
                          value: _fenceTypeLabel(fence.type, l10n),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailField(
                          label: l10n.alertFenceLivestockLabel,
                          value: l10n.alertFenceLivestockCount(
                            fence.livestockCount,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailField(
                          label: l10n.alertFenceAlertLabel,
                          value: l10n.alertFenceAlertCount(activeAlerts),
                          valueColor: activeAlerts > 0
                              ? AppColors.danger
                              : null,
                        ),
                      ),
                    ],
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 8),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _DetailBtn(
                            label: l10n.alertFenceEditBoundary,
                            icon: Icons.edit_location_alt,
                            bgColor: AppColors.info,
                            fgColor: Colors.white,
                            onTap: onEdit,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: _DetailBtn(
                            label: l10n.ranchSectionFenceAlerts,
                            icon: Icons.warning_amber,
                            bgColor: AppColors.primarySoft,
                            fgColor: AppColors.primaryDark,
                            onTap: () => context.push(
                              '${AppRoute.alerts.path}?asset=fence&fenceId=${fence.id}&source=fence',
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 14,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DetailBtn extends StatelessWidget {
  const _DetailBtn({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
