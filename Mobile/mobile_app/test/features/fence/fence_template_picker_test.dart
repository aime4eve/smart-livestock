import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/presentation/widgets/fence_template_picker.dart';

void main() {
  testWidgets('围栏表单显示三个模板入口', (tester) async {
    await _openFenceForm(tester);

    expect(find.byKey(const Key('fence-template-rectangle')), findsOneWidget);
    expect(find.byKey(const Key('fence-template-circle')), findsOneWidget);
    expect(
      find.byKey(const Key('fence-template-trajectory-buffer')),
      findsOneWidget,
    );
  });

  testWidgets('圆形模板可驱动围栏类型和初始几何', (tester) async {
    await _openFenceForm(tester);

    await tester.tap(find.byKey(const Key('fence-template-circle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<FenceType>(FenceType.circle)), findsOneWidget);
    expect(find.byKey(const Key('fence-form-draw-hint')), findsOneWidget);
    expect(_mapPointCount(tester), 2);
  });

  testWidgets('轨迹缓冲区模板可生成初始多边形', (tester) async {
    await _openFenceForm(tester);

    await tester.tap(find.byKey(const Key('fence-template-trajectory-buffer')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<FenceType>(FenceType.polygon)), findsOneWidget);
    expect(find.byKey(const Key('fence-form-draw-hint')), findsOneWidget);
    expect(find.byKey(const Key('fence-form-polygon-done')), findsOneWidget);
    expect(_mapPointCount(tester), greaterThanOrEqualTo(4));

    final areaText = tester.widget<Text>(
      find.byKey(const Key('fence-form-area')),
    );
    expect(_extractArea(areaText.data), greaterThan(0.01));
  });

  test('轨迹缓冲区模板几何有效且非退化', () {
    final preset = fenceTemplatePresetFor(FenceTemplate.trajectoryBuffer);

    expect(preset.type, FenceType.polygon);
    expect(preset.drawingPoints.length, greaterThanOrEqualTo(4));
    expect(_polygonArea(preset.drawingPoints), greaterThan(1e-8));
  });
}

Future<void> _openFenceForm(WidgetTester tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-owner')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-fence')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('fence-panel-toggle')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('fence-add')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('page-fence-form')), findsOneWidget);
}

int _mapPointCount(WidgetTester tester) {
  var count = 0;
  while (true) {
    final finder = find.byKey(Key('fence-form-map-point-$count'));
    if (finder.evaluate().isEmpty) {
      return count;
    }
    count++;
  }
}

double _extractArea(String? areaText) {
  final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(areaText ?? '');
  return double.tryParse(match?.group(1) ?? '') ?? 0;
}

double _polygonArea(List<LatLng> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i++) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.longitude * next.latitude;
    area -= next.longitude * current.latitude;
  }
  return area.abs() / 2;
}
