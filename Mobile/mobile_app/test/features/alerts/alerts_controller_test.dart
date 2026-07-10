import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/alerts/data/alerts_api_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/domain/alerts_repository.dart';
import 'package:hkt_livestock_agentic/features/alerts/presentation/alerts_controller.dart';

class _FakeAlertsRepository implements AlertsRepository {
  _FakeAlertsRepository();

  int loadCallCount = 0;
  String? lastStatus;
  List<String> markedRead = [];
  List<String> dismissed = [];
  List<List<String>> batchReads = [];

  List<AlertItem> _items = [];

  void setItems(List<AlertItem> items) => _items = items;

  @override
  Future<AlertsListData> loadAlerts({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    loadCallCount++;
    lastStatus = status;
    return AlertsListData(
      items: _items,
      total: _items.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<AlertDetail> loadDetail(String alertId) async => AlertDetail(
        id: alertId,
        title: 'Test',
        subtitle: '',
        priority: 'P1',
        type: 'TEST',
        stage: 'active',
        earTag: '-',
      );

  @override
  Future<void> markRead(String alertId) async {
    markedRead.add(alertId);
  }

  @override
  Future<void> dismiss(String alertId) async {
    dismissed.add(alertId);
  }

  @override
  Future<void> batchRead(List<String> alertIds) async {
    batchReads.add(alertIds);
  }
}

AlertItem _makeAlert(String id) => AlertItem(
      id: id,
      title: 'Alert $id',
      subtitle: '',
      priority: 'P1',
      type: 'FENCE_BREACH',
      stage: 'active',
      earTag: '-',
    );

void main() {
  late _FakeAlertsRepository repo;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  ProviderContainer setup({String farmId = 'farm-1'}) {
    repo = _FakeAlertsRepository();
    repo.setItems(List.generate(3, (i) => _makeAlert('$i')));
    return ProviderContainer(
      overrides: [
        alertsRepositoryProvider.overrideWithValue(repo),
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

  test('build loads alerts', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = container.read(alertsControllerProvider);
    expect(state.value, isNotNull);
    expect(state.value!.items.length, 3);
  });

  test('refresh with status filter passes it to repo', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await container
        .read(alertsControllerProvider.notifier)
        .refresh(status: 'ACTIVE');

    expect(repo.lastStatus, 'ACTIVE');
  });

  test('markRead delegates to repo and refreshes', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final callsBefore = repo.loadCallCount;
    await container.read(alertsControllerProvider.notifier).markRead('a1');

    expect(repo.markedRead, ['a1']);
    expect(repo.loadCallCount, callsBefore + 1);
  });

  test('dismiss delegates to repo and refreshes', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final callsBefore = repo.loadCallCount;
    await container.read(alertsControllerProvider.notifier).dismiss('a2');

    expect(repo.dismissed, ['a2']);
    expect(repo.loadCallCount, callsBefore + 1);
  });

  test('batchRead delegates list and refreshes', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final callsBefore = repo.loadCallCount;
    await container
        .read(alertsControllerProvider.notifier)
        .batchRead(['a1', 'a2', 'a3']);

    expect(repo.batchReads.last, ['a1', 'a2', 'a3']);
    expect(repo.loadCallCount, callsBefore + 1);
  });

  test('legacy acknowledge delegates to markRead', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await container
        .read(alertsControllerProvider.notifier)
        .acknowledge('legacy-1');

    expect(repo.markedRead, ['legacy-1']);
  });

  test('legacy handle delegates to dismiss', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await container
        .read(alertsControllerProvider.notifier)
        .handle('legacy-2');

    expect(repo.dismissed, ['legacy-2']);
  });

  test('legacy batchHandle delegates to batchRead', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await container
        .read(alertsControllerProvider.notifier)
        .batchHandle(['l1', 'l2']);

    expect(repo.batchReads.last, ['l1', 'l2']);
  });

  test('legacy archive is a no-op (no repo call)', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final callsBefore = repo.loadCallCount;
    await container.read(alertsControllerProvider.notifier).archive('x');

    expect(repo.markedRead, isEmpty);
    expect(repo.dismissed, isEmpty);
    // archive is a no-op, should not trigger refresh
    expect(repo.loadCallCount, callsBefore);
  });

  test('farm switch triggers rebuild', () async {
    final container = setup();
    addTearDown(container.dispose);

    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    container
        .read(sessionControllerProvider.notifier)
        .updateActiveFarm('farm-2');
    container.read(alertsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(repo.loadCallCount, greaterThanOrEqualTo(2));
  });
}
