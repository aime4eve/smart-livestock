import 'dart:convert';
import 'dart:js_interop';

import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:web/web.dart' as web;

import 'signal_transport.dart';

/// Browser-native SSE transport. EventSource keeps its own reconnect cursor in
/// Last-Event-ID; authorization is exchanged for a one-time ticket before the
/// first connection and an HttpOnly reconnect cookie keeps that flow bound.
class PlatformSignalTransport implements SignalRealtimeTransport {
  web.EventSource? _source;
  bool _closed = false;
  int _failures = 0;

  @override
  bool get supported => true;

  @override
  bool get isActive => _source != null;

  @override
  void start({
    required String farmId,
    required String cursor,
    required void Function(SignalSseMessage message) onMessage,
  }) {
    close();
    _closed = false;
    _requestTicketAndConnect(
      farmId: farmId,
      cursor: cursor,
      onMessage: onMessage,
    );
  }

  Future<void> _requestTicketAndConnect({
    required String farmId,
    required String cursor,
    required void Function(SignalSseMessage message) onMessage,
  }) async {
    try {
      final response = await ApiClient.instance.farmPost(
        '/signals/stream-ticket',
        farmId: farmId,
      );
      final ticket = response['ticket']?.toString();
      if (_closed || ticket == null || ticket.isEmpty) {
        onMessage(const SignalSseMessage(SignalSseControl.failed));
        return;
      }
      if (_closed) return;
      _connect(
        farmId: farmId,
        cursor: cursor,
        ticket: ticket,
        onMessage: onMessage,
      );
    } catch (error) {
      if (!_closed) onMessage(const SignalSseMessage(SignalSseControl.failed));
    }
  }

  void _connect({
    required String farmId,
    required String cursor,
    required String ticket,
    required void Function(SignalSseMessage message) onMessage,
  }) {
    final base = ApiClient.instance.baseUrl;
    final query = Uri(queryParameters: {
      'ticket': ticket,
      'cursor': cursor,
    }).query;
    final source = web.EventSource('$base/farms/$farmId/signals/stream?$query');
    _source = source;

    source.addEventListener(
      'open',
      ((web.Event _) {
        if (_closed) return;
        _failures = 0;
        onMessage(const SignalSseMessage(SignalSseControl.connected));
      }).toJS,
    );
    source.addEventListener(
      'signal-changed',
      ((web.Event event) {
        if (_closed) return;
        onMessage(_message(SignalSseControl.changed, event));
      }).toJS,
    );
    source.addEventListener(
      'signal-reconnect',
      ((web.Event event) {
        if (_closed) return;
        onMessage(_message(SignalSseControl.reconnect, event));
      }).toJS,
    );
    source.addEventListener(
      'error',
      ((web.Event _) {
        if (_closed) return;
        _failures++;
        if (source.readyState == web.EventSource.CLOSED || _failures >= 3) {
          close();
          onMessage(const SignalSseMessage(SignalSseControl.failed));
          return;
        }
        onMessage(const SignalSseMessage(SignalSseControl.interrupted));
      }).toJS,
    );
  }

  SignalSseMessage _message(SignalSseControl control, web.Event event) {
    try {
      final messageEvent = event as web.MessageEvent;
      final raw = messageEvent.data?.dartify();
      final Object? decoded = raw is String ? jsonDecode(raw) : raw;
      final data = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : null;
      return SignalSseMessage(control, data: data);
    } catch (_) {
      // Changed events only ask Signal Store to reconcile; a malformed hint
      // must not become an unhandled browser callback and break polling.
      return SignalSseMessage(control);
    }
  }

  @override
  void close() {
    _closed = true;
    _source?.close();
    _source = null;
  }
}

SignalRealtimeTransport createSignalTransport() => PlatformSignalTransport();
