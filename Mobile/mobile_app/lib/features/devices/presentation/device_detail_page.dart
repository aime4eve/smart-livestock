import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/devices/data/devices_api_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class DeviceDetailPage extends ConsumerStatefulWidget {
  const DeviceDetailPage({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailData {
  const _DeviceDetailData({
    required this.device,
    this.livestockId,
    this.livestockCode,
  });

  final DeviceItem device;
  final String? livestockId;
  final String? livestockCode;
}

class _DeviceDetailPageState extends ConsumerState<DeviceDetailPage> {
  late Future<_DeviceDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DeviceDetailData> _load() async {
    const repository = DevicesApiRepository();
    final device = await repository.loadDetail(widget.deviceId);
    String? livestockId;
    String? livestockCode;

    try {
      final installations = await repository.loadInstallations(pageSize: 500);
      final active = installations
          .where(
            (item) =>
                item.deviceId == widget.deviceId &&
                item.active &&
                item.livestockId.isNotEmpty,
          )
          .toList();
      if (active.isNotEmpty) {
        livestockId = active.first.livestockId;
        try {
          final livestock = await ref
              .read(livestockRepositoryProvider)
              .loadDetail(livestockId);
          livestockCode = livestock.livestockCode;
        } catch (_) {
          livestockCode = livestockId;
        }
      }
    } catch (_) {
      // Binding info is supplementary; the device detail remains usable.
    }

    return _DeviceDetailData(
      device: device,
      livestockId: livestockId,
      livestockCode: livestockCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deviceDetailTitle)),
      body: FutureBuilder<_DeviceDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${l10n.commonLoadFailed}: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => setState(() => _future = _load()),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Header(device: data.device),
              const SizedBox(height: AppSpacing.md),
              _Card(
                title: l10n.deviceDetailBasic,
                children: [
                  _Row(
                    label: l10n.devicesManagement,
                    value:
                        data.device.deviceTypeName ??
                        _deviceType(l10n, data.device.type),
                  ),
                  _Row(label: l10n.deviceDetailEui, value: data.device.devEui),
                  _Row(
                    label: l10n.deviceDetailSerial,
                    value: data.device.serialNo,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _Card(
                title: l10n.deviceDetailSignal,
                children: [
                  _Row(
                    label: l10n.deviceDetailRuntime,
                    value: data.device.runtimeStatus ?? data.device.status.name,
                  ),
                  if (data.device.batteryPercent != null)
                    _Row(
                      label: l10n.deviceDetailSignal,
                      value:
                          '${data.device.batteryPercent}% · ${data.device.signalStrength ?? '-'}',
                    ),
                  if (data.device.rssi != null)
                    _Row(label: 'RSSI', value: '${data.device.rssi} dBm'),
                  if (data.device.lastGateway != null)
                    _Row(
                      label: l10n.deviceDetailGateway,
                      value: data.device.lastGateway,
                    ),
                  if (data.device.lastTelemetrySyncedAt != null)
                    _Row(
                      label: l10n.deviceDetailLastSync,
                      value: data.device.lastTelemetrySyncedAt,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _Card(
                title: l10n.deviceDetailBinding,
                children: [
                  _Row(
                    label: l10n.deviceDetailBinding,
                    value:
                        data.livestockCode ??
                        data.device.boundLivestockCode.ifEmptyNull,
                    fallback: l10n.deviceDetailNone,
                  ),
                  if (data.livestockId != null)
                    _Row(label: 'ID', value: data.livestockId),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _deviceType(AppLocalizations l10n, DeviceType type) {
    return switch (type) {
      DeviceType.gps => l10n.deviceTypeGps,
      DeviceType.rumenCapsule => l10n.deviceTypeRumenCapsule,
      DeviceType.earTag => l10n.deviceTypeEarTag,
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.device});

  final DeviceItem device;

  @override
  Widget build(BuildContext context) {
    final online =
        device.runtimeStatus == 'online' ||
        device.status == DeviceStatus.online;
    final color = online ? AppColors.success : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sensors, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  device.runtimeStatus ?? device.status.name,
                  style: TextStyle(fontSize: 10, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.fallback});

  final String label;
  final String? value;
  final String? fallback;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = (value == null || value!.isEmpty)
        ? (fallback ?? '-')
        : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              effectiveValue,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}
