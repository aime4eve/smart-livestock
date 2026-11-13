import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/fence_buffer_layer.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_models.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_store.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_sync_controller.dart';
import 'package:hkt_livestock_agentic/features/pages/ranch_page.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/ranch_controller.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/ranch_fence_tab.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// dart:io HttpClient stub so NetworkImage widgets (farm header etc.)
/// resolve to a 1x1 PNG instead of throwing NetworkImageLoadException,
/// which the flutter_test zone counts as unexpected exceptions.
/// 1x1 transparent PNG bytes (kTransparentImage equivalent).
final _transparentImage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _ImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _ImageHttpClient();
}

class _ImageHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ImageHttpRequest();
  @override
  void close({bool force = false}) {}
}

class _ImageHttpRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _ImageHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _ImageHttpResponse();
}

class _ImageHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _ImageHttpResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.value(_transparentImage).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}

/// Fakes that skip the polling/transport machinery (3s periodic timer +
/// websocket) which would hang the fake-async widget-test zone.
class _FakeSignalSyncController extends SignalSyncController {
  @override
  SignalSyncState build() => const SignalSyncState(
        farmId: 'F1',
        fences: {'7': _signalFence},
        mapLoaded: true,
      );
}

class _FakeRanchController extends RanchController {
  _FakeRanchController(this._overview);
  final RanchOverview _overview;

  @override
  Future<RanchOverview> build() async => _overview;
}

const _signalFence = MapFenceSignal(
  fenceId: '7',
  name: 'North Pasture',
  revision: 1,
  status: 'OK',
  activeAlertTypes: [],
  livestockCount: 2,
  active: true,
  color: '#4C9A5F',
  fenceType: 'sub',
  version: 1,
  geometry: [
    [28.0, 112.0],
    [28.01, 112.0],
    [28.01, 112.01],
  ],
);

