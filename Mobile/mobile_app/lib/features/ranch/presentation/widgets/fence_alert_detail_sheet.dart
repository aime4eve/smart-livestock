import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'dart:math' show cos, sqrt;
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/device_info_line.dart';
import 'package:hkt_livestock_agentic/core/l10n/l10n.dart';

/// Detail sheet for a fence alert — shows a mini map with fence polygon,
/// livestock position, buffer zone, and distance/direction info.
class FenceAlertDetailSheet extends StatelessWidget {
  const FenceAlertDetailSheet({
    super.key,
    required this.alert,
    required this.fences,
    this.livestockPosition,
  });

  final RanchAlertData alert;
  final List<RanchFenceData> fences;
  final LatLng? livestockPosition;

  @override
  Widget build(BuildContext context) {
    final fence = fences.where((f) => f.id == alert.fenceId).firstOrNull;
    final fencePoints = fence?.points ?? <LatLng>[];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Row(
              children: [
                const Icon(Icons.fence, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    alert.message,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Metadata
            _buildMetadata(context),
            const SizedBox(height: AppSpacing.md),

            // Mini map
            if (fencePoints.isNotEmpty)
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _MiniFenceMap(
                    fencePoints: fencePoints,
                    livestockPosition: livestockPosition,
                    fenceName: fence?.name ?? '',
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.sm),

            // Device info (subtle)
            DeviceInfoLine(deviceId: alert.livestockId),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        if (alert.distance != null)
          _MetricChip(
            icon: Icons.straighten,
            label: L10n.instance.ranchFieldDistanceToFence,
            value: '${alert.distance!.toStringAsFixed(0)}m',
            color: alert.distance! > 30 ? AppColors.warning : AppColors.danger,
          ),
        if (alert.direction != null)
          _MetricChip(
            icon: Icons.navigation,
            label: L10n.instance.ranchFieldDirection,
            value: alert.direction!,
            color: AppColors.info,
          ),
        _MetricChip(
          icon: Icons.schedule,
          label: L10n.instance.ranchFieldTime,
          value: _formatTime(alert.occurredAt),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return L10n.instance.ranchTimeUnknown;
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A mini map showing the fence polygon and livestock position.
class _MiniFenceMap extends StatelessWidget {
  const _MiniFenceMap({
    required this.fencePoints,
    this.livestockPosition,
    required this.fenceName,
  });

  final List<LatLng> fencePoints;
  final LatLng? livestockPosition;
  final String fenceName;

  @override
  Widget build(BuildContext context) {
    // Calculate center from fence points
    final center = fencePoints.isNotEmpty
        ? LatLng(
            fencePoints.map((p) => p.latitude).reduce((a, b) => a + b) / fencePoints.length,
            fencePoints.map((p) => p.longitude).reduce((a, b) => a + b) / fencePoints.length,
          )
        : const LatLng(28.2458, 112.8519);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        // Simple tile layer (OSM for the mini map)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smartlivestock.demo',
        ),
        // Fence polygon
        PolygonLayer(
          polygons: [
            Polygon(
              points: fencePoints,
              color: AppColors.primary.withValues(alpha: 0.15),
              borderColor: AppColors.primary,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        // Buffer zone polygon
        PolygonLayer(
          polygons: [
            Polygon(
              points: _computeBuffer(fencePoints, 50),
              color: Colors.orange.withValues(alpha: 0.08),
              borderColor: Colors.orange.withValues(alpha: 0.5),
              borderStrokeWidth: 1.5,
              pattern: StrokePattern.dashed(segments: [6, 4]),
            ),
          ],
        ),
        // Livestock marker
        if (livestockPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: livestockPosition!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                  ),
                  child: const Center(
                    child: Icon(Icons.pets, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<LatLng> _computeBuffer(List<LatLng> points, int meters) {
    if (points.length < 3) return [];
    final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final latOff = meters / 111000.0;
    final lngOff = meters / (111000.0 * cos(avgLat * 3.14159265 / 180));
    final buffer = <LatLng>[];
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final prev = points[(i - 1 + n) % n];
      final curr = points[i];
      final next = points[(i + 1) % n];
      final dx1 = curr.longitude - prev.longitude;
      final dy1 = curr.latitude - prev.latitude;
      final dx2 = next.longitude - curr.longitude;
      final dy2 = next.latitude - curr.latitude;
      final nx1 = -dy1 / latOff;
      final ny1 = dx1 / lngOff;
      final len1 = sqrt(nx1 * nx1 + ny1 * ny1);
      final nx2 = -dy2 / latOff;
      final ny2 = dx2 / lngOff;
      final len2 = sqrt(nx2 * nx2 + ny2 * ny2);
      if (len1 < 1e-10 || len2 < 1e-10) { buffer.add(curr); continue; }
      final avgNx = (nx1 / len1 + nx2 / len2) / 2;
      final avgNy = (ny1 / len1 + ny2 / len2) / 2;
      final avgLen = sqrt(avgNx * avgNx + avgNy * avgNy);
      if (avgLen < 1e-10) { buffer.add(curr); continue; }
      final scale = meters / avgLen;
      buffer.add(LatLng(
        curr.latitude + avgNy * scale / 111000.0,
        curr.longitude + avgNx * scale / 111000.0 * (latOff / lngOff),
      ));
    }
    return buffer;
  }
}
