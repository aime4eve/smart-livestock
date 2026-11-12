import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/fence/data/track_draft_repository.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/fence_analytics.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/fence_controller.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/track_draft_desktop_panel.dart';
import 'package:hkt_livestock_agentic/features/pages/fence_form_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

import 'track_draft_controller_test.dart'
    show FakeTrackDraftRepository, squarePoints;

/// Task 5: track-draft entry card on the fence form (visibility matrix +
/// offline hint) and the create/edit save-body semantics (spec §4.3).
///
/// ApiClient's top-level `http` calls honour `http.runWithClient`, so a
/// MockClient speaking the real envelope replaces the network (same
/// pattern as feature_gate_page_test).
/// How the candidates probe fails: none / http.ClientException (Web-style
/// transport error) / SocketException (mobile dart:io transport error,
/// review 中1).
enum _OfflineMode { none, clientException, socketException }

void main() {
  final analyticsSink = InMemoryFenceAnalyticsSink();
  final capturedPosts = <Map<String, dynamic>>[];
  final capturedPuts = <({String path, Map<String, dynamic> body})>[];
  var offline = _OfflineMode.none;
  var saveQuotaExceeded = false;

  final fence7 = <String, dynamic>{
    'id': 7,
    'name': 'North Pasture',
    'type': 'polygon',
    'alarmEnabled': true,
    'active': true,
    'vertices': [
      {'lat': 28.0, 'lng': 112.0},
      {'lat': 28.01, 'lng': 112.0},
      {'lat': 28.01, 'lng': 112.01},
    ],
    'version': 3,
    'fenceType': 'sub',
    // Present on the loaded fence to prove the edit path strips it.
    'generationMetadata': {
      'method': 'DEVICE_TRACK',
      'deviceIds': [1, 2],
      'startTime': '2026-10-29T00:00:00Z',
      'endTime': '2026-11-11T00:00:00Z',
      'rawPointCount': 100,
      'usedPoints': 80,
      'outlierTrimmed': 5,
      'hullMethod': 'concave',
      'generatedAt': '2026-11-11T08:00:00Z',
    },
  };

  setUp(() {
    offline = _OfflineMode.none;
    saveQuotaExceeded = false;
    capturedPosts.clear();
    capturedPuts.clear();
    analyticsSink.events.clear();
    FlutterSecureStorage.setMockInitialValues({});
    ApiClient.instance.setActiveFarmId('F1');
  });

  tearDown(() => ApiClient.instance.setActiveFarmId(null));

  http.Client mockClient({List<Map<String, dynamic>> fences = const []}) {
    http.Response ok(Object? data) => http.Response(
          jsonEncode({'code': 'OK', 'data': data}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
    return MockClient((req) async {
      final path = req.url.path;
      if (path.contains('track-draft/candidates')) {
        switch (offline) {
          case _OfflineMode.none:
            break;
          case _OfflineMode.clientException:
            throw http.ClientException('no network');
          case _OfflineMode.socketException:
            throw const SocketException('no network');
        }
        return ok({
          'devices': const [],
          'fenceQuota': {'current': 0, 'limit': null},
        });
      }
      if (path.endsWith('/fences') && req.method == 'POST') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        capturedPosts.add(body);
        if (saveQuotaExceeded) {
          // 403 + QUOTA_EXCEEDED maps to QuotaExceededException in
          // ApiClient (review 中2 — save-time quota race, spec §5.5 兜底).
          return http.Response(
            jsonEncode({
              'code': 'QUOTA_EXCEEDED',
              'message': 'fence quota reached',
            }),
            403,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return ok({'id': 99, 'name': body['name']});
      }
      if (path.contains('/fences/') && req.method == 'PUT') {
        capturedPuts.add(
          (path: path, body: jsonDecode(req.body) as Map<String, dynamic>),
        );
        return ok({'id': 7, 'name': 'North Pasture'});
      }
      if (path.endsWith('/fences')) return ok({'items': fences});
      if (path.contains('/livestock')) return ok({'items': const []});
      return ok(const {});
    });
  }

  /// Home route keeps fenceControllerProvider alive and pre-loads the fence
  /// list so the edit form finds its fence on first build (mirrors the real
  /// app flow where the form opens from the loaded fence list).
  Widget app({UserRole role = UserRole.owner}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Consumer(
            builder: (context, ref, ___) {
              // ignore: unused_local_variable
              final watched = ref.watch(fenceControllerProvider);
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        key: const Key('open-form'),
                        onPressed: () => context.push('/fence/form'),
                        child: const Text('new'),
                      ),
                      TextButton(
                        key: const Key('open-edit-form'),
                        onPressed: () =>
                            context.push('/fence/form?fenceId=7'),
                        child: const Text('edit'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        GoRoute(
          path: '/fence/form',
          builder: (_, state) =>
              FenceFormPage(fenceId: state.uri.queryParameters['fenceId']),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        initialSessionProvider.overrideWithValue(
          AppSession.authenticated(
            role: role,
            accessToken: 'test-token',
            activeFarmId: 'F1',
          ),
        ),
        trackDraftRepositoryProvider.overrideWithValue(
          FakeTrackDraftRepository(
            sourcePoints: squarePoints(),
            totalRaw: 8,
          ),
        ),
        fenceAnalyticsSinkProvider.overrideWithValue(analyticsSink),
      ],
      child: MaterialApp.router(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Future<void> pumpForm(
    WidgetTester tester, {
    UserRole role = UserRole.owner,
    List<Map<String, dynamic>> fences = const [],
  }) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(app(role: role));
      await tester.pumpAndSettle();
    }, () => mockClient(fences: fences));
  }

  Future<void> openNewForm(WidgetTester tester) async {
    await http.runWithClient(() async {
      await tester.tap(find.byKey(const Key('open-form')));
      await tester.pumpAndSettle();
    }, () => mockClient());
  }

  Finder entry() => find.byKey(const Key('fence-form-track-draft-entry'));

  testWidgets('entry card visible for owner (canEditFence=true)',
      (tester) async {
    await pumpForm(tester);
    await openNewForm(tester);
    expect(find.byType(FenceFormPage), findsOneWidget);
    expect(entry(), findsOneWidget);
  });

  testWidgets('entry card hidden for worker (canEditFence=false)',
      (tester) async {
    await pumpForm(tester, role: UserRole.worker);
    await http.runWithClient(() async {
      await tester.tap(find.byKey(const Key('open-form')));
      await tester.pumpAndSettle();
    }, () => mockClient());
    expect(find.byType(FenceFormPage), findsOneWidget);
    expect(entry(), findsNothing);
  });

  testWidgets('offline tap shows hint and does not open the wizard',
      (tester) async {
    await pumpForm(tester);
    await openNewForm(tester);

    offline = _OfflineMode.clientException;
    await http.runWithClient(() async {
      await tester.ensureVisible(entry());
      await tester.tap(entry());
      await tester.pumpAndSettle();
    }, () => mockClient());

    expect(find.byType(TrackDraftFlow), findsNothing);
    expect(find.text('当前离线，生成围栏草图需要网络连接'), findsOneWidget);
  });

  testWidgets(
      'mobile transport failure (SocketException) also triggers the offline '
      'hint instead of failing silently (review 中1)', (tester) async {
    await pumpForm(tester);
    await openNewForm(tester);

    offline = _OfflineMode.socketException;
    await http.runWithClient(() async {
      await tester.ensureVisible(entry());
      await tester.tap(entry());
      await tester.pumpAndSettle();
    }, () => mockClient());

    expect(find.byType(TrackDraftFlow), findsNothing);
    expect(find.text('当前离线，生成围栏草图需要网络连接'), findsOneWidget);
  });

  testWidgets(
      'wizard confirm loads vertices and create save body carries '
      'generationMetadata', (tester) async {
    await pumpForm(tester);
    await openNewForm(tester);

    // Entry → wizard (mobile form factor → three-step wizard).
    await http.runWithClient(() async {
      await tester.ensureVisible(entry());
      await tester.tap(entry());
      await tester.pumpAndSettle();
    }, () => mockClient());
    expect(find.byType(TrackDraftFlow), findsOneWidget);

    // Step 1: pick the only device, advance to range.
    await tester.tap(find.byKey(const Key('track-draft-device-row-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('track-draft-device-next')));
    await tester.pumpAndSettle();
    // Step 2: default 14-day range → generate preview.
    await tester.tap(find.byKey(const Key('track-draft-generate')));
    await tester.pumpAndSettle();
    // Step 3: confirm → vertices + metadata flow back to the form.
    await tester.tap(find.byKey(const Key('track-draft-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(FenceFormPage), findsOneWidget);

    // Track-loaded drafts hide the free-draw toggle (integration-test
    // feedback #3: with 30+ loaded vertices a stray "start drawing" tap
    // wrecks the shape — vertex tools cover the adjustment need instead).
    expect(find.byKey(const Key('fence-form-draw-toggle')), findsNothing);

    // Analytics: enter + generate success (device/point counts) + loaded.
    final names = analyticsSink.events.map((e) => e.name).toList();
    expect(names, contains(FenceAnalyticsEventName.trackDraftWizardEnter));
    expect(names, contains(FenceAnalyticsEventName.trackDraftGenerateSuccess));
    expect(names, contains(FenceAnalyticsEventName.trackDraftLoadedIntoForm));
    final gen = analyticsSink.events.firstWhere(
      (e) => e.name == FenceAnalyticsEventName.trackDraftGenerateSuccess,
    );
    expect(gen.parameters?[FenceAnalyticsParamKey.deviceCount], 1);
    expect(
      (gen.parameters?[FenceAnalyticsParamKey.pointCount] as int) > 0,
      isTrue,
    );

    // Suggested name prefilled; save and capture the create body.
    await http.runWithClient(() async {
      await tester.ensureVisible(find.byKey(const Key('fence-form-save')));
      await tester.tap(find.byKey(const Key('fence-form-save')));
      await tester.pumpAndSettle();
    }, () => mockClient());

    expect(capturedPosts, hasLength(1));
    final metadata =
        capturedPosts.single['generationMetadata'] as Map<String, dynamic>?;
    expect(metadata, isNotNull);
    expect(metadata!['method'], 'DEVICE_TRACK');
    expect(metadata['deviceIds'], [1]);
    expect(metadata['generatedAt'], isA<String>());
    expect(metadata['startTime'], isA<String>());
    expect(metadata['hullMethod'], isNotNull);
  });

  testWidgets('edit save body never carries generationMetadata (语义锁)',
      (tester) async {
    await pumpForm(tester, fences: [fence7]);
    await http.runWithClient(() async {
      await tester.tap(find.byKey(const Key('open-edit-form')));
      await tester.pumpAndSettle();
    }, () => mockClient(fences: [fence7]));
    expect(find.byType(FenceFormPage), findsOneWidget);
    // No entry card in edit mode.
    expect(entry(), findsNothing);

    await http.runWithClient(() async {
      await tester.ensureVisible(find.byKey(const Key('fence-form-save')));
      await tester.tap(find.byKey(const Key('fence-form-save')));
      await tester.pumpAndSettle();
    }, () => mockClient(fences: [fence7]));

    expect(capturedPosts, isEmpty);
    expect(capturedPuts, hasLength(1));
    expect(
      capturedPuts.single.body.containsKey('generationMetadata'),
      isFalse,
    );
    expect(capturedPuts.single.body['name'], 'North Pasture');
  });

  testWidgets(
      'save with 403 QUOTA_EXCEEDED shows the quota copy, not the generic '
      'save-failed text (review 中2, spec §5.5 兜底)', (tester) async {
    await pumpForm(tester);
    await openNewForm(tester);
    saveQuotaExceeded = true;

    await tester.enterText(
      find.byKey(const Key('fence-form-name')),
      'Quota Fence',
    );
    await http.runWithClient(() async {
      await tester.ensureVisible(find.byKey(const Key('fence-form-save')));
      await tester.tap(find.byKey(const Key('fence-form-save')));
      await tester.pumpAndSettle();
    }, () => mockClient());

    // Still on the form; the dedicated quota copy is shown.
    expect(find.byType(FenceFormPage), findsOneWidget);
    expect(find.text('围栏数量已达套餐上限，请升级套餐或删除闲置围栏'),
        findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
  });
}
