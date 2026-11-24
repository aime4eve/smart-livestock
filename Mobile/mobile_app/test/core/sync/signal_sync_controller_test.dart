import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_repository.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_transport.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_sync_controller.dart';

class _FakeTransport implements SignalRealtimeTransport {
  _FakeTransport({this.fail = false, this.supported = false});

  final bool fail;
  @override
  final bool supported;
  final List<String> startedCursors = [];
  int closeCount = 0;
  bool connected = false;
  void Function(SignalSseMessage message)? messageHandler;

  @override
  bool get isActive => connected;

  @override
  void start({
    required String farmId,
    required String cursor,
    required void Function(SignalSseMessage message) onMessage,
  }) {
    startedCursors.add(cursor);
    messageHandler = onMessage;
    Future<void>.microtask(() {
      if (fail) {
        onMessage(const SignalSseMessage(SignalSseControl.failed));
      } else {
        connected = true;
        onMessage(const SignalSseMessage(SignalSseControl.connected));
        onMessage(const SignalSseMessage(SignalSseControl.changed));
      }
    });
  }

  @override
  void close() {
    closeCount++;
    connected = false;
    messageHandler = null;
  }
}

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
  _FakeSignalRepository({
    this.forbidMap = false,
    this.cursorTooOldOnCall = 2,
    this.gateOnCall,
  });

  /// When true, every map fetch is refused the way the backend refuses an
  /// identity without farm-signal access (403 AUTH_FORBIDDEN).
  bool forbidMap;

  /// Map-call number that throws SIGNAL_CURSOR_TOO_OLD (0 = never).
  int cursorTooOldOnCall;

  /// Map-call number to park inside the fetch until [releaseGate] — lets a
  /// test observe the in-flight moment (poll started, fetch suspended).
  int? gateOnCall;
  final Map<int, Completer<void>> _gates = {};

  /// One-shot exception for the next map call (non-denial failure tests);
  /// consumed before the cursor-too-old stub.
  ApiException? failNextMapWith;

  void releaseGate(int callNumber) {
    _gates.remove(callNumber)?.complete();
  }

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
    if (gateOnCall == mapCalls) {
      final gate = _gates.putIfAbsent(mapCalls, () => Completer<void>());
      await gate.future;
    }
    if (forbidMap) {
      throw const ForbiddenException(
        statusCode: 403,
        code: 'AUTH_FORBIDDEN',
      );
    }
    final oneShot = failNextMapWith;
    if (oneShot != null) {
      failNextMapWith = null;
      throw oneShot;
    }
    if (cursorTooOldOnCall == mapCalls) {
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
          signalTransportProvider.overrideWithValue(_FakeTransport()),
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
          signalTransportProvider.overrideWithValue(_FakeTransport()),
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
          signalTransportProvider.overrideWithValue(_FakeTransport()),
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

  testWidgets('connected SSE stops polling and events refresh once', (
    tester,
  ) async {
    final repository = _FakeSignalRepository();
    final transport = _FakeTransport(supported: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_FakeSessionController.new),
          signalRepositoryProvider.overrideWithValue(repository),
          signalTransportProvider.overrideWithValue(transport),
        ],
        child: _SubscriptionProbe(onSubscribed: (_) {}),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(transport.startedCursors, isNotEmpty);
    expect(transport.closeCount, 0);
    expect(
      containerOf(tester).read(signalTransportStatusProvider),
      'sse',
    );

    final mapCallsAfterEvent = repository.mapCalls;
    await tester.pump(const Duration(seconds: 3));
    expect(repository.mapCalls, mapCallsAfterEvent);
  });

  testWidgets('SSE failure falls back to three-second polling', (
    tester,
  ) async {
    final repository = _FakeSignalRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_FakeSessionController.new),
          signalRepositoryProvider.overrideWithValue(repository),
          signalTransportProvider.overrideWithValue(
            _FakeTransport(fail: true, supported: true),
          ),
        ],
        child: _SubscriptionProbe(onSubscribed: (_) {}),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      containerOf(tester).read(signalTransportStatusProvider),
      'polling',
    );

    final mapCallsBeforeWindow = repository.mapCalls;
    await tester.pump(const Duration(seconds: 3));
    expect(repository.mapCalls, greaterThan(mapCallsBeforeWindow));
  });

  testWidgets('a refused map fetch flags the state forbidden, stably', (
    tester,
  ) async {
    final repository = _FakeSignalRepository(forbidMap: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_FakeSessionController.new),
          signalRepositoryProvider.overrideWithValue(repository),
          signalTransportProvider.overrideWithValue(_FakeTransport()),
        ],
        child: _SubscriptionProbe(onSubscribed: (_) {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    final container = containerOf(tester);
    expect(container.read(signalSyncControllerProvider).forbidden, isTrue);
    expect(container.read(signalSyncControllerProvider).stale, isTrue);

    // Sticky across later polls: every poll clears `error` while in flight,
    // so a flag that followed the error would flicker every three seconds.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(repository.mapCalls, greaterThanOrEqualTo(3));
    expect(container.read(signalSyncControllerProvider).forbidden, isTrue);
    expect(container.read(signalSyncControllerProvider).stale, isTrue);
  });

  testWidgets('a poll start clears the error but keeps the forbidden flag', (
    tester,
  ) async {
    // Gate the second fetch mid-flight so the moment the poll STARTS — after
    // the controller cleared `error`, before the fetch resolves — is actually
    // observable. Boundary-only assertions cannot see that moment.
    final repository = _FakeSignalRepository(
      forbidMap: true,
      cursorTooOldOnCall: 0,
      gateOnCall: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_FakeSessionController.new),
          signalRepositoryProvider.overrideWithValue(repository),
          signalTransportProvider.overrideWithValue(_FakeTransport()),
        ],
        child: _SubscriptionProbe(onSubscribed: (_) {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    final container = containerOf(tester);
    expect(container.read(signalSyncControllerProvider).forbidden, isTrue);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    final inFlight = container.read(signalSyncControllerProvider);
    expect(inFlight.refreshing, isTrue, reason: 'fetch is parked at the gate');
    expect(inFlight.error, isNull, reason: 'poll start cleared the error');
    expect(
      inFlight.forbidden,
      isTrue,
      reason: 'poll start must NOT reset the forbidden flag',
    );

    repository.releaseGate(2);
    await tester.pump(const Duration(milliseconds: 50));
    expect(container.read(signalSyncControllerProvider).forbidden, isTrue);
  });

  testWidgets('a successful map fetch clears the forbidden flag', (
    tester,
  ) async {
    // cursorTooOldOnCall=0: the second call walks the REAL success path
    // (_applyMap) instead of the cursor-reset detour the default stub would
    // take — deleting `forbidden: false` from _applyMap must fail this test.
    final repository = _FakeSignalRepository(
      forbidMap: true,
      cursorTooOldOnCall: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_FakeSessionController.new),
          signalRepositoryProvider.overrideWithValue(repository),
          signalTransportProvider.overrideWithValue(_FakeTransport()),
        ],
        child: _SubscriptionProbe(onSubscribed: (_) {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    final container = containerOf(tester);
    expect(container.read(signalSyncControllerProvider).forbidden, isTrue);

    repository.forbidMap = false;
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 150));

    final state = container.read(signalSyncControllerProvider);
    expect(state.forbidden, isFalse);
    expect(state.stale, isFalse);
    expect(state.mapLoaded, isTrue);
  });

  testWidgets('a non-denial failure clears the forbidden flag', (tester) async {
    // Timeout / socket drop after a denial: the situation is no longer a
    // denial, so the banner falls back to the outage text with a retry.
    final repository = _FakeSignalRepository(
      forbidMap: true,
      cursorTooOldOnCall: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_FakeSessionController.new),
          signalRepositoryProvider.overrideWithValue(repository),
          signalTransportProvider.overrideWithValue(_FakeTransport()),
        ],
        child: _SubscriptionProbe(onSubscribed: (_) {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    final container = containerOf(tester);
    expect(container.read(signalSyncControllerProvider).forbidden, isTrue);

    repository.forbidMap = false;
    repository.failNextMapWith = const ServerException(
      message: 'boom',
      statusCode: 503,
      code: 'INTERNAL',
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 50));

    final state = container.read(signalSyncControllerProvider);
    expect(state.stale, isTrue);
    expect(state.forbidden, isFalse);
    expect(state.error, isA<ServerException>());
  });
}

ProviderContainer containerOf(WidgetTester tester) {
  final element = tester.element(find.byType(_SubscriptionProbe));
  return ProviderScope.containerOf(element);
}
