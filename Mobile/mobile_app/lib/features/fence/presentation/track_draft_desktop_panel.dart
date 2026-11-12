import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_wizard_page.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/track_draft_device_picker.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/track_draft_preview.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/track_draft_range_picker.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Responsive entry widget (spec §5.3): ≥900px renders the desktop
/// single-screen panel, below that the mobile three-step wizard. Both
/// forms share the same [trackDraftControllerProvider] state machine.
class TrackDraftFlow extends StatelessWidget {
  const TrackDraftFlow({super.key, this.onConfirmed, this.onBack});

  /// Wizard completion (vertices + generation metadata) for Task 5.
  final void Function(TrackDraftCompletion result)? onConfirmed;

  /// Desktop「‹ 返回表单」.
  final VoidCallback? onBack;

  /// Breakpoint from spec §2.1 (--wizard-panel-width note, §5.3).
  static const double desktopBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= desktopBreakpoint) {
          return TrackDraftDesktopPanel(
            onConfirmed: onConfirmed,
            onBack: onBack,
          );
        }
        return TrackDraftWizardPage(onConfirmed: onConfirmed);
      },
    );
  }
}

/// Desktop form (prototype screen 6): 360px parameter panel (devices +
/// range + source card + generate button) on the left, live map area on
/// the right with floating stat strip / legend / action buttons.
class TrackDraftDesktopPanel extends ConsumerWidget {
  const TrackDraftDesktopPanel({super.key, this.onConfirmed, this.onBack});

  final void Function(TrackDraftCompletion result)? onConfirmed;
  final VoidCallback? onBack;

  /// Component-level constant: --wizard-panel-width (Task 0 mapping §1.1).
  static const double panelWidth = 360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(trackDraftControllerProvider);
    final controller = ref.read(trackDraftControllerProvider.notifier);
    final loading = state.phase == TrackDraftPhase.loading;

    return Scaffold(
      body: Column(
        children: [
          // Top breadcrumb bar (prototype .desktop-topbar).
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.fenceTrackDraftWizardTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: panelWidth,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceAlt,
                    border:
                        Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          children: [
                            _SectionHead(
                              title: '① ${l10n.fenceTrackDraftStepDevice}',
                              trailing: l10n.fenceTrackDraftSelectedOfTotal(
                                state.selectedDeviceIds.length,
                                state.candidates.length,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const SizedBox(
                              height: 240,
                              child: TrackDraftDevicePicker(),
                            ),
                            const TrackDraftSelectedSummary(),
                            const SizedBox(height: AppSpacing.md),
                            _SectionHead(
                              title: '② ${l10n.fenceTrackDraftStepRange}',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const SizedBox(
                              height: 320,
                              child: TrackDraftRangePicker(),
                            ),
                            // ③ Generation source card (fidelity §8,
                            // prototype screen 6 panel): devices + time
                            // range of the latest successful preview,
                            // hidden until one exists.
                            if (state.preview != null &&
                                state.preview!.envelope.isSuccess)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.md),
                                child: TrackDraftMetaCard(
                                  key: const Key(
                                    'track-draft-desktop-source-card',
                                  ),
                                  icon: Icons.receipt_long,
                                  title:
                                      l10n.fenceTrackDraftPreviewSourceTitle,
                                  rows: [
                                    (
                                      l10n.fenceTrackDraftMetaDevices,
                                      _joinNames(
                                        context,
                                        state.preview!.deviceNames,
                                      ),
                                    ),
                                    (
                                      l10n.fenceTrackDraftMetaTimeRange,
                                      _dateRange(state.preview!),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('track-draft-generate'),
                            onPressed: loading || !state.canGenerate
                                ? null
                                : controller.generate,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(l10n.fenceTrackDraftGenerate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: TrackDraftPreview(
                      isDesktop: true,
                      onBack: onBack,
                      onConfirm: () {
                        final result = controller.buildCompletion();
                        if (result != null) onConfirmed?.call(result);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Locale-aware device-name separator (review 低6): zh uses the
/// ideographic comma, everything else a plain comma.
String _joinNames(BuildContext context, List<String> names) => names.join(
      Localizations.localeOf(context).languageCode == 'zh' ? '、' : ', ',
    );

/// `yyyy-MM-dd ~ yyyy-MM-dd` (same format as the preview source card).
String _dateRange(TrackDraftPreviewData preview) {
  String fmt(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }

  return '${fmt(preview.startTime)} ~ ${fmt(preview.endTime)}';
}

/// Panel section header (prototype .sec-head): green tick + title + count.
class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 11,
          color: AppColors.primary,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
