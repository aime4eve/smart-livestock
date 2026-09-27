import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_repository.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_sync_controller.dart';

class _FakeSessionController extends SessionController {
  @override
  AppSession build() => const AppSession.authenticated(
    role: UserRole.owner,
    accessToken: 'test-token',
    userId: 9,
    tenantId: 1,
    activeFarmId: '1',
  );
}

class _FakeSignalRepository implements SignalRepository {
  int mapCalls = 0;
  int livestockCalls = 0;
  int statusRevision = 1;

  @override
  Future<LivestockSignalResponse> fetchLivestockSignals({
    required String farmId,
    required List<String> livestockIds,
    required String cursor,
  }) async {
    livestockCalls++;
    return LivestockSignalResponse(
      farmId: farmId,
      statusRevision: statusRevision,
      changed: cursor == '0',
      items: const [],
    );
  }

  @override
  Future<MapSignalResponse> fetchMapSignals({
    required String farmId,
    required String cursor,
    required bool includeGeometry,
  }) async {
    mapCalls++;
    if (mapCalls == 2) {
      throw const ConflictException(
        message: 'cursor too old',
        statusCode: 410,
        code: 'SIGNAL_CURSOR_TOO_OLD',
      );
    }
    return MapSignalResponse(
      farmId: '1',
      statusRevision: statusRevision,
      positionRevision: 1,
      fenceGeometryRevision: 1,
      cursor: '$statusRevision:1:1',
      changed: true,
      statusChanged: true,
      positionChanged: true,
      fenceGeometryChanged: true,
      fences: [],
      livestockSignals: [],
      positionUpdates: [],
    );
  }
}

class _SubscriptionProbe extends ConsumerStatefulWidget {
  const _SubscriptionProbe({required this.onSubscribed});

  final void Function(Object? mapToken) onSubscribed;

  @override
  ConsumerState<_SubscriptionProbe> createState() => _SubscriptionProbeState();
}

class _SubscriptionProbeState extends ConsumerState<_SubscriptionProbe> {
  Object? mapToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(signalSyncControllerProvider.notifier).setLivestockPage(const [
        '14',
      ]);
      final controller = ref.read(signalSyncControllerProvider.notifier);
      controller.subscribeLivestock();
      mapToken = controller.subscribeMap();
      widget.onSubscribed(mapToken);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('unsubscribe removes only the matching transport mode', (
    tester,
  ) async {
    final repository = _FakeSignalRepository();
    Object? mapToken;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_FakeSessionController.new),
          signalRepositoryProvider.overrideWithValue(repository),
        ],
        child: _SubscriptionProbe(
          onSubscribed: (map) {
            mapToken = map;
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(repository.mapCalls, greaterThanOrEqualTo(1));

    containerOf(
      tester,
    ).read(signalSyncControllerProvider.notifier).unsubscribe(mapToken!);
    final livestockCallsBefore = repository.livestockCalls;
    await tester.pump(const Duration(seconds: 3));

    expect(repository.mapCalls, 1);
    expect(repository.livestockCalls, greaterThan(livestockCallsBefore));
  });

  testWidgets('cursor-too-old resets cursor and performs full resync', (
    tester,
  ) async {
    final repository = _FakeSignalRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_FakeSessionController.new),
          signalRepositoryProvider.overrideWithValue(repository),
        ],
        child: _SubscriptionProbe(onSubscribed: (_) {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(repository.mapCalls, 1);

    await tester.pump(const Duration(seconds: 3));
    expect(repository.mapCalls, greaterThan(1));

    await tester.pump(const Duration(milliseconds: 150));
    expect(repository.mapCalls, greaterThanOrEqualTo(3));
  });

  testWidgets('livestock refresh publishes status cursor to listeners', (
    tester,
  ) async {
    final repository = _FakeSignalRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_FakeSessionController.new),
          signalRepositoryProvider.overrideWithValue(repository),
        ],
        child: _SubscriptionProbe(onSubscribed: (_) {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    repository.statusRevision = 2;
    await tester.pump(const Duration(seconds: 3));

    expect(
      containerOf(tester).read(signalSyncControllerProvider).cursor,
      '2:1:1',
    );
  });
}

ProviderContainer containerOf(WidgetTester tester) {
  final element = tester.element(find.byType(_SubscriptionProbe));
  return ProviderScope.containerOf(element);
}
