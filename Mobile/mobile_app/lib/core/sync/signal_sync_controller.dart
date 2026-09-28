import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_exception.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_models.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_repository.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_transport.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_store.dart';

class SignalSyncController extends FarmScopedNotifier<SignalSyncState> {
  static const pollInterval = Duration(seconds: 3);

  Timer? _timer;
  Timer? _refreshDebounce;
  SignalRealtimeTransport? _transport;
  String? _transportFarmId;
  bool _transportStarting = false;
  bool _refreshing = false;
  String? _farmId;
  String _cursor = '0:0:0';
  final Set<Object> _subscriptions = {};
  final Map<Object, _SignalSubscriptionMode> _subscriptionModes = {};
  List<String> _livestockIds = const [];
  bool _disposed = false;

  bool get _livestockSubscribed =>
      _subscriptionModes.containsValue(_SignalSubscriptionMode.livestock);

  bool get _mapSubscribed =>
      _subscriptionModes.containsValue(_SignalSubscriptionMode.map);

  @override
  SignalSyncState build() {
    final session = ref.watch(sessionControllerProvider);
    final farmId = session.activeFarmId;
    final farmChanged = _farmId != farmId;
    _transport ??= ref.read(signalTransportProvider);
    _farmId = farmId;

    if (!session.isLoggedIn || farmId == null || farmId.isEmpty) {
      _stopTimer();
      _closeTransport();
      _subscriptions.clear();
      _subscriptionModes.clear();
      _livestockIds = const [];
      return const SignalSyncState().clear(null);
    }

    if (farmChanged || state.farmId != farmId) _resetForFarm(farmId);
    ref.onDispose(() {
      _disposed = true;
      _stopTimer();
      _closeTransport();
    });
    _ensureTimer();
    _ensureTransport();
    return state.hasFarm && state.farmId == farmId
        ? state
        : const SignalSyncState().clear(farmId);
  }

  Object subscribeLivestock() {
    final token = _SignalSubscriptionToken(_SignalSubscriptionMode.livestock);
    _subscriptions.add(token);
    _subscriptionModes[token] = _SignalSubscriptionMode.livestock;
    _ensureTimer();
    _ensureTransport();
    _scheduleRefresh();
    return token;
  }

  Object subscribeMap() {
    final token = _SignalSubscriptionToken(_SignalSubscriptionMode.map);
    _subscriptions.add(token);
    _subscriptionModes[token] = _SignalSubscriptionMode.map;
    _ensureTimer();
    _ensureTransport();
    _scheduleRefresh();
    return token;
  }

  void unsubscribe(Object token) {
    _subscriptions.remove(token);
    if (token is _SignalSubscriptionToken) {
      _subscriptionModes.remove(token);
    }
    if (_subscriptions.isEmpty) _subscriptionModes.clear();
    if (_subscriptions.isEmpty) {
      _stopTimer();
      _closeTransport();
    }
  }

  void setLivestockPage(List<String> livestockIds) {
    final ids = List<String>.unmodifiable(livestockIds);
    final unchanged =
        _livestockIds.length == ids.length && _livestockIds.every(ids.contains);
    if (unchanged) return;
    _livestockIds = ids;
    _scheduleRefresh();
  }

  Future<void> refreshNow() async {
    _refreshDebounce?.cancel();
    await _refresh();
  }

  void pause() {
    if (!state.paused) state = state.copyWith(paused: true);
    _closeTransport();
    _stopTimer();
  }

  void resume() {
    if (!state.paused) return;
    state = state.copyWith(paused: false, clearError: true);
    refreshNow();
    _ensureTimer();
    _ensureTransport();
  }

  void _resetForFarm(String farmId) {
    _stopTimer();
    _closeTransport();
    _cursor = '0:0:0';
    _livestockIds = const [];
    state = const SignalSyncState().clear(farmId);
  }

  void _ensureTimer() {
    if (_timer != null || _subscriptions.isEmpty) return;
    _timer = Timer.periodic(pollInterval, (_) => _refresh());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
  }

