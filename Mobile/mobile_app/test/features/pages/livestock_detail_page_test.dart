// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/devices_controller.dart';
import 'package:hkt_livestock_agentic/features/digestive/domain/digestive_repository.dart';
import 'package:hkt_livestock_agentic/features/digestive/presentation/digestive_controller.dart';
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
  _FakeLivestockRepository({this.devices = const []});

  final List<DeviceItem> devices;
  int loadAllCalls = 0;

  @override
  Future<LivestockDetail> loadDetail(String id) async =>
      _detail(devices: devices);

  @override
  Future<LivestockListData> loadAll({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? keyword,
  }) async {
    loadAllCalls++;
    return const LivestockListData(
      items: [],
      total: 0,
      page: 1,
      pageSize: 20,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeDevicesRepository implements DevicesRepository {
  _FakeDevicesRepository({this.installations = const [], this.devices = const []});

  final List<Installation> installations;
  final List<DeviceItem> devices;
  final List<String> uninstalledIds = [];
  String? lastInstallationsLivestockId;
  bool? lastUnboundOnly;
  final List<String> loadDevicesKeywords = [];
  final List<int> loadDevicePages = [];

  @override
  Future<DevicesListData> loadDevices({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    bool? unboundOnly,
  }) async {
    loadDevicesKeywords.add(keyword ?? '');
    loadDevicePages.add(page);
    lastUnboundOnly = unboundOnly;
    var items = devices;
    if (unboundOnly == true) {
      final boundIds = installations
          .where((i) => i.active)
          .map((i) => i.deviceId)
          .toSet();
      items = items.where((d) => !boundIds.contains(d.id)).toList();
    }
    if (keyword != null && keyword.isNotEmpty) {
      final q = keyword.toLowerCase();
      items = items
          .where(
            (d) =>
                d.name.toLowerCase().contains(q) ||
                (d.serialNo ?? '').toLowerCase().contains(q) ||
                (d.devEui ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, items.length);
    final pageItems =
        start >= items.length ? <DeviceItem>[] : items.sublist(start, end);
    return DevicesListData(
      items: pageItems,
      total: items.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<Installation>> loadInstallations({int? pageSize, String? livestockId}) async {
    lastInstallationsLivestockId = livestockId;
    return installations;
  }

  @override
  Future<void> uninstall(String installationId) async {
    uninstalledIds.add(installationId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<SubscriptionStatus> loadCurrent() async => const SubscriptionStatus(
    id: '1',
    tenantId: '1',
    tier: SubscriptionTier.premium,
    status: 'active',
    livestockCount: 1,
    calculatedDeviceFee: 0,
    calculatedTierFee: 0,
    calculatedTotal: 0,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeFeverRepository implements FeverRepository {
  @override
  Future<FeverDetailData> fetchFeverDetail(String livestockId) async =>
      FeverDetailData(
        livestockId: livestockId,
        livestockCode: 'ST-10',
        baselineTemp: 38.5,
        threshold: 39.5,
        status: 'NORMAL',
        recent72h: [
          TemperatureRecord(
            livestockId: livestockId,
            temperature: 38.00,
            timestamp: DateTime.utc(2026, 8, 26, 7),
          ),
          TemperatureRecord(
            livestockId: livestockId,
            temperature: 38.01,
            timestamp: DateTime.utc(2026, 8, 26, 8),
          ),
          TemperatureRecord(
            livestockId: livestockId,
            temperature: 38.02,
            timestamp: DateTime.utc(2026, 8, 26, 9),
          ),
        ],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeDigestiveRepository implements DigestiveRepository {
  @override
  Future<DigestiveDetailData> fetchDigestiveDetail(String livestockId) async =>
      DigestiveDetailData(
        livestockId: livestockId,
        livestockCode: 'ST-10',
        motilityBaseline: 3,
        status: 'NORMAL',
        recent24h: [
          MotilityRecord(
            livestockId: livestockId,
            frequency: 3,
            intensity: 50,
            timestamp: DateTime.utc(2026, 8, 26, 8),
          ),
          MotilityRecord(
            livestockId: livestockId,
            frequency: 2.7,
            intensity: 45,
            timestamp: DateTime.utc(2026, 8, 26, 9),
          ),
        ],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeEstrusRepository implements EstrusRepository {
  @override
  Future<EstrusDetailData> fetchEstrusDetail(String livestockId) async =>
      EstrusDetailData(
        livestockId: livestockId,
        livestockCode: 'ST-10',
        score: 0,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

LivestockDetail _detail({List<DeviceItem> devices = const []}) =>
    LivestockDetail(
      livestockCode: 'ST-10',
      livestockId: '10',
      breed: Breed.simmental,
      ageMonths: 30,
      weightKg: 500,
      health: LivestockHealth.healthy,
      fenceId: '1',
      devices: devices,
      bodyTemp: 38.5,
      activityLevel: 'NORMAL',
      ruminationFreq: '3',
      lastLocation: '28.0, 112.0',
    );

void main() {
  testWidgets('livestock detail shows rumen motility trend', (tester) async {    tester.view.physicalSize = const Size(1000, 1600);
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
            _FakeSubscriptionRepository(),
          ),
          feverRepositoryProvider.overrideWithValue(_FakeFeverRepository()),
          digestiveRepositoryProvider.overrideWithValue(
            _FakeDigestiveRepository(),
          ),
          estrusRepositoryProvider.overrideWithValue(_FakeEstrusRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LivestockDetailPage(livestockId: '10'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('24小时蠕动曲线'), findsOneWidget);
    expect(find.text('实测蠕动'), findsOneWidget);
    expect(find.text('基线参考'), findsWidgets);

    final axisLabels = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .where((text) => text.endsWith('°'))
        .toList();
    expect(axisLabels, isNotEmpty);
    expect(
      axisLabels.toSet().length,
      axisLabels.length,
      reason: 'temperature axis labels must not duplicate after formatting',
    );

    final temperatureChart = tester
        .widgetList<LineChart>(find.byType(LineChart))
        .firstWhere(
          (chart) => chart.data.lineBarsData.any(
            (bar) => bar.spots.any((spot) => spot.y > 35 && spot.y < 42),
          ),
        );
    final actualTemperatureBar = temperatureChart.data.lineBarsData.firstWhere(
      (bar) => bar.spots.any((spot) => spot.y > 35 && spot.y < 42),
    );
    final temperatureSpot = actualTemperatureBar.spots.first;
    final tooltip = temperatureChart.data.lineTouchData.touchTooltipData;
    final touchedSpot = LineBarSpot(actualTemperatureBar, 0, temperatureSpot);

    expect(tooltip.getTooltipColor(touchedSpot), AppColors.surfaceAlt);
    final tooltipItems = tooltip.getTooltipItems([touchedSpot]);
    expect(tooltipItems.single?.text, contains('°C'));
    expect(tooltipItems.single?.text, contains('/'));
    final sideTitles = temperatureChart.data.titlesData.leftTitles.sideTitles;
    expect(sideTitles.interval, greaterThanOrEqualTo(0.1));
    expect(sideTitles.minIncluded, isFalse);
    expect(sideTitles.maxIncluded, isFalse);
  });

  testWidgets('unbind device calls uninstall and shows success', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const device = DeviceItem(
      id: '5',
      name: 'GPS-001',
      type: DeviceType.gps,
      status: DeviceStatus.online,
      boundLivestockCode: 'ST-10',
    );
    final devicesRepo = _FakeDevicesRepository(
      installations: const [
        Installation(
          id: '77',
          deviceId: '5',
          livestockId: '10',
          installedAt: '2026-09-01T00:00:00Z',
          active: true,
        ),
      ],
    );
    final livestockRepo = _FakeLivestockRepository(devices: const [device]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          livestockRepositoryProvider.overrideWithValue(
            livestockRepo,
          ),
          devicesRepositoryProvider.overrideWithValue(devicesRepo),
          subscriptionRepositoryProvider.overrideWithValue(
            _FakeSubscriptionRepository(),
          ),
          feverRepositoryProvider.overrideWithValue(_FakeFeverRepository()),
          digestiveRepositoryProvider.overrideWithValue(
            _FakeDigestiveRepository(),
          ),
          estrusRepositoryProvider.overrideWithValue(_FakeEstrusRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LivestockDetailPage(livestockId: '10'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Activate the (non-autoDispose) list provider before unbinding.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LivestockDetailPage)),
    );
    await container.read(livestockListControllerProvider.future);
    final loadAllBefore = livestockRepo.loadAllCalls;
    expect(loadAllBefore, greaterThanOrEqualTo(1));

    await tester.tap(find.byKey(const Key('livestock-unbind-device-5')));
    await tester.pumpAndSettle();

    expect(find.text('确认解绑？'), findsOneWidget);
    expect(find.text('确定要将设备 GPS-001 与该牲畜解绑吗？解绑后设备可重新绑定到其他牲畜。'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('解绑'),
      ),
    );
    await tester.pumpAndSettle();

    expect(devicesRepo.uninstalledIds, ['77']);
    expect(find.text('解绑成功'), findsOneWidget);
    // Installations must be fetched scoped to this livestock so the lookup
    // stays correct regardless of how many devices the farm has bound.
    expect(devicesRepo.lastInstallationsLivestockId, '10');

    // Unbind must invalidate the list provider so the stale cached list
    // (still showing old bound devices) is refetched when user navigates back.
    await container.read(livestockListControllerProvider.future);
    expect(livestockRepo.loadAllCalls, greaterThan(loadAllBefore));
  });

  testWidgets('bind sheet lists only unbound devices and searches server-side', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const boundDevice = DeviceItem(
      id: '5',
      name: 'GPS-001',
      type: DeviceType.gps,
      status: DeviceStatus.online,
      boundLivestockCode: 'ST-10',
    );
    const boundElsewhere = DeviceItem(
      id: '80',
      name: 'CAP-BOUND',
      type: DeviceType.rumenCapsule,
      status: DeviceStatus.offline,
      boundLivestockCode: '',
    );
    const candidateAlpha = DeviceItem(
      id: '81',
      name: 'CAP-ALPHA',
      type: DeviceType.rumenCapsule,
      status: DeviceStatus.offline,
      boundLivestockCode: '',
      devEui: 'EUI-ALPHA-01',
      serialNo: 'SN-ALPHA',
    );
    const candidateBeta = DeviceItem(
      id: '82',
      name: 'CAP-BETA',
      type: DeviceType.rumenCapsule,
      status: DeviceStatus.offline,
      boundLivestockCode: '',
      devEui: 'EUI-BETA-02',
    );
    final devicesRepo = _FakeDevicesRepository(
      devices: const [boundElsewhere, candidateAlpha, candidateBeta],
      installations: const [
        Installation(
          id: '90',
          deviceId: '80',
          livestockId: '99',
          installedAt: '2026-09-01T00:00:00Z',
          active: true,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          livestockRepositoryProvider.overrideWithValue(
            _FakeLivestockRepository(devices: const [boundDevice]),
          ),
          devicesRepositoryProvider.overrideWithValue(devicesRepo),
          subscriptionRepositoryProvider.overrideWithValue(
            _FakeSubscriptionRepository(),
          ),
          feverRepositoryProvider.overrideWithValue(_FakeFeverRepository()),
          digestiveRepositoryProvider.overrideWithValue(
            _FakeDigestiveRepository(),
          ),
          estrusRepositoryProvider.overrideWithValue(_FakeEstrusRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LivestockDetailPage(livestockId: '10'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('livestock-bind-device')));
    await tester.pumpAndSettle();

    // Initial load pages the server with unboundOnly so only bindable
    // devices show up, no matter how large the farm inventory is.
    expect(devicesRepo.lastUnboundOnly, isTrue);
    expect(find.byKey(const Key('bind-device-80')), findsNothing);
    expect(find.byKey(const Key('bind-device-81')), findsOneWidget);
    expect(find.byKey(const Key('bind-device-82')), findsOneWidget);

    // Keyword search is debounced and delegated to the server; serial no.
    // and EUI are matched server-side too.
    await tester.enterText(find.byKey(const Key('bind-device-search')), 'alpha');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(devicesRepo.loadDevicesKeywords.last, 'alpha');
    expect(find.byKey(const Key('bind-device-81')), findsOneWidget);
    expect(find.byKey(const Key('bind-device-82')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('bind-device-search')),
      'beta-02',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bind-device-81')), findsNothing);
    expect(find.byKey(const Key('bind-device-82')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('bind-device-search')),
      'SN-ALPHA',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bind-device-81')), findsOneWidget);
    expect(find.byKey(const Key('bind-device-82')), findsNothing);
    expect(find.text('无匹配设备'), findsNothing);

    // No match shows the dedicated hint.
    await tester.enterText(find.byKey(const Key('bind-device-search')), 'zzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('无匹配设备'), findsOneWidget);

    // Clearing the query restores the full candidate list.
    await tester.enterText(find.byKey(const Key('bind-device-search')), '');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bind-device-81')), findsOneWidget);
    expect(find.byKey(const Key('bind-device-82')), findsOneWidget);
  });

  testWidgets('bind sheet loads more pages when scrolled to the bottom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 21 bindable candidates: page 1 (20) + page 2 (1) with pageSize 20.
    final candidates = List<DeviceItem>.generate(
      21,
      (i) => DeviceItem(
        id: '${100 + i}',
        name: 'CAP-${i.toString().padLeft(3, '0')}',
        type: DeviceType.rumenCapsule,
        status: DeviceStatus.offline,
        boundLivestockCode: '',
      ),
    );
    final devicesRepo = _FakeDevicesRepository(devices: candidates);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          livestockRepositoryProvider.overrideWithValue(
            _FakeLivestockRepository(),
          ),
          devicesRepositoryProvider.overrideWithValue(devicesRepo),
          subscriptionRepositoryProvider.overrideWithValue(
            _FakeSubscriptionRepository(),
          ),
          feverRepositoryProvider.overrideWithValue(_FakeFeverRepository()),
          digestiveRepositoryProvider.overrideWithValue(
            _FakeDigestiveRepository(),
          ),
          estrusRepositoryProvider.overrideWithValue(_FakeEstrusRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LivestockDetailPage(livestockId: '10'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('livestock-bind-device')));
    await tester.pumpAndSettle();

    // First page only: ListView.builder renders lazily, so verify page fetches
    // instead of off-viewport rows.
    expect(devicesRepo.loadDevicePages, [1]);
    expect(find.byKey(const Key('bind-device-100')), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -800));
    await tester.pumpAndSettle();

    // Scrolling near the bottom fetched page 2 with the remaining device.
    expect(devicesRepo.loadDevicePages, [1, 2]);
    await tester.scrollUntilVisible(
      find.byKey(const Key('bind-device-120')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('bind-device-120')), findsOneWidget);
  });

  testWidgets('bind sheet auto-fetches when a full page filters to no scroll area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Livestock already has a GPS device, so every GPS candidate is filtered
    // out client-side. Page 1 comes back full (18 GPS + 2 capsules) and
    // shrinks to 2 visible rows — pagination must continue automatically
    // instead of leaving the footer spinner spinning forever.
    final gpsPage = List<DeviceItem>.generate(
      18,
      (i) => DeviceItem(
        id: 'g${i + 1}',
        name: 'GPS-${i + 1}',
        type: DeviceType.gps,
        status: DeviceStatus.offline,
        boundLivestockCode: '',
      ),
    );
    const rc1 = DeviceItem(
      id: 'c1',
      name: 'DEV-RC-013',
      type: DeviceType.rumenCapsule,
      status: DeviceStatus.offline,
      boundLivestockCode: '',
    );
    const rc2 = DeviceItem(
      id: 'c2',
      name: 'DEV-RC-015',
      type: DeviceType.rumenCapsule,
      status: DeviceStatus.offline,
      boundLivestockCode: '',
    );
    const tailGps = DeviceItem(
      id: 'g99',
      name: 'GPS-99',
      type: DeviceType.gps,
      status: DeviceStatus.offline,
      boundLivestockCode: '',
    );
    final devicesRepo = _FakeDevicesRepository(
      devices: [...gpsPage, rc1, rc2, tailGps],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          livestockRepositoryProvider.overrideWithValue(
            _FakeLivestockRepository(
              devices: const [
                DeviceItem(
                  id: '5',
                  name: 'GPS-001',
                  type: DeviceType.gps,
                  status: DeviceStatus.online,
                  boundLivestockCode: 'ST-10',
                ),
              ],
            ),
          ),
          devicesRepositoryProvider.overrideWithValue(devicesRepo),
          subscriptionRepositoryProvider.overrideWithValue(
            _FakeSubscriptionRepository(),
          ),
          feverRepositoryProvider.overrideWithValue(_FakeFeverRepository()),
          digestiveRepositoryProvider.overrideWithValue(
            _FakeDigestiveRepository(),
          ),
          estrusRepositoryProvider.overrideWithValue(_FakeEstrusRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LivestockDetailPage(livestockId: '10'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('livestock-bind-device')));
    await tester.pumpAndSettle();

    // Page 1 was full server-side, so page 2 was auto-fetched without any
    // user scrolling, and the loading footer is gone afterwards.
    expect(devicesRepo.loadDevicePages, [1, 2]);
    expect(find.byKey(const Key('bind-device-c1')), findsOneWidget);
    expect(find.byKey(const Key('bind-device-c2')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
