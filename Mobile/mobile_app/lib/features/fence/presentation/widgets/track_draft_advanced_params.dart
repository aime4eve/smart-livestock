import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// 高级参数折叠区 (spec §5.7)：三个牧场主可自调的包络校准滑块
/// （剔除最远点 / 点群合并 / 轮廓简化），默认收起。
///
/// 仅「折叠/展开」这一个 UI 态留在本地 StatefulWidget；参数值本身走
/// 共享 controller（[TrackDraftState.params]），禁 setState 改业务状态。
/// 移动向导第 2 步与桌面面板②节各挂载一处，共享同一 controller。
class TrackDraftAdvancedParams extends ConsumerStatefulWidget {
  const TrackDraftAdvancedParams({super.key});

  @override
  ConsumerState<TrackDraftAdvancedParams> createState() =>
      _TrackDraftAdvancedParamsState();
}

class _TrackDraftAdvancedParamsState
    extends ConsumerState<TrackDraftAdvancedParams> {
  bool _expanded = false;

  /// Slider default positions (spec §5.7); the restore button and the
  /// initial values both derive from the animalTrack bundle display
  /// getters — the literals here are only the slider range anchors.
  static const _defaultRoamingTrimPct = 5.0;
  static const _defaultClusterCellM = 30.0;
  static const _defaultAreaTrimPct = 0.5;

  /// Pushes one slider change through the controller intent, carrying the
  /// other two values from the current params (never local copies).
  void _update({
    double? roamingTrimPct,
    double? clusterCellM,
    double? areaTrimPct,
  }) {
    final p = ref.read(trackDraftControllerProvider).params;
    ref.read(trackDraftControllerProvider.notifier).updateAdvancedParams(
          roamingTrimPct: roamingTrimPct ?? p.roamingTrimPctDisplay.toDouble(),
          clusterCellM: clusterCellM ?? p.clusterCellMDisplay.toDouble(),
          areaTrimPct: areaTrimPct ?? p.areaTrimPctDisplay,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = ref.watch(trackDraftControllerProvider.select(
      (s) => s.params,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const Key('track-draft-advanced-toggle'),
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.fenceTrackAdvancedTitle,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          _SliderRow(
            sliderKey: const Key('track-draft-slider-roaming'),
            label: l10n.fenceTrackAdvRoaming,
            valueText: '${_fmtNum(p.roamingTrimPctDisplay.toDouble())}%',
            value: p.roamingTrimPctDisplay.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            onChanged: (v) => _update(roamingTrimPct: v),
          ),
          _SliderRow(
            sliderKey: const Key('track-draft-slider-cluster'),
            label: l10n.fenceTrackAdvCluster,
            valueText: _meterSuffix(context, p.clusterCellMDisplay.toDouble()),
            value: p.clusterCellMDisplay.toDouble(),
            min: 10,
            max: 100,
            divisions: 9,
            onChanged: (v) => _update(clusterCellM: v),
          ),
          _SliderRow(
            sliderKey: const Key('track-draft-slider-area'),
            label: l10n.fenceTrackAdvArea,
            valueText: '${_fmtNum(p.areaTrimPctDisplay)}%',
            value: p.areaTrimPctDisplay,
            min: 0,
            max: 2,
            divisions: 8,
            onChanged: (v) => _update(areaTrimPct: v),
          ),
          Row(
            children: [
              TextButton(
                key: const Key('track-draft-params-restore'),
                onPressed: () => _update(
                  roamingTrimPct: _defaultRoamingTrimPct,
                  clusterCellM: _defaultClusterCellM,
                  areaTrimPct: _defaultAreaTrimPct,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.fenceTrackAdvRestore,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            l10n.fenceTrackAdvNote,
            style: const TextStyle(
              fontSize: 8.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  /// Locale-aware meter suffix (review 低6 precedent: the inline locale
  /// branch for the device-name separator); '%' needs no localization.
  String _meterSuffix(BuildContext context, double v) =>
      '${_fmtNum(v)} ${Localizations.localeOf(context).languageCode == 'zh' ? '米' : 'm'}';

  /// 30 / 0.5 / 0.75 → "30" / "0.5" / "0.75" (strips trailing zeros, then
  /// a dangling decimal point, from the 0.25-step slider grid).
  String _fmtNum(double v) {
    var s = v.toStringAsFixed(2);
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}

/// One slider row: label + live value on top, discrete slider below.
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.sliderKey,
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final Key sliderKey;
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 30,
          child: Slider(
            key: sliderKey,
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
