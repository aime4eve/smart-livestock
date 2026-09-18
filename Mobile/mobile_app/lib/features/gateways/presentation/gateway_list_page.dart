import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

import '../domain/gateway_models.dart';
import 'gateway_controller.dart';

/// 「我的」→ 网关位置 (NIX-219 F1, prototype screen 1).
/// Auto-discovered gateways the farm's devices actually talk to.
class GatewayListPage extends ConsumerWidget {
  const GatewayListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(gatewayListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.gatewayListTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.gatewayLoadFailed, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.read(gatewayListControllerProvider.notifier).refresh(),
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.gatewayEmptyHint,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
              ),
            );
          }
          final registered = items.where((i) => i.registered).toList();
          final unmarked = items.where((i) => !i.registered).toList();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _hintCard(l10n),
              if (unmarked.isNotEmpty) ...[
                _sectionTitle(l10n.gatewaySectionUnmarked(unmarked.length)),
                for (final item in unmarked) _GatewayCard(item: item, l10n: l10n),
              ],
              if (registered.isNotEmpty) ...[
                _sectionTitle(l10n.gatewaySectionRegistered(registered.length)),
                for (final item in registered) _GatewayCard(item: item, l10n: l10n),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.gatewayListFootnote,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.6),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hintCard(AppLocalizations l10n) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Text(
          l10n.gatewayHintCard,
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      );
}

class _GatewayCard extends StatelessWidget {
  const _GatewayCard({required this.item, required this.l10n});

  final GatewayDiscoveryItem item;
  final AppLocalizations l10n;

  Color get _tierColor => switch (item.linkTier) {
        'stable' => AppColors.success,
        'weak' => AppColors.warning,
        'edge' => AppColors.danger,
        _ => AppColors.textSecondary,
      };

  String _lastSeen(AppLocalizations l10n) {
    final t = item.lastSeen;
    if (t == null) return l10n.gatewayLastSeenUnknown;
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return l10n.gatewayLastSeenNow;
    if (diff.inMinutes < 60) return l10n.gatewayLastSeenMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.gatewayLastSeenHours(diff.inHours);
    return l10n.gatewayLastSeenDate(
        '${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.shortId,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${_lastSeen(l10n)} · ${l10n.gatewayFrames30d(item.frames)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (item.registered) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.gatewayMarkedBy(
                        item.markedAt == null
                            ? '--'
                            : '${item.markedAt!.month.toString().padLeft(2, '0')}-${item.markedAt!.day.toString().padLeft(2, '0')}'),
                    style: const TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: _tierColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(switch (item.linkTier) {
                  'stable' => l10n.linkTierStable,
                  'weak' => l10n.linkTierWeak,
                  'edge' => l10n.linkTierEdge,
                  _ => l10n.linkTierUnknown,
                }, style: const TextStyle(fontSize: 12)),
              ]),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 34,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: item.registered
                        ? AppColors.surfaceMuted
                        : AppColors.primarySoft,
                    foregroundColor: item.registered
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onPressed: item.registered
                      ? () => context.push(
                          '/mine/gateways/${Uri.encodeComponent(item.gatewayId)}',
                          extra: item)
                      : () => context.push(
                          '/mine/gateways/${Uri.encodeComponent(item.gatewayId)}',
                          extra: item),
                  child: Text(item.registered
                      ? l10n.gatewayRemarkAction
                      : l10n.gatewayMarkAction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
