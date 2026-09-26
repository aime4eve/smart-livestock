import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/utils/app_time.dart';
import 'package:hkt_livestock_agentic/features/epidemic/presentation/epidemic_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

enum EpidemicWorkbenchView { disposition, records, network }

class EpidemicWorkbenchPage extends ConsumerStatefulWidget {
  const EpidemicWorkbenchPage({
    super.key,
    this.sourceLivestockId,
    this.initialView = EpidemicWorkbenchView.disposition,
  });

  final String? sourceLivestockId;
  final EpidemicWorkbenchView initialView;

  @override
  ConsumerState<EpidemicWorkbenchPage> createState() =>
      _EpidemicWorkbenchPageState();
}

class _EpidemicWorkbenchPageState extends ConsumerState<EpidemicWorkbenchPage> {
  late EpidemicWorkbenchView view;
  final Set<int> expandedEvidence = {};

  @override
  void initState() {
    super.initState();
    view = widget.initialView;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.sourceLivestockId?.isNotEmpty == true) {
        ref.read(epidemicWorkbenchControllerProvider.notifier).setSource(
              widget.sourceLivestockId,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tier = ref.watch(subscriptionControllerProvider).value?.tier ??
        SubscriptionTier.basic;
    final unlocked = checkTierAccess(tier, FeatureFlags.epidemicAlert);
    final async = ref.watch(epidemicWorkbenchControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          children: [
            Text(l10n.epidemicTitle),
            if (async.value != null)
              Text(
                l10n.epidemicWorkbenchSynced(
                  async.value!.context.windowHours,
                  formatHm(async.value!.context.syncedAt),
                ),
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
      body: !unlocked
          ? _LockedState(l10n: l10n)
          : async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: '${l10n.commonLoadFailed}: $error',
                onRetry: () =>
                    ref.read(epidemicWorkbenchControllerProvider.notifier).refresh(),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(epidemicWorkbenchControllerProvider.notifier).refresh(),
                child: Column(
                  children: [
                    _ModeTabs(
                      selected: view,
                      onChanged: (value) => setState(() => view = value),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                        children: [
                          _SourceSummary(data: data),
                          const SizedBox(height: 16),
                          if (view == EpidemicWorkbenchView.disposition)
                            _DispositionView(
                              data: data,
                              expanded: expandedEvidence,
                              onToggle: (id) => setState(() {
                                expandedEvidence.contains(id)
                                    ? expandedEvidence.remove(id)
                                    : expandedEvidence.add(id);
                              }),
                              onOpenNetwork: () => setState(
                                  () => view = EpidemicWorkbenchView.network),
                              onMark: (item) => ref
                                  .read(epidemicWorkbenchControllerProvider.notifier)
                                  .markDisposition(item),
                            ),
                          if (view == EpidemicWorkbenchView.records)
                            _RecordsView(
                              data: data,
                              onWindowChanged: (hours) => ref
                                  .read(epidemicWorkbenchControllerProvider.notifier)
                                  .setWindowHours(hours),
                              onOpenDisposition: () => setState(
                                  () => view = EpidemicWorkbenchView.disposition),
                            ),
                          if (view == EpidemicWorkbenchView.network)
                            _NetworkView(data: data),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: !unlocked || !async.hasValue
          ? null
          : _BottomBar(
              data: async.value!,
              isReportView: view == EpidemicWorkbenchView.network,
              onWindowChanged: (hours) => ref
                  .read(epidemicWorkbenchControllerProvider.notifier)
                  .setWindowHours(hours),
            ),
    );
  }
}

class _LockedState extends StatelessWidget {
  const _LockedState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(l10n.epidemicContactLockedMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoute.subscription.path),
              child: Text(l10n.epidemicContactUpgrade),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.selected, required this.onChanged});
  final EpidemicWorkbenchView selected;
  final ValueChanged<EpidemicWorkbenchView> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Color(0xFFEDF1EA),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _tab(l10n.epidemicTabDisposition, Icons.fact_check_outlined,
              EpidemicWorkbenchView.disposition),
          _tab(l10n.epidemicTabRecords, Icons.filter_list,
              EpidemicWorkbenchView.records),
          _tab(l10n.epidemicTabNetwork, Icons.account_tree_outlined,
              EpidemicWorkbenchView.network),
        ],
      ),
    );
  }

  Widget _tab(String label, IconData icon, EpidemicWorkbenchView value) {
    final active = selected == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: active ? AppColors.surfaceAlt : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged(value),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 16,
                      color: active ? AppColors.primaryDark : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
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

class _SourceSummary extends StatelessWidget {
  const _SourceSummary({required this.data});
  final EpidemicWorkbenchData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contextData = data.context;
    final critical = data.tiers
        .where((item) => item.key == 'CRITICAL')
        .fold<int>(0, (sum, item) => sum + item.count);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [AppColors.danger.withValues(alpha: .14), AppColors.danger.withValues(alpha: .04)],
        ),
        border: Border.all(color: AppColors.danger.withValues(alpha: .18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emergency, color: AppColors.dangerStrong),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.epidemicSuspectedSource} ${contextData.source.livestockCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.dangerStrong,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${contextData.source.diseaseType ?? l10n.epidemicNotMarked} · ${formatMdhm(contextData.source.markedAt ?? contextData.generatedAt)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summary(
                l10n.epidemicContactLivestockCount,
                data.network.nodes.where((node) => node.kind == 'CONTACT').length,
              ),
              const SizedBox(width: 8),
              _summary(l10n.epidemicCriticalDispositionCount, critical),
              const SizedBox(width: 8),
              _summary(
                l10n.epidemicMostRecentContact,
                contextData.lastContactAgeMinutes ?? -1,
                unit: l10n.epidemicMinutesShort,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(String label, int value, {String? unit}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .84),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              value < 0 ? '--' : '$value${unit ?? ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _DispositionView extends StatelessWidget {
  const _DispositionView({
    required this.data,
    required this.expanded,
    required this.onToggle,
    required this.onOpenNetwork,
    required this.onMark,
  });

  final EpidemicWorkbenchData data;
  final Set<int> expanded;
  final ValueChanged<int> onToggle;
  final VoidCallback onOpenNetwork;
  final ValueChanged<EpidemicLivestockItem> onMark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(l10n.epidemicDispositionQueueTitle, l10n.epidemicTierSortHint),
        const SizedBox(height: 8),
        _TierGrid(tiers: data.tiers),
        const SizedBox(height: 12),
        for (var rank = 1; rank <= 4; rank++)
          ..._tierGroup(context, rank),
      ],
    );
  }

  List<Widget> _tierGroup(BuildContext context, int rank) {
    final l10n = AppLocalizations.of(context)!;
    final items = data.livestock.where((item) => item.rank == rank).toList();
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                switch (rank) {
                  1 => l10n.epidemicTierCritical,
                  2 => l10n.epidemicTierObservation,
                  3 => l10n.epidemicTierTracking,
                  _ => l10n.epidemicTierArchive,
                },
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            Text('${items.length}${l10n.epidemicHeadSuffix}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      for (final item in items)
        _LivestockCard(
          item: item,
          expanded: expanded.contains(item.maxRiskScore + item.livestockCode.hashCode),
          onToggle: () => onToggle(item.maxRiskScore + item.livestockCode.hashCode),
          onOpenNetwork: onOpenNetwork,
          onMark: () => onMark(item),
        ),
    ];
  }
}

class _TierGrid extends StatelessWidget {
  const _TierGrid({required this.tiers});
  final List<EpidemicTierSummary> tiers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final names = {
      'CRITICAL': l10n.epidemicTierCritical,
      'OBSERVATION': l10n.epidemicTierObservation,
      'TRACKING': l10n.epidemicTierTracking,
      'ARCHIVE': l10n.epidemicTierArchive,
    };
    final actions = {
      'CRITICAL': l10n.epidemicTierCriticalAction,
      'OBSERVATION': l10n.epidemicTierObservationAction,
      'TRACKING': l10n.epidemicTierTrackingAction,
      'ARCHIVE': l10n.epidemicTierArchiveAction,
    };
    final colors = {
      'CRITICAL': AppColors.danger,
      'OBSERVATION': AppColors.warning,
      'TRACKING': AppColors.info,
      'ARCHIVE': AppColors.success,
    };
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 52,
      ),
      children: tiers.map((tier) {
        final color = colors[tier.key] ?? AppColors.success;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: const [
              BoxShadow(color: Color(0x0F263126), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(names[tier.key] ?? tier.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.15)),
                  ),
                  Text('${tier.count}${l10n.epidemicHeadSuffix}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.15)),
                ],
              ),
              const SizedBox(height: 2),
              Text(actions[tier.key] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      height: 1.15)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LivestockCard extends StatelessWidget {
  const _LivestockCard({
    required this.item,
    required this.expanded,
    required this.onToggle,
    required this.onOpenNetwork,
    required this.onMark,
  });

  final EpidemicLivestockItem item;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpenNetwork;
  final VoidCallback onMark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = item.rank == 1 ? AppColors.danger : AppColors.warning;
    final primarySoft = item.rank == 1 ? AppColors.dangerSoft : AppColors.warningSoft;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: primary, width: 4)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F263126), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_shortCode(item.livestockCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.epidemicLivestockLabel} ${item.livestockCode}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        item.fenceName?.isNotEmpty == true
                            ? '${item.fenceName} · ${_lastSeen(l10n)}'
                            : _lastSeen(l10n),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(color: primarySoft, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    switch (item.rank) {
                      1 => l10n.epidemicTierCritical,
                      2 => l10n.epidemicTierObservation,
                      3 => l10n.epidemicTierTracking,
                      _ => l10n.epidemicTierArchive,
                    },
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _metric(l10n.epidemicContactCattle, '${item.directContactCount}'),
                const SizedBox(width: 8),
                _metric(l10n.epidemicMaxRisk, '${item.maxRiskScore}'),
                const SizedBox(width: 8),
                _metric(l10n.epidemicTemperature,
                    item.health.currentTemp?.toStringAsFixed(1) ?? '--'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.dueAt == null
                  ? actionLabel(l10n)
                  : '${actionLabel(l10n)} · ${formatMdhm(item.dueAt!)}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary),
            ),
          ),
          if (item.eventIds.isNotEmpty)
            InkWell(
              onTap: onToggle,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        expanded
                            ? l10n.epidemicHideEvidence
                            : l10n.epidemicShowEvidence(item.eventIds.length),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark),
                      ),
                    ),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18, color: AppColors.primaryDark),
                  ],
                ),
              ),
            ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                item.reasonCodes.map((code) => _reasonLabel(l10n, code)).join(' · '),
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenNetwork,
                    icon: const Icon(Icons.account_tree_outlined, size: 16),
                    label: Text(l10n.epidemicContactNetworkAction),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: item.actionStatus == 'COMPLETED' ? null : onMark,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(actionLabel(l10n)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String actionLabel(AppLocalizations l10n) => switch (item.recommendedAction) {
        'ISOLATE_NOTIFY_VET' => l10n.epidemicActionIsolateVet,
        'IMMEDIATE_VET_CHECK' => l10n.epidemicActionImmediateCheck,
        'HEALTH_RECHECK' => l10n.epidemicActionMarkObservation,
        'CONTINUE_TRACING' => l10n.epidemicActionContinueTracing,
        _ => l10n.epidemicActionArchive,
      };

  String _lastSeen(AppLocalizations l10n) {
    final minutes = item.lastContactAgeMinutes;
    return minutes == null ? '--' : l10n.epidemicLastSeenMinutes(minutes);
  }

  String _reasonLabel(AppLocalizations l10n, String code) => switch (code) {
        'DIRECT_SOURCE' => l10n.epidemicReasonDirectSource,
        'PATH_EXPOSURE' => l10n.epidemicReasonPathExposure,
        'HEALTH_ABNORMAL' => l10n.epidemicReasonHealthAbnormal,
        'FRESH' => l10n.epidemicFactorFresh,
        'RECENT' => l10n.epidemicFactorRecent,
        'NEAR' => l10n.epidemicFactorNear,
        'MODERATE_DISTANCE' => l10n.epidemicFactorModerateDistance,
        'LONG_DURATION' => l10n.epidemicFactorLongDuration,
        'MEDIUM_DURATION' => l10n.epidemicFactorMediumDuration,
        _ => code,
  };

  String _shortCode(String code) {
    final parts = code.split('-');
    return parts.length > 1 ? parts.last : code;
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _RecordsView extends StatelessWidget {
  const _RecordsView({required this.data, required this.onWindowChanged, required this.onOpenDisposition});
  final EpidemicWorkbenchData data;
  final ValueChanged<int> onWindowChanged;
  final VoidCallback onOpenDisposition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final high = data.events.where((event) => event.riskScore >= 70).length;
    final medium = data.events.where((event) => event.riskScore >= 40 && event.riskScore < 70).length;
    final low = data.events.where((event) => event.riskScore < 40).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(l10n.epidemicRecordTriageTitle, l10n.epidemicRiskSortHint),
        const SizedBox(height: 8),
        Row(
          children: [
            _countCard(AppColors.danger, l10n.riskHigh, high),
            const SizedBox(width: 8),
            _countCard(AppColors.warning, l10n.riskMedium, medium),
            const SizedBox(width: 8),
            _countCard(AppColors.success, l10n.riskLow, low),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final hours in const [24, 48, 72, 0])
              ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: Text(hours == 0 ? l10n.epidemicWindowAll : l10n.epidemicWindowHours(hours)),
                selected: data.context.windowHours == hours,
                onSelected: (_) => onWindowChanged(hours),
              ),
          ],
        ),
        const SizedBox(height: 16),
        for (final event in data.events)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(
                  color: event.riskScore >= 70
                      ? AppColors.danger
                      : event.riskScore >= 40
                          ? AppColors.warning
                          : AppColors.success,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${event.from.livestockCode} ↔ ${event.to.livestockCode}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.riskScore >= 70
                            ? AppColors.dangerSoft
                            : event.riskScore >= 40
                                ? AppColors.warningSoft
                                : AppColors.successSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${event.riskScore}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.epidemicDistance}: ${event.proximityMeters.toStringAsFixed(1)}m · '
                  '${l10n.epidemicDuration}: ${event.durationMinutes}min · '
                  '${formatMdhm(event.lastContactAt)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(event.factorCodes.map((code) => _factorLabel(l10n, code)).join(' · '),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                TextButton(
                  onPressed: onOpenDisposition,
                  child: Text(l10n.epidemicDispositionByLivestock),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _countCard(Color color, String label, int count) {
    return Expanded(
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(radius: 3.5, backgroundColor: color),
              const SizedBox(width: 5),
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
            ]),
            const SizedBox(height: 5),
            Text('$count', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  String _factorLabel(AppLocalizations l10n, String code) => switch (code) {
        'FRESH' => l10n.epidemicFactorFresh,
        'RECENT' => l10n.epidemicFactorRecent,
        'NEAR' => l10n.epidemicFactorNear,
        'MODERATE_DISTANCE' => l10n.epidemicFactorModerateDistance,
        'LONG_DURATION' => l10n.epidemicFactorLongDuration,
        'MEDIUM_DURATION' => l10n.epidemicFactorMediumDuration,
        _ => code,
      };
}

class _NetworkView extends StatelessWidget {
  const _NetworkView({required this.data});
  final EpidemicWorkbenchData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(l10n.epidemicFirstLayer, l10n.epidemicTapNodeHint),
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _NetworkPainter(data.network, sourceLabel: l10n.epidemicSuspectedSource),
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeading(l10n.epidemicHighRiskPaths, l10n.epidemicSpreadHint),
        for (final path in data.network.paths.where((path) => path.riskScore >= 70))
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: const Border(left: BorderSide(color: AppColors.danger, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(path.livestockIds.join(' → '),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${l10n.epidemicCumulativeRisk}: ${path.riskScore}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
      ],
    );
  }
}

class _NetworkPainter extends CustomPainter {
  const _NetworkPainter(this.network, {required this.sourceLabel});
  final EpidemicNetworkData network;
  final String sourceLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <String, Offset>{};
    final source = network.nodes.where((node) => node.kind == 'SOURCE').toList();
    final contacts = network.nodes.where((node) => node.kind == 'CONTACT').toList();
    final center = Offset(size.width / 2, size.height / 2);
    if (source.isNotEmpty) positions[source.first.livestockId] = center;
    for (var index = 0; index < contacts.length; index++) {
      final angle = -math.pi / 2 + (2 * math.pi * index / contacts.length);
      final radius = math.min(size.width * .34, size.height * .34);
      positions[contacts[index].livestockId] =
          center + Offset(radius * math.cos(angle), radius * math.sin(angle));
    }

    final edgePaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.danger.withValues(alpha: .65);
    for (final edge in network.edges) {
      final from = positions[edge.fromLivestockId];
      final to = positions[edge.toLivestockId];
      if (from != null && to != null) canvas.drawLine(from, to, edgePaint);
    }

    positions.forEach((id, offset) {
      final node = network.nodes.firstWhere(
        (value) => value.livestockId == id,
        orElse: () => EpidemicGraphNode(livestockId: id, livestockCode: '?', kind: 'CONTACT'),
      );
      final isSource = node.kind == 'SOURCE';
      final radius = isSource ? 26.0 : 20.0;
      canvas.drawCircle(offset, radius, Paint()..color = AppColors.danger);
      _text(canvas, _shortCode(node.livestockCode), offset, isSource ? 15 : 13, Colors.white);
      _text(
        canvas,
        isSource ? sourceLabel : node.dispositionTier ?? '',
        offset + Offset(0, radius + 11),
        10,
        AppColors.textSecondary,
      );
    });
  }

  void _text(Canvas canvas, String value, Offset offset, double size, Color color) {
    if (value.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(text: value, style: TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) => oldDelegate.network != network;

  String _shortCode(String code) {
    final parts = code.split('-');
    return parts.length > 1 ? parts.last : code;
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.data,
    required this.isReportView,
    required this.onWindowChanged,
  });

  final EpidemicWorkbenchData data;
  final bool isReportView;
  final ValueChanged<int> onWindowChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showFilter(context),
                icon: const Icon(Icons.filter_list),
                label: Text(l10n.epidemicFilter),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showReport(context),
                icon: const Icon(Icons.description_outlined),
                label: Text(isReportView
                    ? l10n.epidemicInvestigationReport
                    : l10n.epidemicEmergencyReport),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilter(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: [
              for (final hours in const [24, 48, 72, 0])
                ChoiceChip(
                  label: Text(hours == 0
                      ? AppLocalizations.of(context)!.epidemicWindowAll
                      : AppLocalizations.of(context)!.epidemicWindowHours(hours)),
                  selected: data.context.windowHours == hours,
                  onSelected: (_) {
                    onWindowChanged(hours);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReport(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final source = data.context.source;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.epidemicEmergencyReport),
        content: Text(
          '${l10n.epidemicSuspectedSource} ${source.livestockCode}\n'
          '${source.diseaseType ?? l10n.epidemicNotMarked}\n'
          '${l10n.epidemicContactLivestockCount}: ${data.livestock.length}\n'
          '${l10n.epidemicCriticalDispositionCount}: ${data.tiers.firstWhere(
                (tier) => tier.key == 'CRITICAL',
                orElse: () => const EpidemicTierSummary(key: 'CRITICAL', rank: 1, count: 0),
              ).count}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}

Widget _sectionHeading(String title, String hint) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
      Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ],
  );
}