/// Task 5 follow-up: the ranch fence tab renders signal-geometry fences
/// (ranchMapGeometryProvider), which carry no generation provenance of their
/// own. RanchPage merges `generationMetadata` from overview.fences by id so
/// the detail card's "generation source" section renders (spec §4.3).
/// NIX-412: the backend JTS bufferPolygon rides the same overview merge —
/// signal fences carry only the fence body, so without the by-id merge the
/// warning band layer would silently skip every fence.
void main() {
  // Backend-computed buffer ring (JTS output echoed by ranch-overview).
  const overviewBufferRing = [
    LatLng(27.9995, 111.9995),
    LatLng(28.0105, 111.9995),
    LatLng(28.0105, 112.0105),
    LatLng(27.9995, 112.0105),
  ];
  const metadata = <String, dynamic>{
    'method': 'DEVICE_TRACK',
    'deviceIds': [101, 102],
    'startTime': '2026-10-29T00:00:00Z',
    'endTime': '2026-11-11T00:00:00Z',
    'rawPointCount': 16088,
    'usedPoints': 7412,
    'outlierTrimmed': 371,
    'hullMethod': 'concave',
    'generatedAt': '2026-11-11T08:00:00Z',
  };

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.setActiveFarmId('F1');
    HttpOverrides.global = _ImageHttpOverrides();
  });
  tearDown(() {
    ApiClient.instance.setActiveFarmId(null);
    HttpOverrides.global = null;
  });

  RanchFenceData overviewFence({
    Map<String, dynamic>? meta,
    List<LatLng> buffer = const [],
  }) => RanchFenceData(
        id: '7',
        name: 'North Pasture',
        active: true,
        type: 'POLYGON',
        colorValue: 0xFF4C9A5F,
        points: const [
          LatLng(28.0, 112.0),
          LatLng(28.01, 112.0),
          LatLng(28.01, 112.01),
        ],
        areaHectares: 1,
        livestockCount: 2,
        version: 1,
        generationMetadata: meta,
        bufferPoints: buffer,
      );

  RanchOverview overview({
    bool withMetadata = true,
    bool withBuffer = true,
  }) => RanchOverview(
        overallStats: const RanchOverviewStats(
          totalLivestock: 2,
          healthyRate: 1.0,
          alertCount: 0,
          criticalCount: 0,
          deviceOnlineRate: 1.0,
          inFenceRate: 1.0,
        ),
        sceneSummary: RanchSceneSummary.fromJson(null),
        pendingTasks: const [],
        // withMetadata=false models a signal fence with NO matching
        // overview fence (merge misses → metadata stays null). withBuffer=
        // false models the overview fence lacking a stored buffer ring
        // (merge misses → empty bufferPoints → band silently skipped).
        fences: withMetadata
            ? [
                overviewFence(
                  meta: metadata,
                  buffer: withBuffer ? overviewBufferRing : const [],
                ),
              ]
            : const [],
        livestockMarkers: const [],
        alerts: const [],
        fenceAlertSummary: const {},
        healthAlertSummary: const {},
        fenceZones: const [],
      );

  http.Client catchAllClient() => MockClient((req) async => http.Response(
        jsonEncode({'code': 'OK', 'data': const {}}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ));

  Future<void> pumpRanchPage(
    WidgetTester tester, {
    required bool withMetadata,
    bool withBuffer = true,
  }) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialSessionProvider.overrideWithValue(
              const AppSession.authenticated(
                role: UserRole.owner,
                accessToken: 'test-token',
                activeFarmId: 'F1',
              ),
            ),
            ranchControllerProvider.overrideWith(
              () => _FakeRanchController(overview(
                withMetadata: withMetadata,
                withBuffer: withBuffer,
              )),
            ),
            signalSyncControllerProvider.overrideWith(
              _FakeSignalSyncController.new,
            ),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RanchPage(),
          ),
        ),
      );
      // Bounded pumps: the breathing animation (repeat) starts once a fence
      // is selected, so pumpAndSettle would time out afterwards.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      // Switch the bottom sheet to the fence tab (围栏). '围栏' also heads
      // the overview section, so take the tab label (first in tree order).
      await tester.tap(find.text('围栏').first);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      // Select the fence to open the detail card. The map also paints a
      // name chip (IgnorePointer), so scope the tap to the fence tab list.
      final listItemName = find.descendant(
        of: find.byType(RanchFenceTab),
        matching: find.text('North Pasture'),
      );
      await tester.ensureVisible(listItemName.first);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.tap(listItemName.first);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }, catchAllClient);
  }

  testWidgets(
      'signal fence with matching overview metadata renders the source card',
      (tester) async {
    await pumpRanchPage(tester, withMetadata: true);
    expect(
      find.byKey(const Key('fence-generation-source-card')),
      findsOneWidget,
    );
    expect(find.text('生成来源'), findsOneWidget);
    expect(find.text('2 台设备'), findsOneWidget);
  });

  testWidgets(
      'signal fence without matching overview fence hides the source card',
      (tester) async {
    await pumpRanchPage(tester, withMetadata: false);
    // Detail card is open (name pill visible) but no source card.
    expect(find.text('North Pasture'), findsWidgets);
    expect(
      find.byKey(const Key('fence-generation-source-card')),
      findsNothing,
    );
  });
  // 缓冲带聚焦（2026-11-13 用户裁决）：50m 橙色缓冲带只在选中某个围栏时
  // 显示该围栏的；未选中任何围栏时整体隐藏（多围栏缓冲带常显=视觉噪声）。
  // 断言锚点=FenceBufferLayer 是否出现在牧场页 widget 树。
  testWidgets('buffer layer shows while a fence is selected (pumpRanchPage '
      'opens the detail card by default)', (tester) async {
    await pumpRanchPage(tester, withMetadata: true);
    // pumpRanchPage 已选中围栏（打开详情卡是源卡断言前提）→ 缓冲带层出现。
    expect(find.byType(FenceBufferLayer), findsOneWidget);
  });

  testWidgets('buffer layer hides after deselecting the fence', (tester) async {
    await pumpRanchPage(tester, withMetadata: true);
    expect(find.byType(FenceBufferLayer), findsOneWidget);
    // 取消选中（点详情卡头部「收起」按钮）→ 缓冲带层随之隐藏。
    await tester.tap(find.text('收起').first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.byType(FenceBufferLayer), findsNothing);
  });

  // NIX-412 geometry single-source: the band's outer ring must be the
  // overview-merged backend JTS bufferPolygon (merged by id into the signal
  // fence), with the signal fence body as the hole. FenceBufferLayer renders
  // SizedBox.shrink when the merge misses, so anchor the assertion to the
  // descendant PolygonLayer, not the layer widget itself.
  testWidgets('selected fence renders the band from the overview-merged '
      'buffer ring', (tester) async {
    await pumpRanchPage(tester, withMetadata: true);
    final bandLayer = find.descendant(
      of: find.byType(FenceBufferLayer),
      matching: find.byType(PolygonLayer),
    );
    expect(bandLayer, findsOneWidget);
    final polygons = tester.widget<PolygonLayer>(bandLayer).polygons;
    expect(polygons, hasLength(1));
    // shouldTransform depends on tile connectivity probing (AutoNavi online
    // reachable locally → GCJ-02; CI runners have no egress → raw WGS-84),
    // so the environment-dependent transform may NOT be a deterministic
    // assertion input. What must hold everywhere: the ring is EXACTLY the
    // overview-merged geometry (raw or transformed, never anything else)
    // and ring + hole share the same coordinate space (no misaligned band).
    const rawRing = overviewBufferRing;
    final gcjRing = CoordTransform.wgs84ToGcj02All(rawRing);
    const rawHole = [
      LatLng(28.0, 112.0),
      LatLng(28.01, 112.0),
      LatLng(28.01, 112.01),
    ];
    final gcjHole = CoordTransform.wgs84ToGcj02All(rawHole);
    final ringGcj = listEquals(polygons.single.points, gcjRing);
    expect(
      ringGcj || listEquals(polygons.single.points, rawRing),
      isTrue,
      reason: 'band ring must be the overview-merged backend geometry, '
          'either raw WGS-84 (offline tiles) or its GCJ-02 transform '
          '(AutoNavi online) — nothing else',
    );
    expect(
      polygons.single.holePointsList!.single,
      ringGcj ? gcjHole : rawHole,
    );
  });

  testWidgets('overview fence without a buffer ring skips the band entirely',
      (tester) async {
    await pumpRanchPage(tester, withMetadata: true, withBuffer: false);
    // Layer widget exists (selected) but renders nothing — no PolygonLayer
    // under it, never a client-side recomputed ring.
    expect(find.byType(FenceBufferLayer), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FenceBufferLayer),
        matching: find.byType(PolygonLayer),
      ),
      findsNothing,
    );
  });
}
