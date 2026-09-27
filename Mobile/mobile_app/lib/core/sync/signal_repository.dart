import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_transport.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LivestockSignalResponse {
  const LivestockSignalResponse({
    required this.farmId,
    required this.statusRevision,
    required this.changed,
    required this.items,
  });

  final String farmId;
  final int statusRevision;
  final bool changed;
  final List<LivestockSignal> items;

  factory LivestockSignalResponse.fromJson(Map<String, dynamic> json) {
    return LivestockSignalResponse(
      farmId: (json['farmId'] ?? '').toString(),
      statusRevision: json['statusRevision'] as int? ?? 0,
      changed: json['changed'] as bool? ?? false,
      items:
          (json['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(LivestockSignal.fromJson)
              .toList() ??
          const [],
    );
  }
}

class MapSignalResponse {
  const MapSignalResponse({
    required this.farmId,
    required this.statusRevision,
    required this.positionRevision,
    required this.fenceGeometryRevision,
    required this.cursor,
    required this.changed,
    required this.statusChanged,
    required this.positionChanged,
    required this.fenceGeometryChanged,
    required this.fences,
    required this.livestockSignals,
    required this.positionUpdates,
  });

  final String farmId;
  final int statusRevision;
  final int positionRevision;
  final int fenceGeometryRevision;
  final String cursor;
  final bool changed;
  final bool statusChanged;
  final bool positionChanged;
  final bool fenceGeometryChanged;
  final List<MapFenceSignal> fences;
  final List<LivestockSignal> livestockSignals;
  final List<PositionSignal> positionUpdates;

  factory MapSignalResponse.fromJson(Map<String, dynamic> json) {
    return MapSignalResponse(
      farmId: (json['farmId'] ?? '').toString(),
      statusRevision: json['statusRevision'] as int? ?? 0,
      positionRevision: json['positionRevision'] as int? ?? 0,
      fenceGeometryRevision: json['fenceGeometryRevision'] as int? ?? 0,
      cursor: json['cursor'] as String? ?? '0:0:0',
      changed: json['changed'] as bool? ?? false,
      statusChanged: json['statusChanged'] as bool? ?? false,
      positionChanged: json['positionChanged'] as bool? ?? false,
      fenceGeometryChanged: json['fenceGeometryChanged'] as bool? ?? false,
      fences:
          (json['fences'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MapFenceSignal.fromJson)
              .toList() ??
          const [],
      livestockSignals:
          (json['livestockSignals'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(LivestockSignal.fromJson)
              .toList() ??
          const [],
      positionUpdates:
          (json['positionUpdates'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(PositionSignal.fromJson)
              .toList() ??
          const [],
    );
  }
}

class SignalRepository {
  const SignalRepository();

  Future<LivestockSignalResponse> fetchLivestockSignals({
    required String farmId,
    required List<String> livestockIds,
    required String cursor,
  }) async {
    if (livestockIds.isEmpty) {
      return LivestockSignalResponse(
        farmId: farmId,
        statusRevision: 0,
        changed: false,
        items: const [],
      );
    }
    final encodedIds = Uri.encodeQueryComponent(livestockIds.join(','));
    final encodedCursor = Uri.encodeQueryComponent(cursor);
    final data = await ApiClient.instance.farmGet(
      '/signals/livestock?livestockIds=$encodedIds&cursor=$encodedCursor',
      farmId: farmId,
    );
    return LivestockSignalResponse.fromJson(data);
  }

  Future<MapSignalResponse> fetchMapSignals({
    required String farmId,
    required String cursor,
    required bool includeGeometry,
  }) async {
    final encodedCursor = Uri.encodeQueryComponent(cursor);
    final geometry = includeGeometry ? 'true' : 'false';
    final data = await ApiClient.instance.farmGet(
      '/signals/map?cursor=$encodedCursor&includeGeometry=$geometry',
      farmId: farmId,
    );
    return MapSignalResponse.fromJson(data);
  }
}

final signalRepositoryProvider = Provider<SignalRepository>(
  (_) => const SignalRepository(),
);

final signalTransportProvider = Provider<SignalRealtimeTransport>(
  (_) => createSignalTransport(),
);
