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

/// NIX-430: re-upload when the session turns authenticated — covers the
/// first-install-before-login window and account switches (the token event
/// fires only once per launch, before any user is logged in).
Future<void> retryPushTokenUpload() {
  return _PushService.instance.retryTokenUpload();
}

/// NIX-430: release the device token on sign-out so the next user's login
/// re-registers it against their account.
Future<void> notifyPushSignedOut() {
  return _PushService.instance.signedOut();
}

class _PushService {
  _PushService._();

  static final _PushService instance = _PushService._();

  static const MethodChannel _channel = MethodChannel('app/push');
  bool _initialized = false;
  String? _lastUploadedToken;
  String? _pendingToken;
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

  Future<void> retryTokenUpload() async {
    final token = _pendingToken;
    if (token == null) return;
    await _uploadToken(token);
  }

  Future<void> signedOut() async {
    final token = _pendingToken;
    _lastUploadedToken = null;
    if (token == null) return;
    try {
      await ApiClient.instance.post('/push/unregister', body: {
        'token': token,
      });
    } catch (e) {
      debugPrint('[push] unregister on sign-out deferred: $e');
    }
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onToken':
        final token = call.arguments as String?;
        if (token != null && token.isNotEmpty) {
          _pendingToken = token;
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
      // Offline / logged out — retried on session change or next launch.
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
