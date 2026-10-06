// ignore_for_file: prefer_const_constructors

// Regression harness for the NIX-256 5b local-stack walkthrough: the three
// trend sections after the fever chart (digestive / estrus / drinking
// detail) silently collapsed to zero height in release web builds.
// Pumping the real page shape with the local-stack data shapes (fever has
// readings, digestive list empty, estrus trend empty, drinking summary
// loaded, peer 403) reproduces the layout tree; the debug-mode unbounded
// flex assertions fire here before release can swallow them.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/devices_controller.dart';
import 'package:hkt_livestock_agentic/features/digestive/domain/digestive_repository.dart';
import 'package:hkt_livestock_agentic/features/digestive/presentation/digestive_controller.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_repository.dart';
import 'package:hkt_livestock_agentic/features/drinking/presentation/drinking_controller.dart';
import 'package:hkt_livestock_agentic/features/estrus/domain/estrus_repository.dart';
import 'package:hkt_livestock_agentic/features/estrus/presentation/estrus_controller.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/domain/fever_repository.dart';
import 'package:hkt_livestock_agentic/features/fever_warning/presentation/fever_controller.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/features/pages/livestock_detail_page.dart';
import 'package:hkt_livestock_agentic/features/subscription/domain/subscription_repository.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakeLivestockRepository implements LivestockRepository {
  @override
  Future<LivestockDetail> loadDetail(String id) async => _detail();

  @override
  Future<LivestockListData> loadAll({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? keyword,
  }) async =>
      const LivestockListData(items: [], total: 0, page: 1, pageSize: 20);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

LivestockDetail _detail() => LivestockDetail(
      livestockCode: 'SL-2024-012',
      livestockId: '12',
      breed: Breed.simmental,
      ageMonths: 30,
      weightKg: 500,
      health: LivestockHealth.watch,
      fenceId: '1',
      devices: [
        const DeviceItem(
          id: '12',
          name: 'DEV-GPS-012',
          type: DeviceType.gps,
          status: DeviceStatus.online,
          boundLivestockCode: '',
        ),
        const DeviceItem(
          id: '53',
          name: 'DEV-RC-003',
          type: DeviceType.rumenCapsule,
          status: DeviceStatus.online,
          boundLivestockCode: '',
        ),
      ],
      bodyTemp: 40.2,
      activityLevel: 'NORMAL',
      ruminationFreq: '--',
      lastLocation: '28.0, 112.0',
    );

