import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/offline_fences/domain/cached_fence.dart';

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
    final bounds = _computeBounds([
      ...conflict.localFence.vertices,
      ...conflict.serverVertices,
    ]);

    return Scaffold(
      appBar: AppBar(title: Text('围栏冲突: ${conflict.localFence.name}')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('服务端版本 (v${conflict.serverVersion})',
                          style: Theme.of(context).textTheme.titleSmall),
                      Expanded(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: bounds.center,
                            initialZoom: 14,
                          ),
                          children: [
                            PolygonLayer(polygons: [
                              Polygon(
                                points: conflict.serverVertices,
                                color: Colors.blue.withOpacity(0.3),
                                borderColor: Colors.blue,
                                borderStrokeWidth: 2,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('您的修改 (离线编辑)',
                          style: Theme.of(context).textTheme.titleSmall),
                      Expanded(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: bounds.center,
                            initialZoom: 14,
                          ),
                          children: [
                            PolygonLayer(polygons: [
                              Polygon(
                                points: conflict.localFence.vertices,
                                color: Colors.orange.withOpacity(0.3),
                                borderColor: Colors.orange,
                                borderStrokeWidth: 2,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('btn-keep-server'),
                    onPressed: onKeepServer,
                    child: const Text('放弃我的修改'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    key: const Key('btn-keep-local'),
                    onPressed: onKeepLocal,
                    child: const Text('覆盖服务端版本'),
                  ),
                ),
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
