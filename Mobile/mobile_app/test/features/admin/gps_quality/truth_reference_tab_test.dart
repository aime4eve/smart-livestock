import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/truth_reference_tab.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakeRepo extends GpsQualityApiRepository {
  final createdPoints = <RtkPoint>[];
  final deletedPointIds = <int>[];

  @override
  Future<RtkPoint> createRtkPoint({
    required String locationName,
    required String pointLabel,
    required double latitude,
    required double longitude,
  }) async {
    final point = RtkPoint(
      id: 100 + createdPoints.length,
      locationName: locationName,
      pointLabel: pointLabel,
      latitude: latitude,
      longitude: longitude,
    );
    createdPoints.add(point);
    return point;
  }

  @override
  Future<void> deleteRtkPoint(int id) async => deletedPointIds.add(id);
}

class _FakeRtkPoints extends RtkPointsController {
  _FakeRtkPoints(this.points);

  List<RtkPoint> points;
  late _FakeRepo repo;

  @override
  Future<List<RtkPoint>> build() async => List.of(points);

  @override
  Future<bool> deletePoint(int id) async {
    await repo.deleteRtkPoint(id);
    points = points.where((point) => point.id != id).toList();
    ref.invalidateSelf();
    return true;
  }
}

class _FakeDynamicRoutes extends DynamicRoutesController {
  @override
  Future<List<DynamicRoute>> build() async => [];
}

class _FakeTrackLines extends TrackLinesController {
  @override
  Future<List<StandardTrackLine>> build() async => [];
}

RtkPoint _point(
  int id,
  String location,
  String label, [
  double latitude = 28.2465,
  double longitude = 112.8515,
]) => RtkPoint(
  id: id,
  locationName: location,
  pointLabel: label,
  latitude: latitude,
  longitude: longitude,
);

List<RtkPoint> _multiLocationPoints() => [
  _point(1, 'A区', '1号点', 28.2467),
  _point(2, 'A区', '2号点', 28.2464),
  _point(3, 'B区', '10号点', 28.2468),
  _point(4, 'B区', '2号点', 28.2461),
  _point(5, 'B区', '1号点', 28.2463),
  _point(6, 'B区', '20号点', 28.2462),
];

