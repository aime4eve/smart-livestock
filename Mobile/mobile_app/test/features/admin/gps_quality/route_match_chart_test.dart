import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/widgets/route_match_chart.dart';

void main() {
  DynamicMatchedPass pass(double lat, double lng, int seq) => DynamicMatchedPass(
        sequenceNo: seq,
        latitude: lat,
        longitude: lng,
        rtkLatitude: lat,
        rtkLongitude: lng,
        error: 1.5,
        ambiguous: false,
        recordedAt: DateTime(2026, 7, 18, 9, seq),
      );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('renders route points and passes without error', (tester) async {
    await tester.pumpWidget(wrap(RouteMatchChart(
      key: const Key('route-match-chart'),
      points: const [
        RouteMatchPoint(sequenceNo: 1, latitude: 28.2000, longitude: 112.9000, status: RouteMatchStatus.matched),
        RouteMatchPoint(sequenceNo: 2, latitude: 28.2005, longitude: 112.9008, status: RouteMatchStatus.ambiguous),
        RouteMatchPoint(sequenceNo: 3, latitude: 28.2010, longitude: 112.9002, status: RouteMatchStatus.missed),
      ],
      passes: [pass(28.2001, 112.9001, 1), pass(28.2006, 112.9007, 2)],
    )));
    await tester.pump();
    expect(find.byKey(const Key('route-match-chart')), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders empty data without error', (tester) async {
    await tester.pumpWidget(wrap(const RouteMatchChart(points: [])));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders single point (zero-range bounds) without error', (tester) async {
    await tester.pumpWidget(wrap(const RouteMatchChart(
      points: [
        RouteMatchPoint(sequenceNo: 1, latitude: 28.2, longitude: 112.9, status: RouteMatchStatus.matched),
      ],
    )));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
