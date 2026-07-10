import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/livestock/data/livestock_api_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';

class _FakeLivestockRepository implements LivestockRepository {
  _FakeLivestockRepository({this.total = 0});

  final int total;
  int loadCallCount = 0;
  String? lastKeyword;
  int? lastPage;
  List<LivestockSummary> _items = [];

  void setItems(List<LivestockSummary> items) => _items = items;

  @override
  Future<LivestockListData> loadAll({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? keyword,
  }) async {
    loadCallCount++;
    lastKeyword = keyword;
    lastPage = page;
    return LivestockListData(
      items: _items,
      total: total,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<LivestockDetail> loadDetail(String id) async => LivestockDetail(
        earTag: 'SL-$id',
        livestockId: id,
        breed: Breed.angus,
        ageMonths: 24,
        weightKg: 400,
        health: LivestockHealth.healthy,
        fenceId: 'f1',
        devices: const [],
        bodyTemp: 38.5,
        activityLevel: '正常',
        ruminationFreq: '--',
        lastLocation: '0, 0',
      );

  @override
  Future<LivestockDetail> create(Map<String, dynamic> body) async =>
      loadDetail('new');

  @override
  Future<LivestockDetail> update(String id, Map<String, dynamic> body) async =>
      loadDetail(id);

  @override
  Future<void> delete(String id) async {}
}

LivestockSummary _makeSummary(String id) => LivestockSummary(
      id: id,
      earTag: 'SL-$id',
      breed: Breed.angus,
      health: LivestockHealth.healthy,
      fenceId: 'f1',
    );

void main() {
  late _FakeLivestockRepository repo;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  ProviderContainer setup({String farmId = 'farm-1'}) {
    repo = _FakeLivestockRepository(total: 45);
    repo.setItems(List.generate(20, (i) => _makeSummary('$i')));
    return ProviderContainer(
      overrides: [
        livestockRepositoryProvider.overrideWithValue(repo),
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

  test('build loads first page', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(livestockListControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = container.read(livestockListControllerProvider);
    expect(state.value, isNotNull);
    expect(state.value!.items.length, 20);
    expect(repo.lastPage, 1);
  });

  test('search sets keyword and resets to page 1', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(livestockListControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await container
        .read(livestockListControllerProvider.notifier)
        .search('SL-001');

    expect(repo.lastKeyword, 'SL-001');
    expect(repo.lastPage, 1);
  });

  test('goToPage fetches requested page', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(livestockListControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final controller = container.read(livestockListControllerProvider.notifier);
    // total=45, pageSize=20 → 3 pages
    expect(controller.totalPages, 3);

    await controller.goToPage(3);
    expect(repo.lastPage, 3);
  });

  test('goToPage ignores out-of-range pages', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(livestockListControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final controller = container.read(livestockListControllerProvider.notifier);
    final callsBefore = repo.loadCallCount;

    await controller.goToPage(0);
    await controller.goToPage(99);
    await controller.goToPage(1); // same as current

    expect(repo.loadCallCount, callsBefore);
  });

  test('refresh reloads current page', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(livestockListControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final controller = container.read(livestockListControllerProvider.notifier);
    await controller.goToPage(2);
    final callsBefore = repo.loadCallCount;

    await controller.refresh();
    expect(repo.loadCallCount, callsBefore + 1);
    expect(repo.lastPage, 2);
  });

  test('farm switch triggers rebuild', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(livestockListControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    container
        .read(sessionControllerProvider.notifier)
        .updateActiveFarm('farm-2');
    container.read(livestockListControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(repo.loadCallCount, greaterThanOrEqualTo(2));
  });

  test('LivestockDetailController loads by id', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(livestockDetailControllerProvider('liv-42'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = container.read(livestockDetailControllerProvider('liv-42'));
    expect(state.value, isNotNull);
    expect(state.value!.livestockId, 'liv-42');
    expect(state.value!.earTag, 'SL-liv-42');
  });

  test('LivestockDetailController refresh reloads detail', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(livestockDetailControllerProvider('liv-1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await container
        .read(livestockDetailControllerProvider('liv-1').notifier)
        .refresh();

    final state = container.read(livestockDetailControllerProvider('liv-1'));
    expect(state.value, isNotNull);
    expect(state.value!.livestockId, 'liv-1');
  });
}
