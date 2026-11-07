import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/locked_overlay.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Generic scene-locked page (NIX-389): one page for every LOCKED health
/// tile, parameterised by scene key (fever/digestive/estrus/epidemic/ai/
/// calving). Reuses the LockedOverlay visual language of the estrus detail
/// locked chart (padlock + upgrade-to-tier message + CTA to subscription).
class SceneLockedPage extends StatelessWidget {
  const SceneLockedPage({super.key, required this.scene});

  /// Scene key carried in the route query (?scene=calving).
  final String scene;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = switch (scene) {
      'fever' => l10n.ranchSceneFeverMgmt,
      'digestive' => l10n.ranchSceneDigestiveMgmt,
      'estrus' => l10n.ranchSceneEstrusMgmt,
      'epidemic' => l10n.ranchSceneEpidemic,
      'ai' => l10n.aiObserveTitle,
      _ => l10n.ranchSceneCalvingMgmt,
    };
    final icon = switch (scene) {
      'fever' => Icons.thermostat,
      'digestive' => Icons.grain,
      'estrus' => Icons.favorite_outline,
      'epidemic' => Icons.shield_outlined,
      'ai' => Icons.smart_toy_outlined,
      _ => Icons.family_restroom,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sceneLockedTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: LockedOverlay(
        locked: true,
        upgradeTier: 'premium',
        onUpgrade: () => context.go(AppRoute.subscription.path),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: Center(
                  child: Icon(icon, size: 48, color: AppColors.border),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
