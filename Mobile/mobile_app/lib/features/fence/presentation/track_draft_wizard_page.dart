import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/import_wizard_shell.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/track_draft_device_picker.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/track_draft_preview.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/track_draft_range_picker.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Mobile three-step wizard (device → range → preview), reusing
/// [ImportWizardShell] (spec §3.2–3.5). Task 5 pushes this page from the
/// fence form entry; the confirmed result is returned via [onConfirmed]
/// or `Navigator.pop` with a [TrackDraftCompletion].
class TrackDraftWizardPage extends ConsumerWidget {
  const TrackDraftWizardPage({super.key, this.onConfirmed});

  final void Function(TrackDraftCompletion result)? onConfirmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(trackDraftControllerProvider);
    final controller = ref.read(trackDraftControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fenceTrackDraftWizardTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ImportWizardShell(
            step: state.wizardStep,
            stepCount: 3,
            stepLabels: [
              l10n.fenceTrackDraftStepDevice,
              l10n.fenceTrackDraftStepRange,
              l10n.fenceTrackDraftStepPreview,
            ],
            child: Expanded(
              child: switch (state.wizardStep) {
                0 => const TrackDraftDevicePicker(),
                1 => const TrackDraftRangePicker(),
                _ => const TrackDraftPreview(),
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: _ActionBar(
          step: state.wizardStep,
          phase: state.phase,
          onConfirm: () {
            final result = controller.buildCompletion();
            if (result == null) return;
            if (onConfirmed != null) {
              onConfirmed!(result);
            } else {
              Navigator.of(context).pop(result);
            }
          },
        ),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.step,
    required this.phase,
    required this.onConfirm,
  });

  final int step;
  final TrackDraftPhase phase;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(trackDraftControllerProvider);
    final controller = ref.read(trackDraftControllerProvider.notifier);
    final loading = phase == TrackDraftPhase.loading;

    // Step 3 failure keeps its own single exit inside the preview widget.
    if (step == 2 && phase == TrackDraftPhase.failed) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (step == 0) const TrackDraftSelectedSummary(),
          Row(
            children: [
              if (step == 0) ...[
                SizedBox(
                  width: 76,
                  child: OutlinedButton(
                    onPressed: loading ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('track-draft-device-next'),
                    onPressed: controller.canProceedFromDevices
                        ? controller.nextToRange
                        : null,
                    child: Text(l10n.fenceTrackDraftNextRange),
                  ),
                ),
              ] else if (step == 1) ...[
                SizedBox(
                  width: 76,
                  child: OutlinedButton(
                    onPressed: loading ? null : controller.backToDevices,
                    child: Text(l10n.fenceTrackDraftPrevStep),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('track-draft-generate'),
                    onPressed:
                        loading || !state.canGenerate ? null : controller.generate,
                    child: Text(l10n.fenceTrackDraftGenerate),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: 96,
                  child: OutlinedButton(
                    onPressed: loading ? null : controller.backToEditing,
                    child: Text('‹ ${l10n.fenceTrackDraftAdjust}'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('track-draft-confirm'),
                    onPressed:
                        phase == TrackDraftPhase.previewing ? onConfirm : null,
                    child: Text('${l10n.fenceTrackDraftConfirm} ✓'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
