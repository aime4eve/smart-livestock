import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/data/datagen_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/domain/datagen_models.dart';
import 'package:hkt_livestock_agentic/features/admin/datagen/presentation/datagen_controller.dart';

class _FakeRepository implements DatagenApiRepository {
  bool enabledRequested = false;
  List<int>? savedDeviceIds;

  @override
  Future<List<DatagenFarm>> loadFarms() async => [
        const DatagenFarm(
          farmId: 1,
          farmName: 'Main Ranch',
          tenantId: 2,
          tenantName: 'Demo',
          enabled: false,
          selectedDeviceCount: 1,
        ),
      ];

  @override
  Future<DatagenConsoleData> loadConsole(int farmId) async => _console();

  @override
  Future<DatagenClearResult> previewClear({
    required int farmId,
    required String rangeType,
    DateTime? from,
    DateTime? to,
  }) async =>
      _result(0);

  @override
  Future<DatagenClearResult> clear({
    required int farmId,
    required String rangeType,
    required String confirmText,
    DateTime? from,
    DateTime? to,
  }) async =>
      _result(3);

  @override
  Future<DatagenConsoleData> updateControl({
    required int farmId,
    required bool enabled,
    required List<int> deviceIds,
  }) async {
    enabledRequested = enabled;
    savedDeviceIds = deviceIds;
    return _console(enabled: enabled, selected: enabled);
  }

  DatagenConsoleData _console({
    bool enabled = false,
    bool selected = true,
  }) =>
      DatagenConsoleData(
        farm: DatagenFarm(
          farmId: 1,
          farmName: 'Main Ranch',
          tenantId: 2,
          tenantName: 'Demo',
          enabled: enabled,
          selectedDeviceCount: selected ? 1 : 0,
        ),
        enabled: enabled,
        scenario: const DatagenScenario(
          id: 3,
          name: '默认持续合成',
          type: 'NORMAL',
        ),
        devices: [
          DatagenDevice(
            deviceId: 5,
            deviceCode: 'TRK-5',
            devEui: 'eui-5',
            deviceType: 'TRACKER',
            livestockId: 10,
            livestockCode: 'ST-10',
            runtimeStatus: 'online',
            selected: selected,
            eligible: true,
            ineligibleReason: null,
            lastGeneratedAt: null,
          ),
        ],
        stats: const DatagenStats(
          statsTimeZone: 'Asia/Shanghai',
          selectedTotal: 1,
          selectedTrackerCount: 1,
          selectedCapsuleCount: 0,
          todayTelemetryRows: 0,
          todayGpsRows: 0,
          todayHealthRows: 0,
          lastGeneratedAt: null,
        ),
        operations: const [],
      );

  DatagenClearResult _result(int total) => DatagenClearResult(
        telemetryRows: total,
        gpsRows: 0,
        temperatureRows: 0,
        motilityRows: 0,
        activityRows: 0,
        estrusRows: 0,
        anomalyRows: 0,
        alertRows: 0,
        unattributableHealthRows: 0,
        unattributableAlertRows: 0,
        limitationKey: 'datagenConsoleCrossFarmLimit',
      );
}

void main() {
  test('loads farms and initializes selected devices', () async {
    final fake = _FakeRepository();
    final container = ProviderContainer(
      overrides: [datagenApiRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container.read(datagenControllerProvider.notifier).load();

    final state = container.read(datagenControllerProvider);
    expect(state.selectedFarmId, 1);
    expect(state.selectedDeviceIds, {5});
    expect(state.error, isNull);
  });

  test('starting with no selected device is rejected', () async {
    final fake = _FakeRepository();
    final container = ProviderContainer(
      overrides: [datagenApiRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    final controller = container.read(datagenControllerProvider.notifier);
    await controller.load();
    controller.toggleDevice(5, false);

    await controller.toggleRun();

    expect(container.read(datagenControllerProvider).error,
        'error.datagen.devicesRequired');
    expect(fake.enabledRequested, isFalse);
    expect(fake.savedDeviceIds, isNull);
  });

  test('saving devices updates control request and console', () async {
    final fake = _FakeRepository();
    final container = ProviderContainer(
      overrides: [datagenApiRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    final controller = container.read(datagenControllerProvider.notifier);
    await controller.load();

    await controller.toggleRun();

    expect(fake.enabledRequested, true);
    expect(fake.savedDeviceIds, [5]);
    expect(container.read(datagenControllerProvider).console?.enabled, true);
  });
}
