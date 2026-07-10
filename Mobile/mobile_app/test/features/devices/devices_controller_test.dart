import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/devices/data/devices_api_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/devices_repository.dart';
import 'package:hkt_livestock_agentic/features/devices/presentation/devices_controller.dart';

/// Fake repo that returns configurable device lists for testing controller state.
class _FakeDevicesRepository implements DevicesRepository {
  _FakeDevicesRepository({this.total = 0});

  final int total;
  int loadCallCount = 0;
  String? lastKeyword;
  int? lastPage;

  List<DeviceItem> _devices = [];

  void setDevices(List<DeviceItem> devices) => _devices = devices;

  @override
  Future<DevicesListData> loadDevices({
    int page = 1,
    int pageSize = 20,
    String? keyword,
  }) async {
    loadCallCount++;
    lastKeyword = keyword;
    lastPage = page;
    return DevicesListData(
      items: _devices,
      total: total,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<DeviceItem> loadDetail(String id) async => _devices.first;

  @override
  Future<DeviceItem> create(Map<String, dynamic> body) async => _devices.first;

  @override
  Future<DeviceItem> update(String id, Map<String, dynamic> body) async =>
      _devices.first;

  @override
  Future<void> activate(String id) async {}

  @override
  Future<void> decommission(String id) async {}

  @override
  Future<List<DeviceLicense>> loadLicenses() async => [];

  @override
  Future<List<Installation>> loadInstallations() async => [];

  @override
  Future<List<GpsPoint>> loadLatestGps() async => [];

  @override
  Future<List<GpsPoint>> loadGpsHistory(String livestockId) async => [];

  @override
  Future<Map<String, dynamic>> loadDeviceHealth(String deviceId) async => {};
}

DeviceItem _makeDevice(String id) => DeviceItem(
      id: id,
      name: 'DEV-$id',
      type: DeviceType.gps,
      status: DeviceStatus.online,
      boundEarTag: '',
    );

void main() {
  late _FakeDevicesRepository repo;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  ProviderContainer setup({String farmId = 'farm-1'}) {
    repo = _FakeDevicesRepository(total: 25);
    repo.setDevices(List.generate(20, (i) => _makeDevice('$i')));
    return ProviderContainer(
      overrides: [
        devicesRepositoryProvider.overrideWithValue(repo),
        initialSessionProvider.overrideWithValue(
          AppSession.authenticated(
            role: UserRole.owner,
            accessToken: 'token',
            activeFarmId: farmId,
          ),
        ),
      ],
    );
  }

  test('build loads first page with correct defaults', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(devicesControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = container.read(devicesControllerProvider);
    expect(state.value, isNotNull);
    expect(state.value!.items.length, 20);
    expect(repo.lastPage, 1);
    expect(repo.lastKeyword, isNull);
  });

  test('search sets keyword and resets to page 1', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(devicesControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final controller = container.read(devicesControllerProvider.notifier);
    await controller.search('GPS-001');

    expect(repo.lastKeyword, 'GPS-001');
    expect(repo.lastPage, 1);
  });

  test('goToPage fetches the requested page', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(devicesControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final controller = container.read(devicesControllerProvider.notifier);
    // total=25, pageSize=20 → 2 pages
    expect(controller.totalPages, 2);

    await controller.goToPage(2);
    expect(repo.lastPage, 2);
  });

  test('goToPage ignores invalid page numbers', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(devicesControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final controller = container.read(devicesControllerProvider.notifier);
    final callsBefore = repo.loadCallCount;

    await controller.goToPage(0);
    await controller.goToPage(99);
    await controller.goToPage(1); // same page

    expect(repo.loadCallCount, callsBefore);
  });

  test('refresh reloads current page', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(devicesControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final controller = container.read(devicesControllerProvider.notifier);
    await controller.goToPage(2);
    final callsBefore = repo.loadCallCount;

    await controller.refresh();
    expect(repo.loadCallCount, callsBefore + 1);
    expect(repo.lastPage, 2);
  });

  test('farm switch rebuilds controller', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(devicesControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Simulate farm switch
    container.read(sessionControllerProvider.notifier).updateActiveFarm('farm-2');
    container.read(devicesControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Controller should have been rebuilt (at least 2 loads)
    expect(repo.loadCallCount, greaterThanOrEqualTo(2));
  });

  test('totalPages computed from total / pageSize', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(devicesControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final controller = container.read(devicesControllerProvider.notifier);
    // total=25, pageSize=20 → ceil(25/20) = 2
    expect(controller.totalPages, 2);
    expect(controller.pageSize, 20);
  });
}
