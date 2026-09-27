import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class LivestockSignalSummary extends StatefulWidget {
  const LivestockSignalSummary({super.key, required this.signal});

  final LivestockSignal signal;

  @override
  State<LivestockSignalSummary> createState() => _LivestockSignalSummaryState();
}

class _LivestockSignalSummaryState extends State<LivestockSignalSummary> {
  Timer? _freshnessTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _freshnessTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signal = widget.signal;
    final l10n = AppLocalizations.of(context)!;
    final badges = _badges(l10n, signal);
    final visibleBadges = badges.take(2).toList();
    final hiddenCount = badges.length - visibleBadges.length;

    return Padding(
      key: const Key('livestock-signal-summary'),
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ...visibleBadges,
              if (hiddenCount > 0)
                _SignalBadge(
                  key: const Key('livestock-signal-more'),
                  label: l10n.livestockSignalMoreCount(hiddenCount),
                  icon: Icons.more_horiz,
                  color: AppColors.textSecondary,
                  background: AppColors.surfaceMuted,
                ),
            ],
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MetricChip(
                key: const Key('livestock-signal-rumen-temp'),
                icon: Icons.thermostat,
                label: l10n.livestockMetricRumenTemperature,
                value: _temperatureValue(l10n, signal),
                freshness: signal.health.metrics.rumenTemperature
                    .effectiveFreshness(_now),
              ),
              _MetricChip(
                key: const Key('livestock-signal-rumen-motility'),
                icon: Icons.monitor_heart_outlined,
                label: l10n.livestockMetricRumenMotility,
                value: _motilityValue(l10n, signal),
                freshness: signal.health.metrics.rumenMotility
                    .effectiveFreshness(_now),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _badges(AppLocalizations l10n, LivestockSignal signal) {
    final widgets = <Widget>[];
    final health = signal.health.status;
    if (health == 'CRITICAL') {
      widgets.add(
        _SignalBadge(
          key: const Key('livestock-signal-health'),
          label: l10n.livestockSignalHealthCritical,
          icon: Icons.emergency,
          color: AppColors.dangerStrong,
          background: AppColors.dangerSoft,
        ),
      );
    }
    if (signal.fence.status == 'BREACH') {
      widgets.add(
        _SignalBadge(
          key: const Key('livestock-signal-fence'),
          label: l10n.livestockSignalFenceBreach,
          icon: Icons.fence,
          color: AppColors.dangerStrong,
          background: AppColors.dangerSoft,
        ),
      );
    } else if (signal.fence.status == 'APPROACH') {
      widgets.add(
        _SignalBadge(
          key: const Key('livestock-signal-fence'),
          label: l10n.livestockSignalFenceApproach,
          icon: Icons.fence,
          color: AppColors.warningStrong,
          background: AppColors.warningSoft,
        ),
      );
    }
    if (signal.device.status == 'OFFLINE') {
      widgets.add(
        _SignalBadge(
          key: const Key('livestock-signal-device'),
          label: l10n.livestockSignalDeviceOffline,
          icon: Icons.portable_wifi_off,
          color: AppColors.warningStrong,
          background: AppColors.warningSoft,
        ),
      );
    } else if (signal.device.status == 'FAULT') {
      widgets.add(
        _SignalBadge(
          key: const Key('livestock-signal-device'),
          label: l10n.livestockSignalDeviceFault,
          icon: Icons.warning_amber_rounded,
          color: AppColors.warningStrong,
          background: AppColors.warningSoft,
        ),
      );
    }
    if (health == 'WATCH') {
      widgets.add(
        _SignalBadge(
          key: const Key('livestock-signal-health'),
          label: l10n.livestockSignalHealthWatch,
          icon: Icons.monitor_heart_outlined,
          color: AppColors.warningStrong,
          background: AppColors.warningSoft,
        ),
      );
    }
    if (signal.ai.status == 'ALERT') {
      widgets.add(
        _SignalBadge(
          key: const Key('livestock-signal-ai'),
          label: l10n.livestockSignalAiAlert,
          icon: Icons.psychology_alt,
          color: AppColors.aiAnomaly,
          background: AppColors.aiAnomaly.withValues(alpha: 0.1),
        ),
      );
    } else if (signal.ai.status == 'OBSERVE') {
      widgets.add(
        _SignalBadge(
          key: const Key('livestock-signal-ai'),
          label: l10n.livestockSignalAiObserve,
          icon: Icons.psychology_alt,
          color: AppColors.aiAnomaly,
          background: AppColors.aiAnomaly.withValues(alpha: 0.08),
        ),
      );
    }
    if (health == 'NORMAL' && widgets.isEmpty) {
      widgets.add(
        _SignalBadge(
          key: const Key('livestock-signal-health'),
          label: l10n.livestockSignalHealthNormal,
          icon: Icons.check_circle_outline,
          color: AppColors.successStrong,
          background: AppColors.successSoft,
        ),
      );
    }
    return widgets;
  }

  String? _temperatureValue(AppLocalizations l10n, LivestockSignal signal) {
    final value = signal.health.metrics.rumenTemperature.value;
    if (value == null) return null;
    return l10n.livestockMetricTemperatureValue(value);
  }

  String? _motilityValue(AppLocalizations l10n, LivestockSignal signal) {
    final value = signal.health.metrics.rumenMotility.value;
    if (value == null) return null;
    return l10n.livestockMetricMotilityValue(value);
  }
}

class _SignalBadge extends StatelessWidget {
  const _SignalBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    required this.freshness,
  });

  final String? value;
  final IconData icon;
  final String label;
  final String freshness;

  bool get stale => freshness == SignalFreshness.stale;
  bool get delayed => freshness == SignalFreshness.delayed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = value ?? l10n.livestockMetricNoData;
    final note = stale
        ? l10n.livestockMetricStale
        : delayed
        ? l10n.livestockMetricDelayed
        : null;
    final color = stale
        ? AppColors.textSecondary
        : delayed
        ? AppColors.warningStrong
        : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            '$label $text${note == null ? '' : ' · $note'}',
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
