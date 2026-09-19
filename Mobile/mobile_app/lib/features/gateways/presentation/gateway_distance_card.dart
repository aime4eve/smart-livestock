import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/devices/data/devices_api_repository.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

import '../../../core/api/api_client.dart';

/// 通讯距离卡片（NIX-219 F2/F9，原型屏③）。
/// 按网关分组展示帧级距离；无定位设备显示“未知（无定位）+ 信号档位”。
class GatewayDistanceCard extends ConsumerStatefulWidget {
  const GatewayDistanceCard({super.key, required this.livestockId});

  final String livestockId;

  @override
  ConsumerState<GatewayDistanceCard> createState() => _GatewayDistanceCardState();
}

class _GatewayDistanceCardState extends ConsumerState<GatewayDistanceCard> {
  Future<Map<String, dynamic>?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>?> _load() async {
    final installations = await const DevicesApiRepository()
        .loadInstallations(livestockId: widget.livestockId);
    if (installations.isEmpty) return null;
    final deviceId = int.tryParse(installations.first.deviceId);
    if (deviceId == null) return null;
    return ApiClient.instance
        .farmGet('/devices/$deviceId/gateway-distances');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: AppColors.surfaceAlt,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              );
            }
            final view = snap.data;
            if (view == null) {
              return _unknownRow(l10n, withSignal: false);
            }
            final byGateway = (view['byGateway'] as List?) ?? const [];
            final inferred = (view['inferred'] as List?) ?? const [];
            if (byGateway.isEmpty && inferred.isEmpty) {
              return _unknownRow(l10n, withSignal: false);
            }
            final nearest = view['nearest'] as Map?;
            final nearestId = nearest?['gatewayId'] as String?;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.gatewayDistanceTitle,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                for (final g in byGateway)
                  _distanceLine(
                    gatewayId: (g['gatewayId'] as String?) ?? '--',
                    latest: (g['latestMeters'] as num?)?.toDouble(),
                    median: (g['medianMeters'] as num?)?.toDouble(),
                    p95: (g['p95Meters'] as num?)?.toDouble(),
                    isNearest: nearestId != null && nearestId == g['gatewayId'],
                    l10n: l10n,
                  ),
                for (final g in inferred)
                  _inferredLine(
                    gatewayId: (g['gatewayId'] as String?) ?? '--',
                    p50: (g['p50Meters'] as num?)?.toDouble(),
                    p90: (g['p90Meters'] as num?)?.toDouble(),
                    l10n: l10n,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _unknownRow(AppLocalizations l10n, {required bool withSignal}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.gatewayDistanceTitle,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              Text(l10n.gatewayDistanceUnknown,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.gatewayDistanceUnknownHint,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
        ],
      );

  Widget _distanceLine({
    required String gatewayId,
    required double? latest,
    required double? median,
    required double? p95,
    required bool isNearest,
    required AppLocalizations l10n,
  }) {
    final short = gatewayId.length <= 6 ? gatewayId : '…${gatewayId.substring(gatewayId.length - 6)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (isNearest) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                  color: AppColors.primary, borderRadius: BorderRadius.circular(3)),
              child: Text(l10n.gatewayNearestTag,
                  style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(short,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(latest == null ? '--' : l10n.gatewayMeters(latest.round()),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              if (median != null)
                Text(l10n.gatewayMedianSub(median.round()),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inferredLine({
    required String gatewayId,
    required double? p50,
    required double? p90,
    required AppLocalizations l10n,
  }) {
    final short = gatewayId.length <= 6 ? gatewayId : '…${gatewayId.substring(gatewayId.length - 6)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Row(children: [
              Text(short,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(3)),
                child: Text(l10n.gatewayInferredTag,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ),
            ]),
          ),
          Text(
            p50 == null
                ? '--'
                : l10n.gatewayInferredRange(p50.round(), (p90 ?? p50).round()),
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
