import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/features/offline_fences/domain/cached_fence.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class FenceConflictPage extends StatelessWidget {
  final FenceConflict conflict;
  final VoidCallback onKeepLocal;
  final VoidCallback onKeepServer;

  const FenceConflictPage({
    super.key,
    required this.conflict,
    required this.onKeepLocal,
    required this.onKeepServer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bounds = _computeBounds([
      ...conflict.localFence.vertices,
      ...conflict.serverVertices,
    ]);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fenceConflictTitle(conflict.localFence.name))),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final useRow = constraints.maxWidth > 500;
              final mapWidgets = [
                _buildMapSection(
                  title: l10n.fenceConflictServerVersion(conflict.serverVersion.toString()),
                  points: conflict.serverVertices,
                  color: Colors.blue,
                  center: bounds.center,
                ),
                _buildMapSection(
                  title: l10n.fenceConflictLocalVersion,
                  points: conflict.localFence.vertices,
                  color: Colors.orange,
                  center: bounds.center,
                ),
              ];
              return useRow
                  ? Row(children: mapWidgets.map((w) => Expanded(child: w)).toList())
                  : Column(children: mapWidgets);
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('btn-keep-server'),
                    onPressed: onKeepServer,
                    child: Text(l10n.fenceConflictDiscardMine),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    key: const Key('btn-keep-local'),
                    onPressed: onKeepLocal,
                    child: Text(l10n.fenceConflictOverwrite),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection({
    required String title,
    required List<LatLng> points,
    required Color color,
    required LatLng center,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 14),
              children: [
                TileLayer(
                  urlTemplate: 'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scl=1&style=8&x={x}&y={y}&z={z}',
                  subdomains: const ['1', '2', '3', '4'],
                  maxZoom: 18,
                ),
                PolygonLayer(polygons: [
                  Polygon(
                    points: points,
                    color: color.withValues(alpha: 0.3),
                    borderColor: color,
                    borderStrokeWidth: 2,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LatLngBounds _computeBounds(List<LatLng> points) {
    if (points.isEmpty) return LatLngBounds(const LatLng(28, 112), const LatLng(29, 113));
    double minLat = 90, maxLat = -90, minLon = 180, maxLon = -180;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    return LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
  }
}
