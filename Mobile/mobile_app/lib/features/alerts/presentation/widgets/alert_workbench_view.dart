import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alert_workbench.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class AlertWorkbenchView extends StatelessWidget {
  const AlertWorkbenchView({
    super.key,
    required this.data,
    required this.selectedBucket,
    required this.selectedAsset,
    required this.onBucket,
    required this.onAsset,
    required this.onItem,
    required this.onLoadMore,
    required this.onRanking,
    this.compact = false,
    this.loadingMore = false,
    this.batchMode = false,
    this.selectedAlertIds = const {},
    this.onToggleSelection,
    this.source,
  });

  final AlertWorkbenchData data;
  final String selectedBucket;
  final Set<String> selectedAsset;
  final ValueChanged<String> onBucket;
  final ValueChanged<Set<String>> onAsset;
  final ValueChanged<WorkbenchItem> onItem;
  final VoidCallback onLoadMore;
  final VoidCallback onRanking;
  final bool compact;
  final bool loadingMore;
  final bool batchMode;
  final Set<String> selectedAlertIds;
  final ValueChanged<String>? onToggleSelection;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildContext(l10n)),
        SliverToBoxAdapter(child: _buildTiles(l10n)),
        SliverToBoxAdapter(child: _buildAssetChips(l10n)),
        if (compact) ..._compactLists(l10n) else ..._fullList(l10n),
        SliverToBoxAdapter(child: _buildAiStrip(l10n)),
        SliverToBoxAdapter(child: _buildFooter(l10n)),
      ],
    );
  }

  Widget _buildContext(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            _contextNode(
              l10n.workbenchContextOverview,
              active: source != 'fence',
            ),
            _arrow(),
            _contextNode(l10n.workbenchContextFence, active: source == 'fence'),
            _arrow(),
            _contextNode(
              l10n.workbenchContextAlert,
              active: true,
              current: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _contextNode(
    String label, {
    required bool active,
    bool current = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: current
          ? BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: active
              ? AppColors.primaryDark
              : AppColors.primaryDark.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _arrow() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Text(
      '→',
      style: TextStyle(
        fontSize: 7,
        color: AppColors.primaryDark.withValues(alpha: 0.5),
      ),
    ),
  );

  Widget _buildTiles(AppLocalizations l10n) {
    final definitions = [
      _TileSpec(
        key: 'immediate',
        label: l10n.workbenchImmediate,
        sub: l10n.workbenchImmediateSub,
        count: data.summary.immediate,
        unread: data.summary.unreadFor('immediate'),
        background: const LinearGradient(
          colors: [Color(0xFFB3453B), Color(0xFFC9664F)],
        ),
        foreground: Colors.white,
      ),
      _TileSpec(
        key: 'field',
        label: l10n.workbenchField,
        sub: l10n.workbenchFieldSub,
        count: data.summary.field,
        unread: data.summary.unreadFor('field'),
        background: const LinearGradient(
          colors: [Color(0xFFC07A22), Color(0xFFDB9C40)],
        ),
        foreground: Colors.white,
      ),
      _TileSpec(
        key: 'observe',
        label: l10n.workbenchObserve,
        sub: l10n.workbenchObserveSub,
        count: data.summary.observe,
        unread: data.summary.unreadFor('observe'),
        foreground: AppColors.textPrimary,
      ),
      _TileSpec(
        key: 'resolved',
        label: l10n.workbenchResolved,
        sub: l10n.workbenchResolvedSub,
        count: data.summary.resolved,
        foreground: AppColors.textPrimary,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: 2.55,
      children: [
        for (final spec in definitions)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onBucket(spec.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  gradient: spec.background,
                  color: spec.background == null ? AppColors.surfaceAlt : null,
                  borderRadius: BorderRadius.circular(12),
                  border: spec.background == null
                      ? Border.all(
                          color: spec.key == 'observe'
                              ? AppColors.info.withValues(alpha: 0.28)
                              : AppColors.border,
                        )
                      : null,
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(38, 49, 38, 0.06),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(38, 49, 38, 0.04),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spec.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: spec.foreground.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${spec.count}',
                          style: TextStyle(
                            fontSize: 22,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            color: spec.key == 'observe'
                                ? AppColors.info
                                : spec.key == 'resolved'
                                ? AppColors.success
                                : spec.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spec.sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: spec.key == 'observe'
                                ? AppColors.textSecondary
                                : spec.key == 'resolved'
                                ? AppColors.textSecondary
                                : spec.foreground.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                    if (spec.unread > 0 && spec.key != 'resolved')
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 15,
                            minHeight: 15,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: spec.background != null
                                ? AppColors.surfaceAlt
                                : AppColors.danger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${spec.unread}',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: spec.background != null
                                  ? AppColors.danger
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssetChips(AppLocalizations l10n) {
    final values = {
      'all': l10n.workbenchAllAssets,
      'livestock': l10n.workbenchLivestock,
      'herd': l10n.workbenchHerd,
      'fence': l10n.workbenchFence,
      'device': l10n.workbenchDevice,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 9),
      child: SizedBox(
        height: 26,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 5),
          itemBuilder: (context, index) => _chip(
            values.values.elementAt(index),
            selected: selectedAsset.contains(values.keys.elementAt(index)),
            onTap: () => onAsset({values.keys.elementAt(index)}),
          ),
        ),
      ),
    );
  }

  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _compactLists(AppLocalizations l10n) {
    final widgets = <Widget>[];
    for (final bucket in ['immediate', 'field', 'observe']) {
      final items = data.items
          .where((item) => item.bucket == bucket)
          .take(3)
          .toList();
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 9, bottom: 5),
            child: Text(
              _bucketLabel(l10n, bucket),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
      widgets.addAll(_cards(items));
    }
    return widgets;
  }

  List<Widget> _fullList(AppLocalizations l10n) {
    return _cards(data.items);
  }

  List<Widget> _cards(List<WorkbenchItem> items) {
    return [
      SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) =>
            _card(items[index], AppLocalizations.of(context)!),
      ),
    ];
  }

  Widget _card(WorkbenchItem item, AppLocalizations l10n) {
    final (spine, iconBg, iconFg) = _colors(item);
    final selected = selectedAlertIds.contains(item.id);
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (batchMode) {
            onToggleSelection?.call(item.id);
          } else {
            onItem(item);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(38, 49, 38, 0.05),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: spine),
                if (batchMode)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(_icon(item), size: 14, color: iconFg),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (item.unread)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.asset.name} · ${_time(item.occurredAt)}'
                          '${item.unread ? ' · ${l10n.workbenchUnread}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4,
                          runSpacing: 3,
                          children: [
                            _tag(
                              _bucketLabel(l10n, item.bucket),
                              _bucketColor(item.bucket),
                            ),
                            _tag(
                              _assetLabel(l10n, item.asset.kind),
                              AppColors.primary,
                            ),
                            if (item.reasons.isNotEmpty)
                              _tag(
                                '${l10n.workbenchEvidence} ${item.reasons.length}',
                                AppColors.textSecondary,
                              ),
                            if (item.ai != null && item.ai!.band != 'calm')
                              _tag(
                                '${l10n.aiObserveTitle} · ${_aiLabel(l10n, item.ai!.band)}',
                                AppColors.info,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAiStrip(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onRanking,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.psychology_alt,
                    size: 14,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.workbenchAiRanking,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    if (compact) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          if (data.canLoadMore)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: loadingMore ? null : onLoadMore,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: loadingMore
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.workbenchLoadMore,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 5),
          Text(
            l10n.workbenchShownOf(data.items.length, data.total),
            style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _bucketLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'immediate' => l10n.workbenchImmediate,
      'field' => l10n.workbenchField,
      'observe' => l10n.workbenchObserve,
      'resolved' => l10n.workbenchResolved,
      _ => l10n.workbenchAllBuckets,
    };
  }

  String _assetLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'livestock' => l10n.workbenchLivestock,
      'herd' => l10n.workbenchHerd,
      'fence' => l10n.workbenchFence,
      'device' => l10n.workbenchDevice,
      _ => l10n.workbenchAllAssets,
    };
  }

  String _aiLabel(AppLocalizations l10n, String band) {
    return switch (band) {
      'alarm' => l10n.aiBandAlarm,
      'watch' => l10n.aiBandWatch,
      _ => l10n.aiBandCalm,
    };
  }

  Color _bucketColor(String bucket) {
    return switch (bucket) {
      'immediate' => AppColors.danger,
      'field' => AppColors.warning,
      'observe' => AppColors.info,
      _ => AppColors.success,
    };
  }

  (Color, Color, Color) _colors(WorkbenchItem item) {
    final color = _bucketColor(item.bucket);
    return (color, color.withValues(alpha: 0.11), color);
  }

  IconData _icon(WorkbenchItem item) {
    if (item.asset.kind == 'fence') return Icons.fence;
    if (item.asset.kind == 'device') return Icons.sensors;
    if (item.asset.kind == 'herd') return Icons.shield_outlined;
    if (item.ai != null && item.ai!.band != 'calm') return Icons.psychology;
    if (item.bucket == 'resolved') return Icons.check_circle_outline;
    return Icons.pets;
  }

  String _time(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    return '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _TileSpec {
  const _TileSpec({
    required this.key,
    required this.label,
    required this.sub,
    required this.count,
    required this.foreground,
    this.unread = 0,
    this.background,
  });

  final String key;
  final String label;
  final String sub;
  final int count;
  final int unread;
  final Color foreground;
  final LinearGradient? background;
}

Future<void> showAiRankingSheet(
  BuildContext context,
  List<WorkbenchItem> items,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AiRankingSheet(items: items),
  );
}

class _AiRankingSheet extends StatelessWidget {
  const _AiRankingSheet({required this.items});

  final List<WorkbenchItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ranked = items.where((item) => item.ai != null).toList()
      ..sort((a, b) => b.ai!.score.compareTo(a.ai!.score));
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 3,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_alt,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.workbenchAiRanking,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (ranked.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.aiNotReady,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: ranked.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = ranked[index];
                  return Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.asset.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (item.title.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.infoSoft,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            item.ai!.band == 'alarm'
                                ? l10n.aiBandAlarm
                                : item.ai!.band == 'watch'
                                ? l10n.aiBandWatch
                                : l10n.aiBandCalm,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

String workbenchTargetRoute(WorkbenchItem item) {
  return switch (item.asset.kind) {
    'fence' => AppRoute.ranch.path,
    'device' => AppRoute.devices.path,
    'livestock' => '/livestock/${item.asset.id}?section=health',
    _ => AppRoute.ranch.path,
  };
}