  void _ensureTransport() {
    final farmId = _farmId;
    if (!_canStartTransport(farmId)) return;
    if (_transport?.isActive == true && _transportFarmId == farmId) return;
    if (_transportStarting) return;

    _transportStarting = true;
    final requestCursor = _cursor;
    _transport!.start(
      farmId: farmId!,
      cursor: requestCursor,
      onMessage: _handleTransportMessage,
    );
    _transportStarting = false;
    _transportFarmId = farmId;
  }

  bool _canStartTransport(String? farmId) {
    return farmId != null &&
        farmId.isNotEmpty &&
        _subscriptions.isNotEmpty &&
        !_disposed &&
        !state.paused &&
        _transport != null &&
        _transport!.supported;
  }

  void _handleTransportMessage(SignalSseMessage message) {
    if (_disposed) return;
    switch (message.control) {
      case SignalSseControl.connected:
        _stopTimer();
        // Opening SSE must not cancel an initial delta fetch already waiting
        // for its debounce; otherwise a fast open can leave the map empty.
        _scheduleRefresh();
        state = state.copyWith(
          transport: SignalTransportKind.sse,
          stale: false,
          clearError: true,
        );
      case SignalSseControl.changed:
        _scheduleRefresh();
      case SignalSseControl.reconnect:
        _transport?.close();
        _transportFarmId = null;
        _cursor = '0:0:0';
        _ensureTimer();
        _scheduleRefresh();
        state = state.copyWith(
          cursor: _cursor,
          transport: SignalTransportKind.polling,
        );
      case SignalSseControl.interrupted:
        break;
      case SignalSseControl.failed:
        _transport?.close();
        _transportFarmId = null;
        if (_subscriptions.isNotEmpty) _ensureTimer();
        state = state.copyWith(transport: SignalTransportKind.polling);
    }
  }

  void _closeTransport() {
    if (_transport?.isActive == true || _transportFarmId != null) {
      _transport?.close();
    }
    _transportFarmId = null;
    _transportStarting = false;
  }

