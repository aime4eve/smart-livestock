import 'signal_transport.dart';

class PlatformSignalTransport implements SignalRealtimeTransport {
  @override
  bool get supported => false;

  @override
  bool get isActive => false;

  @override
  void start({
    required String farmId,
    required String cursor,
    required void Function(SignalSseMessage message) onMessage,
  }) {}

  @override
  void close() {}
}

SignalRealtimeTransport createSignalTransport() => PlatformSignalTransport();
