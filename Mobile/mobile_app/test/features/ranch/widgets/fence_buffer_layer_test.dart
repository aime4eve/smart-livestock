import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/fence_buffer_layer.dart';

/// NIX-412 geometry single-source regression:
/// 1. The band's outer ring must come from the backend JTS bufferPolygon
///    (same geometry the alert engine tests against), with the fence body
///    as the hole.
/// 2. A fence without a backend buffer polygon renders no band at all —
///    never fall back to client-side offset computation (the two-geometry
///    drift this fix removes).
void main() {
  const fenceTriangle = [
    LatLng(28.20, 112.90),
    LatLng(28.21, 112.90),
    LatLng(28.21, 112.91),
  ];
  const backendBufferRing = [
    LatLng(28.1995, 112.8995),
    LatLng(28.2105, 112.8995),
    LatLng(28.2105, 112.9105),
    LatLng(28.1995, 112.9105),
  ];

  RanchFenceData fence({List<LatLng> buffer = const []}) => RanchFenceData(
        id: 'F1',
        name: 'concave fence',
        active: true,
        type: 'POLYGON',
        colorValue: 0xFF4C9A5F,
        points: fenceTriangle,
        areaHectares: 1.0,
        livestockCount: 0,
        version: 1,
        bufferPoints: buffer,
      );

  /// PolygonLayer needs a MapCamera, so mount layers inside a real
  /// FlutterMap (no TileLayer → no network in tests).
  Widget host(FenceBufferLayer layer) => MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: MapOptions(
              initialCenter: fenceTriangle.first,
              initialZoom: 14,
            ),
            children: [layer],
          ),
        ),
      );

  testWidgets('renders band from backend buffer ring with fence hole',
      (tester) async {
    await tester.pumpWidget(host(FenceBufferLayer(
      fences: [fence(buffer: backendBufferRing)],
    )));

    final layer = tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    expect(layer.polygons, hasLength(1));
    final polygon = layer.polygons.single;
    // Outer ring = backend geometry verbatim (no client-side recompute).
    expect(polygon.points, backendBufferRing);
    // Hole = fence body, so only the outer 50m band stays visible.
    expect(polygon.holePointsList, hasLength(1));
    expect(polygon.holePointsList!.single, fenceTriangle);
  });

  testWidgets('skips band when backend buffer polygon is absent',
      (tester) async {
    await tester.pumpWidget(host(FenceBufferLayer(
      fences: [fence()],
    )));

    expect(find.byType(PolygonLayer), findsNothing);
  });

  testWidgets('skips inactive fences', (tester) async {
    const disabled = RanchFenceData(
      id: 'F2',
      name: 'disabled',
      active: false,
      type: 'POLYGON',
      colorValue: 0xFF4C9A5F,
      points: fenceTriangle,
      areaHectares: 1.0,
      livestockCount: 0,
      version: 1,
      bufferPoints: backendBufferRing,
    );
    await tester.pumpWidget(
        host(const FenceBufferLayer(fences: [disabled])));

    expect(find.byType(PolygonLayer), findsNothing);
  });
}
