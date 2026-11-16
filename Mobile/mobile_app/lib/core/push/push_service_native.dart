import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';

/// NIX-430: APNs push bridge (iOS first; Android/FCM deferred). The native
/// AppDelegate drives remote-notification registration and forwards
/// token/tap events over the `app/push` channel; this service uploads
/// tokens to the server and turns notification taps into deep links.
void initPush() {
  if (!Platform.isIOS) return; // iOS only for now
  _PushService.instance.init();
}

void attachPushRouter(GoRouter router) {
  _PushService.instance.attachRouter(router);
}

class _PushService {
  _PushService._();

  static final _PushService instance = _PushService._();

  static const MethodChannel _channel = MethodChannel('app/push');
  bool _initialized = false;
  String? _lastUploadedToken;
  GoRouter? _router;

  void attachRouter(GoRouter router) => _router = router;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_onMethodCall);
    try {
      final granted =
          await _channel.invokeMethod<bool>('requestAuthorization') ?? false;
      if (granted) {
        // didRegisterForRemoteNotificationsWithDeviceToken answers onToken.
        await _channel.invokeMethod('requestToken');
      }
    } on PlatformException catch (e) {
      // Push is best-effort at startup — never block the app on it.
      debugPrint('[push] init failed: $e');
    }
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onToken':
        final token = call.arguments as String?;
        if (token != null && token.isNotEmpty) {
          await _uploadToken(token);
        }
        return null;
      case 'onTap':
        _handleTap((call.arguments as Map?)?.cast<String, Object?>());
        return null;
      default:
        return null;
    }
  }

  Future<void> _uploadToken(String token) async {
    if (token == _lastUploadedToken) return; // unchanged since last upload
    try {
      await ApiClient.instance.post('/push/register', body: {
        'platform': 'ios',
        'token': token,
      });
      _lastUploadedToken = token;
    } catch (e) {
      // Offline / logged out — retried at the next token event or app start.
      _lastUploadedToken = null;
      debugPrint('[push] token upload deferred: $e');
    }
  }

  void _handleTap(Map<String, Object?>? payload) {
    // Notification taps land on the alert workbench; per-alert deep links
    // can refine this once the alert detail route carries an id parameter.
    _router?.go('/alerts');
  }
}
