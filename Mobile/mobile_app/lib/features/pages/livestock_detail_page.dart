import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/features/estrus/presentation/estrus_controller.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/presentation/fever_controller.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/widgets/locked_overlay.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class LivestockDetailPage extends ConsumerWidget {
  const LivestockDetailPage({super.key, required this.earTag});

  final String earTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(livestockDetailControllerProvider(earTag));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.livestockDetailTitle),
        leading: IconButton(
          key: const Key('livestock-back'),
          onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoute.twin.path);
          }
        },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        key: const Key('page-livestock-detail'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            asyncData.when(
              data: (detail) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LivestockInfoCard(detail: detail),
                  const SizedBox(height: AppSpacing.md),
                  _DeviceListCard(detail: detail),
                  const SizedBox(height: AppSpacing.md),
                  _HealthDataCard(detail: detail),
                  const SizedBox(height: AppSpacing.md),
                  _LocationCard(detail: detail),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${l10n.commonLoadFailed}: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(livestockDetailControllerProvider(earTag)
                              .notifier)
                          .refresh(),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivestockInfoCard extends StatelessWidget {
  const _LivestockInfoCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HighfiCard(
      key: const Key('livestock-info-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                detail.earTag,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: AppSpacing.sm),
              HighfiStatusChip(
                label: switch (detail.health) {
                  LivestockHealth.healthy => l10n.livestockHealthHealthy,
                  LivestockHealth.watch => l10n.livestockHealthWatch,
                  LivestockHealth.abnormal => l10n.livestockHealthAbnormal,
                },
                color: switch (detail.health) {
                  LivestockHealth.healthy => AppColors.success,
                  LivestockHealth.watch => AppColors.warning,
                  LivestockHealth.abnormal => AppColors.danger,
                },
                icon: switch (detail.health) {
                  LivestockHealth.healthy => Icons.check_circle_outline,
                  LivestockHealth.watch => Icons.visibility_outlined,
                  LivestockHealth.abnormal => Icons.warning_amber_rounded,
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoItem(label: l10n.livestockBreed, value: detail.breed),
              _InfoItem(label: l10n.livestockAgeMonthsLabel, value: l10n.livestockAgeMonthsValue(detail.ageMonths)),
              _InfoItem(label: l10n.livestockWeight, value: '${detail.weightKg} kg'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _DeviceListCard extends StatelessWidget {
  const _DeviceListCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HighfiCard(
      key: const Key('livestock-device-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.livestockBindDevices, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final device in detail.devices)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      switch (device.type) {
                        DeviceType.gps => Icons.gps_fixed,
                        DeviceType.rumenCapsule => Icons.medication,
                        DeviceType.accelerometer => Icons.speed,
                      },
                      color: switch (device.status) {
                        DeviceStatus.online => AppColors.success,
                        DeviceStatus.offline => AppColors.textSecondary,
                        DeviceStatus.lowBattery => AppColors.warning,
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            [
                              if (device.batteryPercent != null)
                                l10n.deviceBatteryValue(device.batteryPercent!),
                              if (device.signalStrength != null)
                                l10n.deviceSignalValue(device.signalStrength!),
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HealthDataCard extends ConsumerWidget {
  const _HealthDataCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subAsync = ref.watch(subscriptionControllerProvider);
    final tier = subAsync.value?.tier ?? SubscriptionTier.basic;

    return HighfiCard(
      key: const Key('livestock-health-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.livestockHealthData, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _InfoItem(label: l10n.livestockBodyTemp, value: '${detail.bodyTemp.toStringAsFixed(1)}°C'),
              _InfoItem(label: l10n.livestockActivity, value: detail.activityLevel),
              _InfoItem(
                label: l10n.livestockRumination,
                value: double.tryParse(detail.ruminationFreq) != null
                    ? l10n.livestockRuminationValue(detail.ruminationFreq)
                    : detail.ruminationFreq,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // ── Inline: temperature trend chart ──
          _FeverTrendSection(livestockId: detail.livestockId),
          const SizedBox(height: AppSpacing.md),
          // ── Inline: estrus score trend chart (Premium+) ──
          _EstrusTrendSection(livestockId: detail.livestockId, tier: tier),
        ],
      ),
    );
  }
}

class _FeverTrendSection extends ConsumerWidget {
  const _FeverTrendSection({required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncFever = ref.watch(feverDetailControllerProvider(livestockId));

    return asyncFever.when(
      loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 180, child: Center(child: Text(l10n.feverLoadFailed))),
      data: (fever) {
        final readings = fever.recent72h;
        if (readings.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(child: Text(l10n.feverNoRecords, style: Theme.of(context).textTheme.bodySmall)),
          );
        }
        final spots = readings.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.temperature)).toList();
        final minTemp = readings.map((r) => r.temperature).reduce((a, b) => a < b ? a : b) - 0.3;
        final maxTemp = readings.map((r) => r.temperature).reduce((a, b) => a > b ? a : b) + 0.3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.feverDetailChartTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(height: 160, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)), child: LineChart(LineChartData(
              minY: minTemp,
              maxY: maxTemp,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 10)))),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(spots: spots, isCurved: true, color: AppColors.danger, barWidth: 2, dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.danger.withValues(alpha: 0.3), AppColors.danger.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                LineChartBarData(spots: [FlSpot(0, fever.baselineTemp), FlSpot((readings.length - 1).toDouble(), fever.baselineTemp)], color: AppColors.textSecondary.withValues(alpha: 0.4), dashArray: const [4, 4], barWidth: 1, dotData: const FlDotData(show: false)),
              ],
            ))),
            const SizedBox(height: 6),
            Row(children: [
              _chartLegend(AppColors.danger, l10n.feverLegendActual),
              const SizedBox(width: 12),
              _chartLegend(AppColors.textSecondary.withValues(alpha: 0.4), l10n.feverLegendBaseline),
            ]),
          ],
        );
      },
    );
  }
}

