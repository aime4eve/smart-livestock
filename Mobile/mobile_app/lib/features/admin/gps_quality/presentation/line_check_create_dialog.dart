import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Create LINE checks dialog (NIX-68, spatial matching): devices with
/// gps_logs data load on open (refresh button available), select devices +
/// a standard track line (SELECTED pinned with ★), then launch one READY
/// LINE test per device. No time window — matching is purely spatial.
class LineCheckCreateDialog extends ConsumerStatefulWidget {
  const LineCheckCreateDialog({super.key});

  @override
  ConsumerState<LineCheckCreateDialog> createState() =>
      _LineCheckCreateDialogState();
}

class _LineCheckCreateDialogState
    extends ConsumerState<LineCheckCreateDialog> {
  bool _querying = false;
  bool _launching = false;
  List<LineCheckDevice>? _devices;
  final Set<String> _selectedDevices = {};
  int? _trackLineId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _queryDevices());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trackLines = ref.watch(trackLinesProvider).value ?? [];
    // SELECTED first (★ pinned), then by import time (spec §8.4).
    final sortedLines = List<StandardTrackLine>.from(trackLines)
      ..sort((a, b) {
        if (a.selected != b.selected) return a.selected ? -1 : 1;
        return (b.createdAt ?? DateTime(2000))
            .compareTo(a.createdAt ?? DateTime(2000));
      });

    return AlertDialog(
      key: const Key('line-check-create-dialog'),
      title: Row(children: [
        Expanded(child: Text(l10n.gpsQualityLineCreate)),
        _lineTypeTag(l10n),
      ]),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ① Query devices (auto-loaded on open)
              Row(children: [
                FilledButton.icon(
                  key: const Key('line-check-query-devices-btn'),
                  icon: _querying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.gpsQualityLineQueryDevices,
                      style: const TextStyle(fontSize: 12)),
                  onPressed: _querying ? null : _queryDevices,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(l10n.gpsQualityLineQueryHint,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ),
              ]),
              // ② Device list
              if (_devices != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${l10n.gpsQualityLineSelectDevices} · '
                  '${l10n.gpsQualityLineDevicesFound(_devices!.length)}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (_devices!.isEmpty)
                  Text(l10n.gpsQualityNoData,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary))
                else
                  ..._devices!.map(_buildDeviceRow),
                const SizedBox(height: AppSpacing.md),
                // ③ Standard track line
                DropdownButtonFormField<int>(
                  key: const Key('line-check-track-line-select'),
                  decoration: InputDecoration(
                    labelText: l10n.gpsQualityLineSelectTrack,
                    helperText: l10n.gpsQualityLineStarHint,
                    isDense: true,
                  ),
                  initialValue: _trackLineId,
                  isExpanded: true,
                  items: sortedLines
                      .map((l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(
                              '${l.selected ? '★ ' : ''}${l.name}'
                              '（${l.selected ? l10n.gpsQualityTrackLineSelected : l10n.gpsQualityTrackLineCandidate}'
                              ' · ${l10n.gpsQualityTrackLinePointLength(l.pointCount, l.lengthM.toStringAsFixed(0))}）',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _trackLineId = v),
                ),
                if (sortedLines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(l10n.gpsQualityLineNoTrackLine,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.warning)),
                  ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.lineTeal.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                        left: BorderSide(color: AppColors.lineTeal, width: 3)),
                  ),
                  child: Text(l10n.gpsQualityLineCalcNote,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _launching ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('line-check-launch-btn'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.lineTeal),
          onPressed: (_selectedDevices.isEmpty ||
                  _trackLineId == null ||
                  _launching)
              ? null
              : _launch,
          child: _launching
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(l10n.gpsQualityLineLaunch(_selectedDevices.length)),
        ),
      ],
    );
  }

  Widget _lineTypeTag(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.lineTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: AppColors.lineTeal, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('${l10n.gpsQualityLineCheck} LINE',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.lineTeal)),
      ]),
    );
  }

  Widget _buildDeviceRow(LineCheckDevice d) {
    final l10n = AppLocalizations.of(context)!;
    final timeFmt = DateFormat('MM-dd HH:mm');
    final checked = _selectedDevices.contains(d.deviceCode);
    return InkWell(
      key: ValueKey('line-check-device-${d.deviceCode}'),
      onTap: () => setState(() {
        if (checked) {
          _selectedDevices.remove(d.deviceCode);
        } else {
          _selectedDevices.add(d.deviceCode);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Checkbox(
            value: checked,
            activeColor: AppColors.lineTeal,
            visualDensity: VisualDensity.compact,
            onChanged: (v) => setState(() {
              if (v == true) {
                _selectedDevices.add(d.deviceCode);
              } else {
                _selectedDevices.remove(d.deviceCode);
              }
            }),
          ),
          Expanded(
            child: Text(d.deviceCode,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
          ),
          Text(l10n.gpsQualityLinePointTotal(d.pointCount),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.md),
          Text(
            d.firstRecordedAt != null && d.lastRecordedAt != null
                ? l10n.gpsQualityLineFirstLast(
                    timeFmt.format(d.firstRecordedAt!),
                    timeFmt.format(d.lastRecordedAt!))
                : '-',
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFamily: 'monospace'),
          ),
        ]),
      ),
    );
  }

  Future<void> _queryDevices() async {
    setState(() {
      _querying = true;
      _devices = null;
      _selectedDevices.clear();
    });
    try {
      final devices = await ref
          .read(gpsQualityApiRepositoryProvider)
          .fetchLineCheckDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _selectedDevices
            ..clear()
            ..addAll(devices.map((d) => d.deviceCode));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _querying = false);
    }
  }

  Future<void> _launch() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _launching = true);
    try {
      final results = await ref
          .read(gpsQualityApiRepositoryProvider)
          .createLineChecks(
            trackLineId: _trackLineId!,
            deviceCodes: _selectedDevices.toList(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(checksProvider);
      ref.invalidate(lineComparisonProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(l10n.gpsQualityLineLaunchDone(results.length))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _launching = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
