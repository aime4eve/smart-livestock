import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

// NIX-389: three-state health tiles. The server (ranch-overview
// sceneSummary.gating) decides OPEN/LOCKED/HIDDEN per scene; this file only
// renders the verdict — no tier or feature-flag logic lives client-side.

/// One health-management tile on the ranch overview. Same geometry for all
/// states: OPEN shows the data card, LOCKED swaps the status pill for a lock
/// pill, keeps the name and shows an upgrade foot. HIDDEN is handled by the
/// caller (the tile is dropped from the grid entirely, no empty slot).
class HealthSceneTile extends StatelessWidget {
  const HealthSceneTile({
    super.key,
    required this.icon,
    required this.color,
    required this.name,
    required this.gating,
    required this.foot,
    required this.lockedFoot,
    this.statusPill,
    this.footBold,
    this.onOpen,
    this.onLockedTap,
  });

  final IconData icon;
  final Color color;
  final String name;
  final SceneGatingState gating;

  /// OPEN-state status pill (ignored when locked).
  final Widget? statusPill;

  /// OPEN-state foot line.
  final String foot;

  /// Optional bold danger tail appended to the foot (fever/epidemic).
  final TextSpan? footBold;

  /// LOCKED-state upgrade hint.
  final String lockedFoot;

  final VoidCallback? onOpen;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    final locked = gating == SceneGatingState.locked;
    return InkWell(
      onTap: locked ? onLockedTap : onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (locked)
                  const _LockedPill()
                else if (statusPill != null)
                  statusPill!,
              ],
            ),
            const SizedBox(height: 6),
            if (!locked && footBold != null)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: foot,
                      style: const TextStyle(
                        fontSize: 9,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    footBold!,
                  ],
                ),
              )
            else
              Text(
                locked ? lockedFoot : foot,
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.3,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lock-styled status pill: grey/neutral with a small padlock, matching the
/// existing pill geometry (7/2 padding, 8.5 w700 text).
class _LockedPill extends StatelessWidget {
  const _LockedPill();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 8.5,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 2),
          Text(
            l10n.sceneTileLocked,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The standalone scene-locked page (NIX-389): parameterised by scene so a
/// single page serves all locked tiles instead of one page per scene.
void pushSceneLocked(BuildContext context, String scene) {
  context.push('${AppRoute.sceneLocked.path}?scene=$scene');
}

/// Builds the health-management tiles in the fixed
/// fever/digestive/estrus/epidemic/calving order. HIDDEN scenes are dropped
/// from the returned list entirely so the grid never leaves an empty slot.
List<Widget> buildHealthSceneTiles(
  BuildContext context, {
  required dynamic scene,
  required RanchSceneGating gating,
  required RanchSceneSummaryCalving calving,
  required int feverOver6h,
}) {
  final l10n = AppLocalizations.of(context)!;

  Widget pill(Color color, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );

  final feverN = scene.fever.abnormalCount - scene.fever.elevatedCount;
  final lowN = scene.fever.elevatedCount;
  final epiRate = (scene.epidemic.abnormalRate * 100).toStringAsFixed(1);
  final epiOver = scene.epidemic.abnormalRate >= 0.10;

  final tiles = <Widget>[];

  if (gating.fever != SceneGatingState.hidden) {
    tiles.add(
      HealthSceneTile(
        icon: Icons.thermostat,
        color: const Color(0xFFD97B29),
        name: l10n.ranchSceneFeverMgmt,
        gating: gating.fever,
        statusPill: scene.fever.abnormalCount == 0
            ? pill(AppColors.success, l10n.pillSteady)
            : pill(
                scene.fever.criticalCount > 0
                    ? AppColors.danger
                    : AppColors.warning,
                l10n.pillAbnormal(scene.fever.abnormalCount),
              ),
        foot: scene.fever.abnormalCount == 0
            ? l10n.sceneFeverCalm
            : l10n.sceneFeverFoot(feverN, lowN),
        footBold: scene.fever.abnormalCount > 0 && feverOver6h > 0
            ? TextSpan(
                text: l10n.sceneFeverFootOver(feverOver6h),
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              )
            : null,
        lockedFoot: l10n.sceneTileLockedFoot,
        onOpen: () => context.push(AppRoute.twinFever.path),
        onLockedTap: () => pushSceneLocked(context, 'fever'),
      ),
    );
  }

  if (gating.digestive != SceneGatingState.hidden) {
    tiles.add(
      HealthSceneTile(
        icon: Icons.grain,
        color: const Color(0xFF8D6E4F),
        name: l10n.ranchSceneDigestiveMgmt,
        gating: gating.digestive,
        statusPill: scene.digestive.abnormalCount == 0
            ? pill(AppColors.success, l10n.pillSteady)
            : pill(
                AppColors.warning,
                l10n.pillAbnormal(scene.digestive.abnormalCount),
              ),
        foot: scene.digestive.abnormalCount == 0
            ? l10n.sceneDigestiveCalm
            : l10n.sceneDigestiveFoot(scene.digestive.abnormalCount),
        lockedFoot: l10n.sceneTileLockedFoot,
        onOpen: () => context.push(AppRoute.twinDigestive.path),
        onLockedTap: () => pushSceneLocked(context, 'digestive'),
      ),
    );
  }

  if (gating.estrus != SceneGatingState.hidden) {
    tiles.add(
      HealthSceneTile(
        icon: Icons.favorite,
        color: AppColors.estrus,
        name: l10n.ranchSceneEstrusMgmt,
        gating: gating.estrus,
        statusPill: scene.estrus.highScoreCount == 0
            ? pill(AppColors.success, l10n.pillSteady)
            : pill(
                AppColors.estrus,
                l10n.pillHigh(scene.estrus.highScoreCount),
              ),
        foot: scene.estrus.highScoreCount == 0
            ? l10n.sceneEstrusCalm
            : l10n.sceneEstrusFoot(scene.estrus.highScoreCount),
        lockedFoot: l10n.sceneTileLockedFoot,
        onOpen: () => context.push(AppRoute.twinEstrus.path),
        onLockedTap: () => pushSceneLocked(context, 'estrus'),
      ),
    );
  }

  if (gating.epidemic != SceneGatingState.hidden) {
    tiles.add(
      HealthSceneTile(
        icon: Icons.shield,
        color: const Color(0xFF2E7D74),
        name: l10n.ranchSceneEpidemic,
        gating: gating.epidemic,
        statusPill: epiOver
            ? pill(AppColors.danger, l10n.pillRate(epiRate))
            : scene.epidemic.abnormalRate > 0
            ? pill(AppColors.warning, l10n.pillRate(epiRate))
            : pill(AppColors.success, l10n.pillSteady),
        foot: epiOver
            ? (scene.epidemic.hasMarkedSource
                  ? l10n.sceneEpidemicFootAbove(epiRate)
                  : l10n.sceneEpidemicFootNoSource(epiRate))
            : l10n.sceneEpidemicFootBelow(epiRate),
        // P7: epiOver with no marked source appends a danger bold tail
        // segment via the same two-span foot the fever card uses.
        footBold: epiOver && !scene.epidemic.hasMarkedSource
            ? TextSpan(
                text: l10n.sceneEpidemicFootNoSourceTag,
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              )
            : null,
        lockedFoot: l10n.sceneTileLockedFoot,
        onOpen: () => context.push(AppRoute.twinEpidemic.path),
        onLockedTap: () => pushSceneLocked(context, 'epidemic'),
      ),
    );
  }

  // Calving tile (NIX-389): pill shows the high-risk head count in the
  // warning colour; the foot switches between calm and count lines.
  if (gating.calving != SceneGatingState.hidden) {
    tiles.add(
      HealthSceneTile(
        icon: Icons.family_restroom,
        color: const Color(0xFF9C6BB3),
        name: l10n.ranchSceneCalvingMgmt,
        gating: gating.calving,
        statusPill: calving.highRiskCount > 0
            ? pill(AppColors.warning, l10n.pillCalvingHigh(calving.highRiskCount))
            : pill(AppColors.success, l10n.pillSteady),
        foot: calving.highRiskCount > 0
            ? l10n.sceneCalvingFoot(calving.highRiskCount)
            : l10n.sceneCalvingCalm,
        lockedFoot: l10n.sceneTileLockedFoot,
        onOpen: () => context.push(AppRoute.calvingPredictions.path),
        onLockedTap: () => pushSceneLocked(context, 'calving'),
      ),
    );
  }

  return tiles;
}

/// AI watch card (full-width row under the tile grid). Returns null when the
/// server hides the scene; LOCKED renders the same geometry with a lock pill,
/// the name kept and the whole card tappable into the scene-locked page.
Widget? buildHealthAiTile(
  BuildContext context,
  dynamic ai,
  SceneGatingState gating,
) {
  if (gating == SceneGatingState.hidden) return null;
  final l10n = AppLocalizations.of(context)!;
  final locked = gating == SceneGatingState.locked;
  final empty = ai == null || ai.anomalyCount == 0;
  final color = locked || empty
      ? AppColors.textSecondary
      : ai.avgScore >= 0.7
      ? AppColors.danger
      : ai.avgScore >= 0.3
      ? AppColors.warning
      : AppColors.success;

  final Widget pill;
  if (locked) {
    pill = const _LockedPill();
  } else if (empty) {
    pill = const SizedBox.shrink();
  } else {
    final band = ai.avgScore >= 0.7
        ? l10n.aiBandAlarm
        : ai.avgScore >= 0.3
        ? l10n.aiBandWatch
        : l10n.aiBandCalm;
    pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        band,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget aiRow() {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.smart_toy, size: 15, color: AppColors.info),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.aiObserveTitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                locked
                    ? l10n.sceneTileLockedFoot
                    : empty
                    ? l10n.aiNotReady
                    : l10n.aiSummaryWatching(ai.anomalyCount),
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!empty) pill,
      ],
    );
  }

  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: locked
        ? InkWell(
            onTap: () => pushSceneLocked(context, 'ai'),
            borderRadius: BorderRadius.circular(12),
            child: aiRow(),
          )
        : aiRow(),
  );
}
