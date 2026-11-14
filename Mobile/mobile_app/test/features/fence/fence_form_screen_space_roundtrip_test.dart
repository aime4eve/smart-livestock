import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/map/map_constants.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/fence_item.dart';
import 'package:hkt_livestock_agentic/features/pages/fence_form_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// NIX-237: the form keeps its points in SCREEN space (GCJ-02 under 高德
/// tiles) and inverts them on save. The screen→store roundtrip must be
/// consistent in BOTH tile states: whatever the map state, saving an
/// untouched template polygon must persist the WGS-84 template vertices —
/// not the GCJ-shifted ones (~500 m) and not a double-inverse.
///
/// The tile provider is forced through the [debugTileProviderOverride] test
/// seam, so no connectivity probe (timers/HTTP) runs in the test.
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.setActiveFarmId('F1');
  });

  tearDown(() {
    debugTileProviderOverride = null;
    ApiClient.instance.setActiveFarmId(null);
  });

  SmartTileProvider forcedProvider({required bool gcj, bool offline = false}) {
    final provider = SmartTileProvider(
      mbtilesProviders: const [],
      onlineUrl: 'https://tiles.example/{z}/{x}/{y}.png',
      onlineIsGcj02: gcj,
    );
    if (offline) {
      provider.simulateOffline();
    } else {
      provider.simulatePrimary();
    }
    return provider;
  }

  /// Edit-mode fixture: a WGS-84 polygon the API would return for id 77.
  final fence77Polygon = <String, dynamic>{
    'id': 77,
    'name': 'Polygon 77',
    'shape': 'polygon',
    'alarmEnabled': true,
    'active': true,
    'vertices': [
      {'lat': 28.0, 'lng': 112.0},
      {'lat': 28.01, 'lng': 112.0},
      {'lat': 28.01, 'lng': 112.01},
    ],
    'version': 3,
    'fenceType': 'sub',
  };

  Widget app({String? fenceId}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(body: FenceFormPage(fenceId: fenceId)),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'test-token',
            activeFarmId: 'F1',
          ),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('高德态：模板顶点经屏幕系（GCJ）往返，保存体仍是 WGS-84 模板值',
      (tester) async {
    final capturedBodies = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      debugTileProviderOverride = forcedProvider(gcj: true);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fence-form-name')), 'GCJ往返');
      await _scrollToSaveAndTap(tester);
    }, () => mockClient(capturedBodies));

    expect(capturedBodies, isNotEmpty, reason: 'POST /fences 应已被捕获');
    assertVerticesMatchTemplate(capturedBodies.single, reason: '高德态保存体');
  });

  testWidgets('OSM 态（WGS 瓦片）：无变换，保存体恒等于模板值', (tester) async {
    final capturedBodies = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      debugTileProviderOverride = forcedProvider(gcj: false);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fence-form-name')), 'OSM往返');
      await _scrollToSaveAndTap(tester);
    }, () => mockClient(capturedBodies));

    expect(capturedBodies, isNotEmpty, reason: 'POST /fences 应已被捕获');
    assertVerticesMatchTemplate(capturedBodies.single, reason: 'OSM 态保存体');
  });

  testWidgets('离线态（server tileserver = WGS）：无变换，保存体恒等于模板值',
      (tester) async {
    final capturedBodies = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      debugTileProviderOverride = forcedProvider(gcj: true, offline: true);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fence-form-name')), '离线往返');
      await _scrollToSaveAndTap(tester);
    }, () => mockClient(capturedBodies));

    expect(capturedBodies, isNotEmpty, reason: 'POST /fences 应已被捕获');
    assertVerticesMatchTemplate(capturedBodies.single, reason: '离线态保存体');
  });

  testWidgets('编辑路径：高德态载入 WGS 围栏不触碰直接保存，顶点恒等往返',
      (tester) async {
    final capturedBodies = <Map<String, dynamic>>[];
    await http.runWithClient(() async {
      debugTileProviderOverride = forcedProvider(gcj: true);
      await tester.pumpWidget(app(fenceId: '77'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fence-form-name')), '编辑恒等');
      await _scrollToSaveAndTap(tester);
    }, () => mockClient(capturedBodies, initialFences: [fence77Polygon]));

    expect(capturedBodies, isNotEmpty, reason: 'PUT /fences/77 应已被捕获');
    // Open → save untouched must be an identity roundtrip: the loaded WGS
    // vertices come back as themselves (no GCJ drift accumulation).
    final vertices = (capturedBodies.single['vertices'] as List)
        .map((v) => LatLng((v['lat'] as num).toDouble(),
            (v['lng'] as num).toDouble()))
        .toList();
    expect(vertices.length, fence77Polygon['vertices'].length,
        reason: '编辑恒等往返 顶点数');
    for (var i = 0; i < vertices.length; i++) {
      final expected = (fence77Polygon['vertices'][i]
          as Map<String, dynamic>);
      expect(vertices[i].latitude, closeTo(expected['lat'] as double, 5e-5),
          reason: '编辑恒等往返 顶点$i 纬度');
      expect(vertices[i].longitude, closeTo(expected['lng'] as double, 5e-5),
          reason: '编辑恒等往返 顶点$i 经度');
    }
  });
}

Future<void> _scrollToSaveAndTap(WidgetTester tester) async {
  // The save button sits at the bottom of a long form — a tall viewport
  // makes it visible without scrolling (ensureVisible proved insufficient
  // under the default 800x600 surface).
  tester.view.physicalSize = const Size(800.0, 1800.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpAndSettle();
  final saveButton = find.byKey(const Key('fence-form-save'));
  await tester.tap(saveButton, warnIfMissed: true);
  await tester.pumpAndSettle();
}

http.Client mockClient(
  List<Map<String, dynamic>> capturedBodies, {
  List<Map<String, dynamic>> initialFences = const [],
}) {
  http.Response ok(Object? data) => http.Response(
        jsonEncode({'code': 'OK', 'data': data}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
  return MockClient((req) async {
    final path = req.url.path;
    if (path.endsWith('/fences') && req.method == 'POST') {
      capturedBodies
          .add(jsonDecode(req.body) as Map<String, dynamic>);
      return ok({'id': 99});
    }
    if (req.method == 'PUT' && path.contains('/fences/')) {
      capturedBodies
          .add(jsonDecode(req.body) as Map<String, dynamic>);
      return ok({'id': 77});
    }
    if (path.endsWith('/fences') && req.method == 'GET') {
      return ok({'items': initialFences});
    }
    if (path.contains('/livestock')) return ok({'items': const []});
    return ok(const {});
  });
}

void assertVerticesMatchTemplate(
  Map<String, dynamic> body, {
  required String reason,
}) {
  final vertices = (body['vertices'] as List)
      .map((v) => LatLng(
            (v['lat'] as num).toDouble(),
            (v['lng'] as num).toDouble(),
          ))
      .toList();
  final expected = FenceItem.defaultPointsForType(
      FenceType.polygon, MapConstants.mapCenter);
  expect(vertices.length, expected.length, reason: reason);
  for (var i = 0; i < expected.length; i++) {
    expect(vertices[i].latitude, closeTo(expected[i].latitude, 5e-5),
        reason: '$reason 顶点$i 纬度');
    expect(vertices[i].longitude, closeTo(expected[i].longitude, 5e-5),
        reason: '$reason 顶点$i 经度');
  }
}