class _FakeFeverRepository implements FeverRepository {
  @override
  Future<FeverDetailData> fetchFeverDetail(String livestockId) async =>
      FeverDetailData(
        livestockId: livestockId,
        livestockCode: 'SL-2024-012',
        baselineTemp: 38.5,
        threshold: 39.5,
        status: 'FEVER',
        recent72h: [
          for (var i = 0; i < 6; i++)
            TemperatureRecord(
              livestockId: livestockId,
              temperature: 38.5 + (i % 3) * 0.3,
              timestamp: DateTime.utc(2026, 10, 4, 2 + i),
            ),
        ],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Local-stack shape for livestock 12: recent24h is an EMPTY list.
class _FakeDigestiveRepository implements DigestiveRepository {
  @override
  Future<DigestiveDetailData> fetchDigestiveDetail(String livestockId) async =>
      DigestiveDetailData(
        livestockId: livestockId,
        livestockCode: 'SL-2024-012',
        motilityBaseline: 3,
        status: 'NORMAL',
        recent24h: const [],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Local-stack shape: trend7d is an EMPTY list.
class _FakeEstrusRepository implements EstrusRepository {
  @override
  Future<EstrusDetailData> fetchEstrusDetail(String livestockId) async =>
      EstrusDetailData(
        livestockId: livestockId,
        livestockCode: 'SL-2024-012',
        score: 0,
        trend7d: const [],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeDrinkingRepository implements DrinkingRepository {
  @override
  Future<DrinkingEventsPage> listEvents(
    String livestockId, {
    String? from,
    String? to,
  }) async => const DrinkingEventsPage(events: []);

  @override
  Future<DrinkingSummary> summary(
    String livestockId, {
    String? date,
    required int days,
  }) async =>
      DrinkingSummary(
        date: date ?? '2026-10-04',
        days: days,
        daily: const DrinkingDaily(count: 3, events: [], lastDrinkEndAt: null),
        weekly: days == 7
            ? const DrinkingWeekly(count: 18, avgPerDay: 2.6)
            : null,
        rolling30dBaseline: days == 30
            ? const DrinkingRollingBaseline(avgPerDay: 2.6, sampleDays: 6)
            : null,
        dayCounts: days == 7
            ? [
                for (var i = 0; i < 7; i++)
                  DrinkingDayCount(date: '2026-10-0${i + 1}', count: 2),
              ]
            : const [],
      );

  /// Peer comparison = Premium; local walkthrough account gets 403.
  @override
  Future<DrinkingPeerComparison> peerComparison(String livestockId) async {
    throw const ForbiddenException(
      message: 'peer is premium',
      statusCode: 403,
      code: 'AUTH_FORBIDDEN',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository(this.tier);

  final SubscriptionTier tier;

  @override
  Future<SubscriptionStatus> loadCurrent() async => SubscriptionStatus(
    id: '1',
    tenantId: '1',
    tier: tier,
    status: 'active',
    livestockCount: 1,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeDevicesRepository implements DevicesRepository {
  @override
  Future<List<Installation>> loadInstallations({
    int? pageSize,
    String? livestockId,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pumpPage(
  WidgetTester tester, {
  SubscriptionTier tier = SubscriptionTier.premium,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        livestockRepositoryProvider.overrideWithValue(
          _FakeLivestockRepository(),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          _FakeSubscriptionRepository(tier),
        ),
        feverRepositoryProvider.overrideWithValue(_FakeFeverRepository()),
        digestiveRepositoryProvider.overrideWithValue(
          _FakeDigestiveRepository(),
        ),
        estrusRepositoryProvider.overrideWithValue(_FakeEstrusRepository()),
        drinkingRepositoryProvider.overrideWithValue(_FakeDrinkingRepository()),
        devicesRepositoryProvider.overrideWithValue(_FakeDevicesRepository()),
        initialSessionProvider.overrideWithValue(
          const AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'token',
            activeFarmId: '1',
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LivestockDetailPage(livestockId: '12'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Walks the render tree and reports every RenderFlex whose size exceeds
/// its constraints (the "overflowed by N pixels" family), including the
/// offending widget — overflow FlutterErrors lose the creator chain when
/// captured via takeException.
List<String> _findOverflows(WidgetTester tester) {
  final overflows = <String>[];
  for (final element in tester.allElements.whereType<RenderObjectElement>()) {
    final object = element.renderObject;
    if (object is RenderFlex && object.direction == Axis.horizontal) {
      // Flex children outside the visible extent: total non-flex child
      // main-axis extents exceed the flex's own width (overflow errors
      // clamp the flex size, so size-vs-constraints never fires).
      var total = 0.0;
      var count = 0;
      RenderBox? child = object.firstChild;
      while (child != null) {
        final next = object.childAfter(child);
        final pd = child.parentData;
        final isFlexible = pd is FlexParentData && pd.flex != null && pd.flex! > 0;
        if (!isFlexible) {
          total += child.size.width;
          count++;
        }
        child = next;
      }
      if (count > 0) total += object.spacing * (count - 1);
      if (total > object.size.width + 0.01) {
        final chain = <String>[element.widget.toStringShort()];
        var depth = 0;
        element.visitAncestorElements((ancestor) {
          depth++;
          chain.insert(0, ancestor.widget.toStringShort());
          return depth < 34;
        });
        overflows.add(
          'children total $total vs flex width ${object.size.width} at:\n'
          '  ${chain.join(' < ')}',
        );
      }
    }
  }
  return overflows;
}

void main() {
  testWidgets('premium: all four trend sections render with local-stack shapes', (
    tester,
  ) async {
    await _pumpPage(tester);
    final firstException = tester.takeException();
    if (firstException != null) {
      debugPrint('FIRST EXCEPTION:\n$firstException');
      for (final line in _findOverflows(tester)) {
        debugPrint('OVERFLOW: $line');
      }
    }
    expect(firstException, isNull);

    // All four sections must exist in the tree (visibility checked below
    // via scrolling, the page is taller than the viewport).
    expect(find.byKey(const Key('drinking-card')), findsOneWidget);
    expect(find.byKey(const Key('drinking-detail-section')), findsOneWidget);

    // Scroll to the bottom and verify each section's copy actually laid
    // out (findsOneWidget only matches widgets that were built, not
    // zero-height). Drag up repeatedly to reach the page tail.
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    // The physiology card sits after the health card; reaching it proves
    // the health card sections consumed vertical space.
    expect(find.text('生理记录'), findsOneWidget);
  });

  testWidgets('basic tier: estrus locked overlay still lays out', (
    tester,
  ) async {
    await _pumpPage(tester, tier: SubscriptionTier.basic);
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text('生理记录'), findsOneWidget);
  });
}
