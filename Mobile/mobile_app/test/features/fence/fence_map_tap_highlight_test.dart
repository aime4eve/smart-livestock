import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  testWidgets('选中围栏后高亮样式与非选中围栏有明显视觉差异', (tester) async {
    await _openFencePage(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    container.read(fenceControllerProvider.notifier).select('fence_pasture_a');
    await tester.pumpAndSettle();

    final polygonLayer = tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    final fences = container.read(fenceControllerProvider).fences;
    final selectedFence = fences.firstWhere((f) => f.id == 'fence_pasture_a');
    final selectedPolygon = polygonLayer.polygons.firstWhere(
      (p) => p.points == selectedFence.points,
    );
    final otherPolygons = polygonLayer.polygons.where(
      (p) => p.points != selectedFence.points,
    );

    expect(selectedPolygon.color!.a, closeTo(0.4, 0.05));
    expect(selectedPolygon.borderStrokeWidth, 3.5);
    for (final p in otherPolygons) {
      expect(p.color!.a, closeTo(0.1, 0.05));
      expect(p.borderStrokeWidth, 1.5);
    }
  });

  testWidgets('切换选中围栏后前一个围栏恢复正常显示', (tester) async {
    await _openFencePage(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    final controller = container.read(fenceControllerProvider.notifier);

    controller.select('fence_pasture_a');
    await tester.pumpAndSettle();
    controller.select('fence_pasture_b');
    await tester.pumpAndSettle();

    final state = container.read(fenceControllerProvider);
    expect(state.selectedFenceId, 'fence_pasture_b');

    final polygonLayer = tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    final fenceA = state.fences.firstWhere((f) => f.id == 'fence_pasture_a');
    final polygonA = polygonLayer.polygons.firstWhere(
      (p) => p.points == fenceA.points,
    );
    expect(polygonA.color!.a, closeTo(0.1, 0.05));
    expect(polygonA.borderStrokeWidth, 1.5);
  });

  testWidgets('先选A区再选三角围栏可切换选中且地图视角不跳转', (tester) async {
    await _openFencePage(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    final fences = container.read(fenceControllerProvider).fences;
    final fenceA = fences.firstWhere((f) => f.id == 'fence_pasture_a');
    final triangleFence = fences.firstWhere((f) => f.id == 'fence_rest');

    final map = tester.widget<FlutterMap>(find.byKey(const Key('fence-browse-map')));
    final mapController = map.mapController!;
    final onMapTap = map.options.onTap!;
    final centerBefore = mapController.camera.center;
    final zoomBefore = mapController.camera.zoom;

    onMapTap(
      const TapPosition(Offset.zero, Offset.zero),
      _fenceCenter(fenceA.points),
    );
    await tester.pumpAndSettle();
    expect(container.read(fenceControllerProvider).selectedFenceId, fenceA.id);
    expect(
      mapController.camera.center.latitude,
      closeTo(centerBefore.latitude, 0.0001),
    );
    expect(
      mapController.camera.center.longitude,
      closeTo(centerBefore.longitude, 0.0001),
    );
    expect(mapController.camera.zoom, closeTo(zoomBefore, 0.0001));

    onMapTap(
      const TapPosition(Offset.zero, Offset.zero),
      _fenceCenter(triangleFence.points),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(fenceControllerProvider).selectedFenceId,
      triangleFence.id,
    );
    expect(
      mapController.camera.center.latitude,
      closeTo(centerBefore.latitude, 0.0001),
    );
    expect(
      mapController.camera.center.longitude,
      closeTo(centerBefore.longitude, 0.0001),
    );
    expect(mapController.camera.zoom, closeTo(zoomBefore, 0.0001));
  });
}

LatLng _fenceCenter(List<LatLng> points) {
  var lat = 0.0;
  var lng = 0.0;
  for (final point in points) {
    lat += point.latitude;
    lng += point.longitude;
  }
  return LatLng(lat / points.length, lng / points.length);
}

Future<void> _openFencePage(WidgetTester tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-owner')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-fence')));
  await tester.pumpAndSettle();
}