Future<_FakeRepo> _pumpTab(
  WidgetTester tester, {
  required _FakeRtkPoints rtkPoints,
  Size size = const Size(1280, 800),
}) async {
  final repo = _FakeRepo();
  rtkPoints.repo = repo;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gpsQualityApiRepositoryProvider.overrideWithValue(repo),
        rtkPointsProvider.overrideWith(() => rtkPoints),
        dynamicRoutesProvider.overrideWith(_FakeDynamicRoutes.new),
        trackLinesProvider.overrideWith(_FakeTrackLines.new),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TruthReferenceTab()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void _expectVisibleTextOrder(WidgetTester tester, List<String> texts) {
  final offsets = texts.map((text) {
    final finder = find.text(text);
    expect(finder, findsOneWidget);
    return tester.getTopLeft(finder).dy;
  }).toList();
  expect(offsets, isNot(orderedPairsLessThan(offsets)));
}

Matcher orderedPairsLessThan(List<double> values) =>
    _OrderedPairsLessThan(values);

class _OrderedPairsLessThan extends Matcher {
  _OrderedPairsLessThan(this.values);

  final List<double> values;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    for (var i = 1; i < values.length; i++) {
      if (values[i - 1] >= values[i]) return true;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('is not strictly increasing: $values');
}

void main() {
  testWidgets('默认选中点数最多的位置并隐藏位置列', (tester) async {
    await _pumpTab(tester, rtkPoints: _FakeRtkPoints(_multiLocationPoints()));

    expect(find.text('B区'), findsOneWidget);
    expect(find.text('4 个点位'), findsOneWidget);
    expect(find.text('1号点'), findsOneWidget);
    expect(find.text('2号点'), findsOneWidget);
    expect(find.text('10号点'), findsOneWidget);
    expect(find.text('20号点'), findsOneWidget);
    expect(find.text('位置'), findsNothing);
  });

  testWidgets('全部位置显示位置列且搜索自动切换到全部位置', (tester) async {
    await _pumpTab(tester, rtkPoints: _FakeRtkPoints(_multiLocationPoints()));

    await tester.enterText(
      find.byKey(const Key('rtk-point-search-field')),
      'A区',
    );
    await tester.pumpAndSettle();

    expect(find.text('位置'), findsOneWidget);
    expect(find.text('A区'), findsAtLeastNWidgets(1));
    expect(find.text('1号点'), findsOneWidget);
    expect(find.text('10号点'), findsNothing);
  });

  testWidgets('坐标保留七位小数', (tester) async {
    await _pumpTab(
      tester,
      rtkPoints: _FakeRtkPoints([
        _point(1, 'B区', '1号点', 28.2465001, 112.8514999),
      ]),
    );

    expect(find.text('28.2465001'), findsOneWidget);
    expect(find.text('112.8514999'), findsOneWidget);
  });

  testWidgets('点位编号按自然数字排序', (tester) async {
    await _pumpTab(
      tester,
      rtkPoints: _FakeRtkPoints([
        _point(1, 'B区', '10号点'),
        _point(2, 'B区', '2号点'),
        _point(3, 'B区', '1号点'),
      ]),
    );

    _expectVisibleTextOrder(tester, ['1号点', '2号点', '10号点']);
  });

  testWidgets('纬度表头支持升降序切换', (tester) async {
    await _pumpTab(
      tester,
      rtkPoints: _FakeRtkPoints([
        _point(1, 'B区', '2号点', 28.2462),
        _point(2, 'B区', '1号点', 28.2461),
        _point(3, 'B区', '3号点', 28.2463),
      ]),
    );

    await tester.tap(find.text('纬度'));
    await tester.pumpAndSettle();
    _expectVisibleTextOrder(tester, ['1号点', '2号点', '3号点']);

    await tester.tap(find.text('纬度'));
    await tester.pumpAndSettle();
    _expectVisibleTextOrder(tester, ['3号点', '2号点', '1号点']);
  });

  testWidgets('删除当前唯一位置点后自动切回全部位置', (tester) async {
    final fakePoints = _FakeRtkPoints([_point(11, '唯一位置', '11号点')]);
    final repo = await _pumpTab(tester, rtkPoints: fakePoints);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-rtk-point')));
    await tester.pumpAndSettle();

    expect(fakePoints.points, isEmpty);
    expect(repo.deletedPointIds, [11]);
    expect(find.text('全部位置'), findsOneWidget);
    expect(find.text('暂无数据'), findsOneWidget);
  });

  testWidgets('搜索无匹配时显示专用空态和关键节点', (tester) async {
    await _pumpTab(tester, rtkPoints: _FakeRtkPoints(_multiLocationPoints()));

    await tester.enterText(
      find.byKey(const Key('rtk-point-search-field')),
      '不存在',
    );
    await tester.pumpAndSettle();

    expect(find.text('没有匹配的 RTK 真值点'), findsOneWidget);
    expect(find.byKey(const Key('rtk-points-panel')), findsOneWidget);
    expect(find.byKey(const Key('rtk-location-nav')), findsOneWidget);
    expect(find.byKey(const Key('rtk-points-table')), findsOneWidget);
  });

  testWidgets('窄屏显示横向位置导航和表格', (tester) async {
    await _pumpTab(
      tester,
      rtkPoints: _FakeRtkPoints(_multiLocationPoints()),
      size: const Size(390, 844),
    );

    expect(find.byKey(const Key('rtk-location-nav')), findsOneWidget);
    expect(find.byKey(const Key('rtk-points-table')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
