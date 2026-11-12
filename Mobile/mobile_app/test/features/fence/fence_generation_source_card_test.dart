import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/fence/data/fence_dto.dart';
import 'package:hkt_livestock_agentic/features/fence/presentation/widgets/fence_generation_source_card.dart';
import 'package:hkt_livestock_agentic/features/pages/fence_page.dart';
import 'package:hkt_livestock_agentic/features/ranch/domain/ranch_models.dart';
import 'package:hkt_livestock_agentic/features/ranch/presentation/widgets/ranch_fence_tab.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Task 5: "generation source" card — shared widget rendering, both detail
/// mount points (fence page list card + ranch fence detail card), and the
/// DTO passthrough branches feeding them (spec §4.3).
void main() {
  final metadata = <String, dynamic>{
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

  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('fenceItemFromJson generationMetadata passthrough', () {
    Map<String, dynamic> baseJson() => {
          'id': 7,
          'name': 'F7',
          'type': 'polygon',
          'vertices': [
            {'lat': 28.0, 'lng': 112.0},
            {'lat': 28.01, 'lng': 112.0},
            {'lat': 28.01, 'lng': 112.01},
          ],
        };

    test('Map payload is kept as-is', () {
      final json = baseJson()..['generationMetadata'] = metadata;
      final item = fenceItemFromJson(json, 0, 0);
      expect(item.generationMetadata, isNotNull);
      expect(item.generationMetadata!['method'], 'DEVICE_TRACK');
      expect(item.generationMetadata!['deviceIds'], [101, 102]);
      expect(item.generationMetadata!['usedPoints'], 7412);
    });

    test('malformed payload degrades to null', () {
      final json = baseJson()..['generationMetadata'] = 'DEVICE_TRACK';
      expect(fenceItemFromJson(json, 0, 0).generationMetadata, isNull);
    });

    test('missing key stays null', () {
      expect(fenceItemFromJson(baseJson(), 0, 0).generationMetadata, isNull);
    });
  });

  group('RanchFenceData.fromJson generationMetadata passthrough', () {
    test('Map kept / malformed and missing degrade to null', () {
      final base = <String, dynamic>{
        'id': 'f1',
        'name': 'Zone A',
        'points': const [],
      };
      final withMeta = RanchFenceData.fromJson(
        {...base, 'generationMetadata': metadata},
      );
      expect(withMeta.generationMetadata!['method'], 'DEVICE_TRACK');
      final malformed = RanchFenceData.fromJson(
        {...base, 'generationMetadata': 42},
      );
      expect(malformed.generationMetadata, isNull);
      expect(RanchFenceData.fromJson(base).generationMetadata, isNull);
    });
  });

  group('FenceGenerationSourceCard widget', () {
    testWidgets('renders method/device count/range/generatedAt rows',
        (tester) async {
      await tester.pumpWidget(
        wrap(FenceGenerationSourceCard(metadata: metadata)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('fence-generation-source-card')),
        findsOneWidget,
      );
      expect(find.text('生成来源'), findsOneWidget);
      expect(find.text('从设备轨迹生成'), findsOneWidget);
      expect(find.text('2 台设备'), findsOneWidget);
      expect(find.textContaining('2026-10-29'), findsOneWidget);
      expect(find.textContaining('~'), findsOneWidget);
      expect(find.text('生成时间'), findsOneWidget);
    });

    testWidgets('unknown method falls back to the raw value', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FenceGenerationSourceCard(
            metadata: {'method': 'GPX_IMPORT'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('GPX_IMPORT'), findsOneWidget);
    });
  });

  group('mount point: ranch_fence_tab _FenceDetailCard', () {
    RanchFenceData fence({Map<String, dynamic>? meta}) => RanchFenceData(
          id: 'f1',
          name: 'Zone A',
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
        );

    Future<void> pumpTab(WidgetTester tester, RanchFenceData f) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        wrap(
          RanchFenceTab(
            fences: [f],
            alerts: const [],
            noGpsCount: 0,
            outsideFenceCount: 0,
            noPositionCodes: const [],
            totalLivestock: 2,
            fenceUnread: 0,
            fenceStatusMap: const {},
            livestockMarkers: const [],
            selectedFenceId: 'f1',
            onFenceSelected: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('renders source card when metadata present', (tester) async {
      await pumpTab(tester, fence(meta: metadata));
      expect(
        find.byKey(const Key('fence-generation-source-card')),
        findsOneWidget,
      );
    });

    testWidgets('hidden when metadata is null', (tester) async {
      await pumpTab(tester, fence());
      expect(
        find.byKey(const Key('fence-generation-source-card')),
        findsNothing,
      );
    });
  });

  group('mount point: fence_page _FenceCard', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      ApiClient.instance.setActiveFarmId('F1');
    });
    tearDown(() => ApiClient.instance.setActiveFarmId(null));

    http.Client mockClient({required bool withMetadata}) {
      http.Response ok(Object? data) => http.Response(
            jsonEncode({'code': 'OK', 'data': data}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
      final fenceJson = <String, dynamic>{
        'id': 7,
        'name': 'North Pasture',
        'type': 'polygon',
        'active': true,
        'vertices': [
          {'lat': 28.0, 'lng': 112.0},
          {'lat': 28.01, 'lng': 112.0},
          {'lat': 28.01, 'lng': 112.01},
        ],
        'livestockCount': 3,
        if (withMetadata) 'generationMetadata': metadata,
      };
      return MockClient((req) async {
        final path = req.url.path;
        if (path.endsWith('/fences')) return ok({'items': [fenceJson]});
        if (path.contains('/livestock')) return ok({'items': const []});
        return ok(const {});
      });
    }

    Future<void> pumpFencePage(
      WidgetTester tester, {
      required bool withMetadata,
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
            ],
            child: const MaterialApp(
              locale: Locale('zh'),
              localizationsDelegates:
                  AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: FencePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }, () => mockClient(withMetadata: withMetadata));
    }

    testWidgets('list card renders source card when metadata present',
        (tester) async {
      await pumpFencePage(tester, withMetadata: true);
      expect(find.byKey(const Key('fence-card-7')), findsOneWidget);
      expect(
        find.byKey(const Key('fence-generation-source-card')),
        findsOneWidget,
      );
    });

    testWidgets('list card hides source card when metadata null',
        (tester) async {
      await pumpFencePage(tester, withMetadata: false);
      expect(find.byKey(const Key('fence-card-7')), findsOneWidget);
      expect(
        find.byKey(const Key('fence-generation-source-card')),
        findsNothing,
      );
    });
  });
}
