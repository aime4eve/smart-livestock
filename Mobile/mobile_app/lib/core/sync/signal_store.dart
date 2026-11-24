import 'package:hkt_livestock_agentic/core/sync/signal_models.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_transport.dart';

class SignalSyncState {
  const SignalSyncState({
    this.farmId,
    this.cursor = '0:0:0',
    this.livestockSignals = const {},
    this.positions = const {},
    this.fences = const {},
    this.livestockLoaded = false,
    this.mapLoaded = false,
    this.refreshing = false,
    this.stale = false,
    this.forbidden = false,
    this.paused = false,
    this.transport = SignalTransportKind.polling,
    this.error,
  });

  final String? farmId;
  final String cursor;
  final Map<String, LivestockSignal> livestockSignals;
  final Map<String, PositionSignal> positions;
  final Map<String, MapFenceSignal> fences;
  final bool livestockLoaded;
  final bool mapLoaded;
  final bool refreshing;
  final bool stale;

  /// The live-signal endpoint refused this identity (403 AUTH_FORBIDDEN) — as
  /// opposed to a transient outage, it neither recovers on its own nor changes
  /// on retry. Reflects the most recent failed attempt: a denial sets it, any
  /// other failure clears it, and it is deliberately not reset when the next
  /// poll starts (every poll clears [error] while in flight), so consumers —
  /// the banner, the fence fallback — must key off this flag rather than the
  /// error object. A successful refresh or a farm change clears it.
  final bool forbidden;

  final bool paused;
  final SignalTransportKind transport;
  final Object? error;

  bool get hasFarm => farmId != null && farmId!.isNotEmpty;

  LivestockSignal? livestockSignal(String id) => livestockSignals[id];
  PositionSignal? position(String id) => positions[id];
  MapFenceSignal? fence(String id) => fences[id];

  SignalSyncState clear(String? farmId) => SignalSyncState(farmId: farmId);

  SignalSyncState copyWith({
    String? farmId,
    String? cursor,
    Map<String, LivestockSignal>? livestockSignals,
    Map<String, PositionSignal>? positions,
    Map<String, MapFenceSignal>? fences,
    bool? livestockLoaded,
    bool? mapLoaded,
    bool? refreshing,
    bool? stale,
    bool? forbidden,
    bool? paused,
    SignalTransportKind? transport,
    Object? error,
    bool clearError = false,
  }) {
    return SignalSyncState(
      farmId: farmId ?? this.farmId,
      cursor: cursor ?? this.cursor,
      livestockSignals: livestockSignals ?? this.livestockSignals,
      positions: positions ?? this.positions,
      fences: fences ?? this.fences,
      livestockLoaded: livestockLoaded ?? this.livestockLoaded,
      mapLoaded: mapLoaded ?? this.mapLoaded,
      refreshing: refreshing ?? this.refreshing,
      stale: stale ?? this.stale,
      forbidden: forbidden ?? this.forbidden,
      paused: paused ?? this.paused,
      transport: transport ?? this.transport,
      error: clearError ? null : error ?? this.error,
    );
  }
}