  void _scheduleRefresh() {
    if (_subscriptions.isEmpty) return;
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 100), _refresh);
  }

  Future<void> _refresh() async {
    final farmId = _farmId;
    if (farmId == null ||
        farmId.isEmpty ||
        _refreshing ||
        state.paused ||
        _subscriptions.isEmpty) {
      return;
    }

    _refreshing = true;
    if (!state.refreshing) {
      state = state.copyWith(refreshing: true, clearError: true);
    }
    try {
      final repository = ref.read(signalRepositoryProvider);
      if (_mapSubscribed) {
        final response = await repository.fetchMapSignals(
          farmId: farmId,
          cursor: _cursor,
          includeGeometry: _cursor == '0:0:0',
        );
        _applyMap(response);
      }
      if (_livestockSubscribed && _livestockIds.isNotEmpty) {
        final response = await repository.fetchLivestockSignals(
          farmId: farmId,
          livestockIds: _livestockIds,
          cursor: _cursor.split(':').first,
        );
        _applyLivestock(response);
      }
      if (!_disposed && state.stale) state = state.copyWith(stale: false);
    } on ApiException catch (e) {
      if (e.code == 'SIGNAL_CURSOR_TOO_OLD') {
        _cursor = '0:0:0';
        _stopTimer();
        state = SignalSyncState(
          farmId: farmId,
          cursor: _cursor,
          stale: true,
          error: e,
        );
        _scheduleRefresh();
        return;
      }
      if (!_disposed) state = state.copyWith(stale: true, error: e);
    } catch (e) {
      if (!_disposed) state = state.copyWith(stale: true, error: e);
    } finally {
      _refreshing = false;
      if (!_disposed && state.refreshing) {
        state = state.copyWith(refreshing: false);
      }
    }
  }

  void _applyMap(MapSignalResponse response) {
    final positions = Map<String, PositionSignal>.from(state.positions);
    for (final position in response.positionUpdates) {
      positions[position.livestockId] = position;
    }

    var signals = state.livestockSignals;
    if (response.statusChanged) {
      signals = {
        for (final signal in response.livestockSignals)
          signal.livestockId: signal,
      };
      positions.removeWhere(
        (livestockId, _) => !signals.containsKey(livestockId),
      );
    } else {
      signals = Map<String, LivestockSignal>.from(signals);
      for (final signal in response.livestockSignals) {
        signals[signal.livestockId] = signal;
      }
    }

    final parts = _cursor.split(':');
    final previousGeometryRevision = int.tryParse(parts[2]) ?? 0;
    final fullGeometry =
        previousGeometryRevision == 0 || response.fenceGeometryChanged;
    final responseFences = {
      for (final fence in response.fences) fence.fenceId: fence,
    };
    final fences = fullGeometry
        ? responseFences
        : () {
            final merged = Map<String, MapFenceSignal>.from(state.fences);
            for (final entry in responseFences.entries) {
              final cached = state.fences[entry.key];
              merged[entry.key] = MapFenceSignal(
                fenceId: entry.value.fenceId,
                name: entry.value.name,
                revision: entry.value.revision,
                status: entry.value.status,
                activeAlertTypes: entry.value.activeAlertTypes,
                livestockCount: entry.value.livestockCount,
                active: entry.value.active,
                color: entry.value.color,
                fenceType: entry.value.fenceType,
                version: entry.value.version,
                geometry: cached?.geometry ?? entry.value.geometry,
              );
            }
            return merged;
          }();

    _cursor = response.cursor;
    state = state.copyWith(
      farmId: response.farmId,
      cursor: response.cursor,
      positions: positions,
      livestockSignals: signals,
      fences: fences,
      mapLoaded: true,
      stale: false,
      clearError: true,
    );
  }

  void _applyLivestock(LivestockSignalResponse response) {
    final signals = Map<String, LivestockSignal>.from(state.livestockSignals);
    for (final signal in response.items) {
      signals[signal.livestockId] = signal;
    }
    if (response.changed) {
      signals.removeWhere(
        (livestockId, _) =>
            _livestockIds.contains(livestockId) &&
            !response.items.any((signal) => signal.livestockId == livestockId),
      );
    }
    final parts = _cursor.split(':');
    final statusRevision = int.tryParse(parts.first) ?? 0;
    if (response.statusRevision > statusRevision) {
      _cursor = '${response.statusRevision}:${parts.skip(1).join(':')}';
    }
    state = state.copyWith(
      livestockSignals: signals,
      cursor: _cursor,
      livestockLoaded: true,
      stale: false,
      clearError: true,
    );
  }
}

enum _SignalSubscriptionMode { livestock, map }

class _SignalSubscriptionToken {
  _SignalSubscriptionToken(this.mode);

  final _SignalSubscriptionMode mode;
  final Object id = Object();
}

final signalSyncControllerProvider =
    NotifierProvider<SignalSyncController, SignalSyncState>(
      SignalSyncController.new,
    );

final livestockSignalsProvider = Provider<Map<String, LivestockSignal>>((ref) {
  return ref.watch(
    signalSyncControllerProvider.select((state) => state.livestockSignals),
  );
});

final livestockSignalByIdProvider = Provider.family<LivestockSignal?, String>((
  ref,
  id,
) {
  return ref.watch(
    signalSyncControllerProvider.select((state) => state.livestockSignals[id]),
  );
});

final ranchMapSignalsProvider = Provider<Map<String, LivestockSignal>>((ref) {
  return ref.watch(
    signalSyncControllerProvider.select((state) => state.livestockSignals),
  );
});

final ranchMapPositionsProvider = Provider<Map<String, PositionSignal>>((ref) {
  return ref.watch(
    signalSyncControllerProvider.select((state) => state.positions),
  );
});

final ranchMapGeometryProvider = Provider<Map<String, MapFenceSignal>>((ref) {
  return ref.watch(
    signalSyncControllerProvider.select((state) => state.fences),
  );
});

final signalTransportStatusProvider = Provider<String>((ref) {
  final state = ref.watch(signalSyncControllerProvider);
  final transport = switch (state.transport) {
    SignalTransportKind.sse => 'sse',
    SignalTransportKind.polling => 'polling',
  };
  if (state.stale) return 'stale';
  if (state.refreshing) return 'refreshing';
  return state.paused ? 'paused' : transport;
});
