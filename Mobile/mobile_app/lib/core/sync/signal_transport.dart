import 'signal_transport_stub.dart'
    if (dart.library.js_interop) 'signal_transport_web.dart' as platform;

enum SignalTransportKind { sse, polling }

enum SignalSseControl { connected, changed, reconnect, interrupted, failed }

class SignalSseMessage {
  const SignalSseMessage(this.control, {this.id, this.data});

  final SignalSseControl control;
  final String? id;
  final Map<String, dynamic>? data;
}

abstract class SignalRealtimeTransport {
  bool get supported;
  bool get isActive;

  void start({
    required String farmId,
    required String cursor,
    required void Function(SignalSseMessage message) onMessage,
  });

  void close();
}

SignalRealtimeTransport createSignalTransport() =>
    platform.createSignalTransport();

SignalStreamNotification? parseSignalNotification(Map<String, dynamic> data) {
  if (data['farmId'] == null) return null;
  return SignalStreamNotification.fromJson(data);
}

class SignalStreamNotification {
  const SignalStreamNotification({
    required this.farmId,
    required this.livestockIds,
    required this.fenceIds,
    required this.statusRevision,
    required this.positionRevision,
    required this.fenceGeometryRevision,
  });

  final String farmId;
  final List<String> livestockIds;
  final List<String> fenceIds;
  final int statusRevision;
  final int positionRevision;
  final int fenceGeometryRevision;

  factory SignalStreamNotification.fromJson(Map<String, dynamic> json) {
    return SignalStreamNotification(
      farmId: (json['farmId'] ?? '').toString(),
      livestockIds:
          (json['livestockIds'] as List?)?.map((value) => value.toString()).toList() ??
              const [],
      fenceIds:
          (json['fenceIds'] as List?)?.map((value) => value.toString()).toList() ??
              const [],
      statusRevision: json['statusRevision'] as int? ?? 0,
      positionRevision: json['positionRevision'] as int? ?? 0,
      fenceGeometryRevision: json['fenceGeometryRevision'] as int? ?? 0,
    );
  }
}
