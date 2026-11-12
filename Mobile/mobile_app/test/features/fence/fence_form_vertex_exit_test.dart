import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart'
    show initialSessionProvider;
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart'
    show UserRole;
import 'package:hkt_livestock_agentic/features/pages/fence_form_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Integration-test feedback regression (2026-11-12 #1/#2):
/// 1. Loaded track vertices could not be deleted — numbered markers now tap-
///    delete (polygon only, min 3 points).
/// 2. Tapping 取消 after a browser refresh froze the page — go_router
///    `context.pop()` throws GoError("There is nothing to pop") at the
///    bottom of the stack (delegate.dart:105); exit now falls back to
///    context.go('/fence').
///
/// Mock plumbing mirrors track_draft_entry_test.dart (http.runWithClient +
/// MockClient speaking the real envelope).
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.setActiveFarmId('F1');
  });
  tearDown(() => ApiClient.instance.setActiveFarmId(null));

  http.Response ok(Object? data) => http.Response(
        jsonEncode({'code': 'OK', 'data': data}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  http.Client mockClient() => MockClient((req) async {
        final path = req.url.path;
        if (path.endsWith('/fences')) return ok({'items': const []});
        if (path.contains('/livestock')) return ok({'items': const []});
        return ok(const {});
      });

  Widget app({String initialLocation = '/'}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, __) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open-form'),
                onPressed: () => context.push('/fence/form'),
                child: const Text('open-form-home'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/fence/form',
          builder: (_, __) => const FenceFormPage(),
        ),
        // Fallback target for the deep-link exit path.
        GoRoute(
          path: '/fence',
          builder: (_, __) => const Scaffold(
              body: KeyedSubtree(
                  key: ValueKey('fence-list'), child: SizedBox())),
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

  Future<void> pump(WidgetTester tester, {String initialLocation = '/'}) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(app(initialLocation: initialLocation));
      await tester.pumpAndSettle();
    }, mockClient);
  }

  /// Loads 4 polygon vertices through the manual-entry dialog so the
  /// numbered markers exist without needing the map camera. Switches the
  /// fence type to polygon first (default is rectangle, which keeps only
  /// two structural anchor points).
  Future<void> loadManualPolygon(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('fence-form-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('多边形').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-form-map-manual')));
    await tester.pumpAndSettle();
    // Center + four cardinal vertices around the default map center
    // (MapConfig defaultCenter ≈ 28.2282,112.9388). Spacing 0.0016° ≈ 75 px
    // at z15 — neighbor grab targets (r=28px) stay clear of each other's
    // centers AND of the edge-midpoint dots (≥53px away), and the whole
    // ring fits the 260px-tall viewport centered on the first vertex.
    await tester.enterText(
      find.byKey(const Key('fence-form-manual-input')),
      '28.2282,112.9380\n'
          '28.2298,112.9380\n'
          '28.2282,112.9396\n'
          '28.2266,112.9380\n'
          '28.2282,112.9364',
    );
    await tester.tap(find.byKey(const Key('fence-form-manual-apply')));
    await tester.pumpAndSettle();
  }

  testWidgets('refreshed page (stack bottom): 取消 exits via /fence, no GoError',
      (tester) async {
    await pump(tester, initialLocation: '/fence/form');
    await loadManualPolygon(tester);
    await tester.tap(find.byKey(const Key('fence-form-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fence-list')), findsOneWidget,
        reason: 'bottom-of-stack exit must navigate to the fence list');
    expect(tester.takeException(), isNull);
  });

  testWidgets('refreshed page: appBar back key exits via /fence too',
      (tester) async {
    await pump(tester, initialLocation: '/fence/form');
    await tester.tap(find.byKey(const Key('fence-form-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fence-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with history: 取消 pops back home as before', (tester) async {
    await pump(tester);
    await http.runWithClient(() async {
      await tester.tap(find.byKey(const Key('open-form')));
      await tester.pumpAndSettle();
    }, mockClient);
    await tester.tap(find.byKey(const Key('fence-form-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-form')), findsOneWidget,
        reason: 'normal history keeps the pop semantics');
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag-ready hit area: markers expose a 56px grab target and '
      'a drag does not delete (drag-to-move verified in-browser, real '
      'gesture arena)', (tester) async {
    await pump(tester, initialLocation: '/fence/form');
    await loadManualPolygon(tester);
    // Drag-to-move depends on the real gesture arena (marker pan recognizer
    // vs the map's own — widget-test synthesized gestures don't reproduce
    // that arbitration; verified via browser E2E on dev). Here we pin the
    // invariants that ARE testable: the grab target is MarkerLayer data
    // wired to the polygon points, and a synthetic drag still leaves the
    // vertex count intact (a drag must never degenerate into a delete).
    final markers =
        tester.widget<MarkerLayer>(find.byType(MarkerLayer).last).markers;
    expect(markers.length, 5);
    expect(
      markers.every((mk) => mk.width == 56 && mk.height == 56),
      isTrue,
      reason: '56px grab target (28px visual dot + margin)',
    );
    await tester.drag(
      find.byKey(const Key('fence-form-map-point-1')),
      const Offset(24, -18),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer).last).markers.length,
      5,
      reason: 'a drag is a move, never a delete',
    );
  });

  testWidgets('move tool (default): tapping a marker never deletes',
      (tester) async {
    await pump(tester, initialLocation: '/fence/form');
    await loadManualPolygon(tester);
    await tester.tap(find.byKey(const Key('fence-form-map-point-1')));
    // The tap may fall through to the map's own tap handler, which arms a
    // 250ms timer — pump past it so no timer is pending at teardown.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    // Move tool is the default — deletion requires the explicit delete tool.
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer).last).markers.length,
      5,
    );
  });

  testWidgets('delete tool: tapping a marker deletes that vertex',
      (tester) async {
    await pump(tester, initialLocation: '/fence/form');
    await loadManualPolygon(tester);
    await tester.tap(find.byKey(const Key('fence-form-tool-delete')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-form-map-point-1')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer).last).markers.length,
      4,
      reason: 'delete tool + tap removes the vertex (5 -> 4)',
    );
  });

  testWidgets('edge midpoint dots exist on every edge (tap-to-insert '
      'verified in-browser: map-stack hit-test offset makes the synthetic '
      'tap unreliable)', (tester) async {
    await pump(tester, initialLocation: '/fence/form');
    await loadManualPolygon(tester);
    final edgeLayer =
        tester.widget<MarkerLayer>(find.byType(MarkerLayer).first).markers;
    expect(edgeLayer.length, 5, reason: 'one midpoint dot per edge');
    // Each midpoint dot sits on its edge (midpoint of the two endpoints).
    final vertexLayer =
        tester.widget<MarkerLayer>(find.byType(MarkerLayer).last).markers;
    for (var i = 0; i < vertexLayer.length; i++) {
      final a = vertexLayer[i].point;
      final b = vertexLayer[(i + 1) % vertexLayer.length].point;
      final mid = edgeLayer[i].point;
      expect(mid.latitude, closeTo((a.latitude + b.latitude) / 2, 1e-9));
      expect(mid.longitude, closeTo((a.longitude + b.longitude) / 2, 1e-9));
    }
    expect(
      edgeLayer.every((mk) => mk.width == 28 && mk.height == 28),
      isTrue,
    );
  });

  testWidgets('manual entry keeps the draw toggle visible (hidden only for '
      'track-loaded drafts)', (tester) async {
    await pump(tester, initialLocation: '/fence/form');
    await loadManualPolygon(tester);
    expect(find.byKey(const Key('fence-form-draw-toggle')), findsOneWidget,
        reason: 'hide rule is scoped to track-loaded drafts (_draftMetadata)');
  });

  testWidgets('polygon keeps its minimum of 3 vertices', (tester) async {
    await pump(tester, initialLocation: '/fence/form');
    await loadManualPolygon(tester);
    await tester.tap(find.byKey(const Key('fence-form-tool-delete')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    // Delete down to exactly 3 (5 -> 4 -> 3).
    await tester.tap(find.byKey(const Key('fence-form-map-point-1')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fence-form-map-point-1')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    // A further delete must be rejected.
    await tester.tap(find.byKey(const Key('fence-form-map-point-1')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fence-form-map-point-2')), findsOneWidget,
        reason: '3 vertices is the polygon floor — deletion is a no-op');
  });

  testWidgets('manual-entry flow itself stays intact (5 vertices load)',
      (tester) async {
    await pump(tester, initialLocation: '/fence/form');
    await loadManualPolygon(tester);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(Key('fence-form-map-point-$i')), findsOneWidget);
    }
  });
}
