import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/data/track_draft_repository.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Thousands separator for point estimates (prototype shows `16,088`).
String formatPointCount(int value) {
  final digits = value.toString();
  return digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

/// Wizard step 1 / desktop panel section ①: multi-select tracker list
/// (spec §3.2). Scrollable content; the persistent selection summary is
/// [TrackDraftSelectedSummary], pinned above the action bar by the parent.
class TrackDraftDevicePicker extends ConsumerWidget {
  const TrackDraftDevicePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(trackDraftControllerProvider);

    if (state.candidatesLoading) {
      return const Center(
        key: Key('track-draft-devices-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (state.candidatesFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.commonLoadFailed,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonal(
              key: const Key('track-draft-devices-retry'),
              onPressed: () =>
                  ref.read(trackDraftControllerProvider.notifier).loadCandidates(),
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    if (state.candidates.isEmpty) {
      return Center(
        key: const Key('track-draft-devices-empty'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            l10n.fenceTrackDraftNoDevices,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return ListView(
      key: const Key('track-draft-device-list'),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      children: [
        for (final device in state.candidates)
          _DeviceRow(
            device: device,
            selected: state.selectedDeviceIds.contains(device.deviceId),
            onTap: () => ref
                .read(trackDraftControllerProvider.notifier)
                .toggleDevice(device.deviceId),
          ),
        const SizedBox(height: AppSpacing.xs),
        // Same-lot guidance (prototype screen 2 bottom info bar).
        _HintBar(
          icon: Icons.lightbulb_outline,
          color: AppColors.info,
          text: l10n.fenceTrackDraftSameLotHint,
        ),
        if (state.quotaFull) ...[
          const SizedBox(height: AppSpacing.sm),
          _HintBar(
            key: const Key('track-draft-quota-hint'),
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            text: l10n.fenceTrackDraftQuotaExceeded,
          ),
        ],
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final TrackDraftDeviceCandidate device;
  final bool selected;
  final VoidCallback onTap;

  bool get _stale {
    final lastFix = device.lastFixAt;
    if (lastFix == null) return true;
    return DateTime.now().difference(lastFix) > const Duration(hours: 24);
  }

  String _fixLabel(AppLocalizations l10n) {
    final lastFix = device.lastFixAt;
    if (lastFix == null) return l10n.fenceTrackDraftNeverLocated;
    final diff = DateTime.now().difference(lastFix);
    if (diff.inMinutes < 60) {
      return l10n.fenceTrackDraftFixMinutesAgo(math.max(1, diff.inMinutes));
    }
    if (diff.inHours < 24) return l10n.fenceTrackDraftFixHoursAgo(diff.inHours);
    return l10n.fenceTrackDraftFixDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stale = _stale;
    final row = Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : AppColors.surfaceAlt,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
        // Prototype radius-md (12) — component-level value, not the
        // inputDecorationTheme 14 (Task 0 deviation record #1).
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          // Prototype --shadow-card (component-level value).
          BoxShadow(
            color: Color(0x14263126),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: selected
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.gps_fixed, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      if (device.earTag != null && device.earTag!.isNotEmpty)
                        TextSpan(text: '${l10n.fenceTrackDraftEarTag} ${device.earTag} · '),
                      if (stale)
                        TextSpan(
                          text: device.lastFixAt == null
                              ? l10n.fenceTrackDraftNeverLocated
                              : l10n.fenceTrackDraftStaleFix(
                                  DateTime.now()
                                      .difference(device.lastFixAt!)
                                      .inDays,
                                ),
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        TextSpan(text: _fixLabel(l10n)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPointCount(device.pointCount),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                l10n.fenceTrackDraftPoints30d,
                style: const TextStyle(
                  fontSize: 8,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return Padding(
      // Stale rows dim to 65% but stay selectable (spec §3.2).
      padding: EdgeInsets.zero,
      child: Opacity(
        opacity: stale ? 0.65 : 1,
        child: InkWell(
          key: Key('track-draft-device-row-${device.deviceId}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: row,
        ),
      ),
    );
  }
}

/// Persistent bottom counter above the action bar (spec §3.2):
/// 已选 {n} 台 · 预估合并 {m} 点.
class TrackDraftSelectedSummary extends ConsumerWidget {
  const TrackDraftSelectedSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(trackDraftControllerProvider);
    return Padding(
      key: const Key('track-draft-selected-summary'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        l10n.fenceTrackDraftSelectedSummary(
          state.selectedDeviceIds.length,
          formatPointCount(state.estimatedPoints),
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Info/warning hint bar shared by the wizard steps (prototype .limit-hint).
class _HintBar extends StatelessWidget {
  const _HintBar({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 9, color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
