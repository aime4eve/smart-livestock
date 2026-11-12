import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/track_draft_advanced_params.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/track_draft_device_picker.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Wizard step 2 / desktop panel section ②: quick range chips + custom
/// start/end boxes with the 30-day hard cap (spec §3.3).
class TrackDraftRangePicker extends ConsumerWidget {
  const TrackDraftRangePicker({super.key});

  static const quickOptions = [7, 14, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(trackDraftControllerProvider);
    final controller = ref.read(trackDraftControllerProvider.notifier);
    final tooLong = state.rangeTooLong || state.rangeInverted;

    return ListView(
      key: const Key('track-draft-range-picker'),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      children: [
        Row(
          children: [
            for (final days in quickOptions) ...[
              Expanded(
                child: _QuickChip(
                  key: Key('track-draft-range-chip-$days'),
                  label: l10n.fenceTrackDraftRangeChipDays(days),
                  selected: state.quickDays == days,
                  onTap: () => controller.setQuickRange(days),
                ),
              ),
              if (days != quickOptions.last)
                const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _DateBox(
                key: const Key('track-draft-range-start'),
                label: l10n.fenceTrackDraftRangeStart,
                value: state.startTime,
                isStart: true,
                danger: tooLong,
                onPick: (d) => controller.setCustomRange(
                  DateTime(d.year, d.month, d.day),
                  state.endTime ?? DateTime(d.year, d.month, d.day, 23, 59),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _DateBox(
                key: const Key('track-draft-range-end'),
                label: l10n.fenceTrackDraftRangeEnd,
                value: state.endTime,
                isStart: false,
                danger: tooLong,
                onPick: (d) => controller.setCustomRange(
                  state.startTime ?? DateTime(d.year, d.month, d.day),
                  DateTime(d.year, d.month, d.day, 23, 59),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // 30-day cap: amber warning replaces the info hint (spec §3.3).
        if (tooLong)
          _RangeHint(
            key: const Key('track-draft-range-warning'),
            color: AppColors.warning,
            borderAlpha: 0.3,
            icon: Icons.warning_amber_rounded,
            text: l10n.fenceTrackDraftRangeTooLong,
          )
        else
          _RangeHint(
            color: AppColors.info,
            borderAlpha: 0.25,
            icon: Icons.info_outline,
            text: l10n.fenceTrackDraftRangeHint,
          ),
        const SizedBox(height: AppSpacing.md),
        _SelectedDevicesCard(),
        const SizedBox(height: AppSpacing.md),
        // 高级参数折叠区 (spec §5.7)：移动向导第 2 步与桌面面板②节共用本
        // 组件（桌面把本 picker 内嵌在 320px 盒里，挂这里两形态各得一份，
        // 且不外推桌面面板 ListView 的「生成来源」卡）。
        const TrackDraftAdvancedParams(),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    super.key,
    required this.label,
    required this.value,
    required this.isStart,
    required this.danger,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final bool isStart;
  final bool danger;
  final ValueChanged<DateTime> onPick;

  String _fmt(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: now.subtract(const Duration(days: 730)),
          lastDate: now,
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(
            color: danger ? AppColors.danger : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 8.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? '--' : _fmt(value!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today,
                    size: 12, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeHint extends StatelessWidget {
  const _RangeHint({
    super.key,
    required this.color,
    required this.borderAlpha,
    required this.icon,
    required this.text,
  });

  final Color color;
  final double borderAlpha;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: borderAlpha)),
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

/// Selected-devices meta card (prototype screen 3 .meta-card).
class _SelectedDevicesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(trackDraftControllerProvider);
    final selected = [
      for (final c in state.candidates)
        if (state.selectedDeviceIds.contains(c.deviceId))
          c.earTag == null || c.earTag!.isEmpty
              ? c.name
              : '${c.name}（${c.earTag}）',
    ];
    final days = state.hasRange
        ? state.endTime!.difference(state.startTime!).inDays
        : 0;
    return TrackDraftMetaCard(
      icon: Icons.gps_fixed,
      title: l10n.fenceTrackDraftSelectedDevicesTitle(selected.length),
      rows: [
        (l10n.fenceTrackDraftMetaDevices, _joinNames(context, selected)),
        (
          l10n.fenceTrackDraftMetaEstimate,
          l10n.fenceTrackDraftEstimateDesc(
            days,
            formatPointCount(state.estimatedPoints),
          ),
        ),
      ],
    );
  }
}

/// Locale-aware device-name separator (review 低6): zh uses the
/// ideographic comma, everything else a plain comma.
String _joinNames(BuildContext context, List<String> names) => names.join(
      Localizations.localeOf(context).languageCode == 'zh' ? '、' : ', ',
    );

/// Shared meta card (prototype .meta-card): title row + key/value rows.
class TrackDraftMetaCard extends StatelessWidget {
  const TrackDraftMetaCard({
    super.key,
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14263126),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      k,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                        height: 1.8,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      v,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.8,
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