class _EstrusTrendSection extends ConsumerWidget {
  const _EstrusTrendSection({required this.livestockId, required this.tier});
  final String livestockId;
  final SubscriptionTier tier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasEstrusDetect = checkTierAccess(tier, FeatureFlags.estrusDetect);

    if (!hasEstrusDetect) {
      return LockedOverlay(
        locked: true,
        upgradeTier: 'premium',
        onUpgrade: () => context.go(AppRoute.subscription.path),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💕 ${l10n.estrusDetailChartTitle}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const SizedBox(height: 160, child: Center(child: Icon(Icons.favorite_outline, size: 40, color: AppColors.border))),
            ],
          ),
        ),
      );
    }

    final asyncEstrus = ref.watch(estrusDetailControllerProvider(livestockId));

    return asyncEstrus.when(
      loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 180, child: Center(child: Text(l10n.estrusLoadFailed))),
      data: (estrus) {
        final trend = estrus.trend7d;
        if (trend.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(child: Text(l10n.estrusNoScores, style: Theme.of(context).textTheme.bodySmall)),
          );
        }
        final spots = trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.score)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.estrusDetailChartTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(height: 160, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)), child: LineChart(LineChartData(
              minY: 0,
              maxY: 100,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(y: 70, color: AppColors.warning.withValues(alpha: 0.5), dashArray: const [4, 4]),
              ]),
              lineBarsData: [
                LineChartBarData(spots: spots, isCurved: true, color: AppColors.estrus, barWidth: 2, dotData: const FlDotData(show: true)),
              ],
            ))),
            const SizedBox(height: 6),
            Row(children: [
              _chartLegend(AppColors.estrus, l10n.estrusLegendScore),
              const SizedBox(width: 12),
              _chartLegend(AppColors.warning.withValues(alpha: 0.5), l10n.estrusLegendThreshold),
            ]),
          ],
        );
      },
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.detail});

  final LivestockDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HighfiCard(
      key: const Key('livestock-location-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.livestockLocation, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.livestockLastLocation(detail.lastLocation),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: const Key('livestock-view-track'),
            onPressed: () => context.go(AppRoute.fence.path),
            icon: const Icon(Icons.map_outlined),
            label: Text(l10n.livestockViewTrajectory),
          ),
        ],
      ),
    );
  }
}

Widget _chartLegend(Color color, String label) {
  return Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
  ]);
}
