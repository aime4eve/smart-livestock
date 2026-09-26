import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_models.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_repository.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_store.dart';

class SignalSyncController extends FarmScopedNotifier<SignalSyncState> {
  static const pollInterval = Duration(seconds: 3);

  Timer? _timer;
  Timer? _refreshDebounce;
  bool _refreshing = false;
  String? _farmId;
  String _cursor = '0:0:0';
  final Set<Object> _subscriptions = {};
  bool _livestockSubscribed = false;
  bool _mapSubscribed = false;
  List<String> _livestockIds = const [];
  bool _disposed = false;

  @override
  SignalSyncState build() {
    final session = ref.watch(sessionControllerProvider);
    final farmId = session.activeFarmId;
    final farmChanged = _farmId != farmId;
    _farmId = farmId;

    if (!session.isLoggedIn || farmId == null || farmId.isEmpty) {
      _stopTimer();
      _subscriptions.clear();
      _livestockSubscribed = false;
      _mapSubscribed = false;
      _livestockIds = const [];
      return const SignalSyncState().clear(null);
    }

    if (farmChanged || state.farmId != farmId) _resetForFarm(farmId);
    ref.onDispose(() {
      _disposed = true;
      _stopTimer();
    });
    _ensureTimer();
    return state.hasFarm && state.farmId == farmId
        ? state
        : const SignalSyncState().clear(farmId);
  }

  Object subscribeLivestock() {
    final token = Object();
    _subscriptions.add(token);
    _livestockSubscribed = true;
    _ensureTimer();
    _scheduleRefresh();
    return token;
  }

  Object subscribeMap() {
    final token = Object();
    _subscriptions.add(token);
    _mapSubscribed = true;
    _ensureTimer();
    _scheduleRefresh();
    return token;
  }

  void unsubscribe(Object token) {
    _subscriptions.remove(token);
    if (_subscriptions.isEmpty) {
      _livestockSubscribed = false;
      _mapSubscribed = false;
      _stopTimer();
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
  }

  void resume() {
    if (!state.paused) return;
    state = state.copyWith(paused: false, clearError: true);
    refreshNow();
  }

  void _resetForFarm(String farmId) {
    _stopTimer();
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
    final signals = Map<String, LivestockSignal>.from(state.livestockSignals);
    for (final signal in response.livestockSignals) {
      signals[signal.livestockId] = signal;
    }
    final fences = response.fences.isEmpty
        ? state.fences
        : {for (final fence in response.fences) fence.fenceId: fence};

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
    final parts = _cursor.split(':');
    final statusRevision = int.tryParse(parts.first) ?? 0;
    if (response.statusRevision > statusRevision) {
      _cursor = '${response.statusRevision}:${parts.skip(1).join(':')}';
    }
    state = state.copyWith(
      livestockSignals: signals,
      livestockLoaded: true,
      stale: false,
      clearError: true,
    );
  }
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
  if (state.stale) return 'stale';
  if (state.refreshing) return 'refreshing';
  return state.paused ? 'paused' : 'polling';
});
