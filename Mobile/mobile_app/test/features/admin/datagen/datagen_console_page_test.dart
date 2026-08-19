// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/data/datagen_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/domain/datagen_models.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/presentation/datagen_controller.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/presentation/datagen_console_page.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class _FakeRepository implements DatagenApiRepository {
  DatagenRules? savedRules;

  @override
  Future<List<DatagenFarm>> loadFarms() async => const [
        DatagenFarm(
          farmId: 1,
          farmName: 'Main Ranch',
          tenantId: 2,
          tenantName: 'Demo Tenant',
          enabled: true,
          selectedDeviceCount: 2,
        ),
      ];

  @override
  Future<DatagenConsoleData> loadConsole(int farmId) async => _console();

  @override
  Future<DatagenConsoleData> updateControl({
    required int farmId,
    required bool enabled,
    required List<int> deviceIds,
  }) async => _console();

  @override
  Future<DatagenConsoleData> updateRules({
    required int farmId,
    required DatagenRules rules,
  }) async {
    savedRules = rules;
    return _console();
  }

  @override
  Future<DatagenClearResult> previewClear({
    required int farmId,
    required String rangeType,
    DateTime? from,
    DateTime? to,
  }) async => _clearResult();

  @override
  Future<DatagenClearResult> clear({
    required int farmId,
    required String rangeType,
    required String confirmText,
    DateTime? from,
    DateTime? to,
  }) async => _clearResult();

  DatagenConsoleData _console() => DatagenConsoleData(
        farm: const DatagenFarm(
          farmId: 1,
          farmName: 'Main Ranch',
          tenantId: 2,
          tenantName: 'Demo Tenant',
          enabled: true,
          selectedDeviceCount: 2,
        ),
        enabled: true,
        scenario: const DatagenScenario(
          id: 3,
          name: '默认持续合成',
          type: 'normal',
        ),
        rules: const DatagenRules(
          trackerIntervalSeconds: 600,
          capsuleIntervalSeconds: 1200,
          fenceExcursionProbability: 0.05,
          fenceExcursionMinMinutes: 10,
          fenceExcursionMaxMinutes: 20,
          healthEventProbability: 0.01,
          feverDurationMinMinutes: 180,
          feverDurationMaxMinutes: 300,
          motilityDurationMinMinutes: 480,
          motilityDurationMaxMinutes: 720,
        ),
        devices: const [
          DatagenDevice(
            deviceId: 5,
            deviceCode: 'TRK-5',
            devEui: 'eui-5',
            deviceType: 'TRACKER',
            livestockId: 10,
            livestockCode: 'ST-10',
            runtimeStatus: 'online',
            selected: true,
            eligible: true,
            ineligibleReason: null,
            lastGeneratedAt: null,
          ),
          DatagenDevice(
            deviceId: 6,
            deviceCode: 'CAP-6',
            devEui: 'eui-6',
            deviceType: 'CAPSULE',
            livestockId: 10,
            livestockCode: 'ST-10',
            runtimeStatus: 'offline',
            selected: true,
            eligible: true,
            ineligibleReason: null,
            lastGeneratedAt: null,
          ),
        ],
        stats: const DatagenStats(
          statsTimeZone: 'Asia/Shanghai',
          selectedTotal: 2,
          selectedTrackerCount: 1,
          selectedCapsuleCount: 1,
          todayTelemetryRows: 2,
          todayGpsRows: 1,
          todayHealthRows: 3,
          lastGeneratedAt: null,
        ),
        operations: const [
          DatagenOperation(
            id: 9,
            action: 'START',
            operatorId: 1,
            operatorRole: 'PLATFORM_ADMIN',
            occurredAt: null,
            summaryKey: 'datagenConsoleOperationStart',
          ),
          DatagenOperation(
            id: 10,
            action: 'UPDATE_RULES',
            operatorId: 1,
            operatorRole: 'B2B_ADMIN',
            occurredAt: null,
            summaryKey: 'datagenConsoleOperationUpdateRules',
          ),
        ],
      );

  DatagenClearResult _clearResult() => const DatagenClearResult(
        telemetryRows: 2,
        gpsRows: 1,
        temperatureRows: 1,
        motilityRows: 1,
        activityRows: 1,
        estrusRows: 1,
        anomalyRows: 0,
        alertRows: 0,
        unattributableHealthRows: 0,
        unattributableAlertRows: 0,
        limitationKey: 'datagenConsoleCrossFarmLimit',
      );
}

void main() {
  testWidgets('renders datagen console with localized values', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = _FakeRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        datagenApiRepositoryProvider.overrideWithValue(fake),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DatagenConsolePage(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('datagen-console-page')), findsOneWidget);
    expect(find.text('设备范围'), findsOneWidget);
    expect(find.text('数据清理'), findsOneWidget);
    expect(find.text('操作记录'), findsOneWidget);
    expect(find.text('围栏外出触发概率'), findsOneWidget);
    expect(find.text('围栏外出持续范围'), findsOneWidget);
    expect(find.text('发热持续范围'), findsOneWidget);
    expect(find.text('消化动力下降持续范围'), findsOneWidget);
    expect(find.textContaining('50/50'), findsOneWidget);

    await tester.tap(find.text('保存规则'));
    await tester.pumpAndSettle();
    expect(fake.savedRules?.trackerIntervalSeconds, 600);
    expect(fake.savedRules?.capsuleIntervalSeconds, 1200);
    expect(fake.savedRules?.fenceExcursionProbability, 0.05);
    expect(fake.savedRules?.healthEventProbability, 0.01);
    expect(fake.savedRules?.feverDurationMinMinutes, 180);
    expect(fake.savedRules?.motilityDurationMinMinutes, 480);

    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    expect(find.text('追踪器'), findsOneWidget);
    expect(find.text('胶囊'), findsOneWidget);
    expect(find.text('在线'), findsOneWidget);
    expect(find.text('离线'), findsOneWidget);

    await tester.tap(find.byType(Tab).at(3));
    await tester.pumpAndSettle();
    expect(find.textContaining('平台管理员'), findsOneWidget);
    expect(find.text('调整仿真规则'), findsOneWidget);
  });
}
