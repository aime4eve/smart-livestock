import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

void main() {
  testWidgets('选中围栏后呼吸动画高亮样式与非选中围栏有明显视觉差异', (tester) async {
    await _openFencePage(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    container.read(fenceControllerProvider.notifier).select('fence_pasture_a');
    await tester.pump(const Duration(milliseconds: 750));

    final polygonLayer =
        tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    final fences = container.read(fenceControllerProvider).fences;
    final selectedFence =
        fences.firstWhere((f) => f.id == 'fence_pasture_a');
    final selectedPolygon = polygonLayer.polygons.firstWhere(
      (p) => p.points == selectedFence.points,
    );
    final otherPolygons = polygonLayer.polygons.where(
      (p) => p.points != selectedFence.points,
    );

    expect(selectedPolygon.color!.a, closeTo(0.35, 0.06));
    expect(selectedPolygon.borderStrokeWidth,
        closeTo(3.75, 0.76));
    for (final p in otherPolygons) {
      expect(p.color!.a, closeTo(0.08, 0.03));
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
    await tester.pump(const Duration(milliseconds: 750));
    controller.select('fence_pasture_b');
    await tester.pump(const Duration(milliseconds: 750));

    final state = container.read(fenceControllerProvider);
    expect(state.selectedFenceId, 'fence_pasture_b');

    final polygonLayer =
        tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    final fenceA =
        state.fences.firstWhere((f) => f.id == 'fence_pasture_a');
    final polygonA = polygonLayer.polygons.firstWhere(
      (p) => p.points == fenceA.points,
    );
    expect(polygonA.color!.a, closeTo(0.08, 0.03));
    expect(polygonA.borderStrokeWidth, 1.5);
  });

  testWidgets('无选中围栏时默认透明度为 0.15', (tester) async {
    await _openFencePage(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('page-fence'))),
    );
    container.read(fenceControllerProvider.notifier).select(null);
    await tester.pump();

    final polygonLayer =
        tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    for (final p in polygonLayer.polygons) {
      expect(p.color!.a, closeTo(0.15, 0.03));
      expect(p.borderStrokeWidth, 2.0);
    }
  });
}

Future<void> _openFencePage(WidgetTester tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-owner')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-fence')));
  await tester.pumpAndSettle();
}
