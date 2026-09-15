import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/app/demo_app.dart';
import 'package:hkt_livestock_agentic/app/session/app_session.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/app/url_strategy.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/l10n/locale_controller.dart';
import 'package:hkt_livestock_agentic/core/api/jwt_decoder.dart';
import 'package:hkt_livestock_agentic/core/api/jwt_storage.dart';
import 'package:hkt_livestock_agentic/core/database/app_database.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/core/timezone/time_zone_controller.dart';

SemanticsHandle? _webSemanticsHandle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategyIfWeb();
  if (kIsWeb) {
    _webSemanticsHandle ??= WidgetsBinding.instance.ensureSemantics();
  }

  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  if (apiBaseUrl.isNotEmpty) {
    ApiClient.instance.setBaseUrl(apiBaseUrl);
  }

  // Seed AppDatabase via path_provider (correct sandbox path on every
  // platform) before any provider touches AppDatabase.instance, whose sync
  // constructor cannot resolve an app-support dir on iOS.
  await AppDatabase.createAsync();

  // Restore session from stored JWT token (survives page refresh).
  final initialSession = await _restoreSession();
  debugPrint('boot: session restored (${initialSession.isLoggedIn})');
  // Restore persisted locale so the language choice survives a page refresh.
  final initialLocale = await LocaleController.restore();
  debugPrint('boot: locale restored ($initialLocale)');
  // Restore persisted time zone so map tile source choice survives restart.
  final initialTimeZoneId = await TimeZoneController.restore();
  debugPrint('boot: time zone restored ($initialTimeZoneId)');

  debugPrint('boot: runApp');
  runApp(
    ProviderScope(
      overrides: [
        initialSessionProvider.overrideWithValue(initialSession),
        initialLocaleProvider.overrideWithValue(initialLocale),
        initialTimeZoneIdProvider.overrideWithValue(initialTimeZoneId),
      ],
      child: const DemoApp(),
    ),
  );
}

/// Read stored token + user info, decode JWT to check expiry,
/// and return an authenticated session if valid.
Future<AppSession> _restoreSession() async {
  final token = await JwtStorage.instance.getAccessToken();
  if (token == null) return AppSession.loggedOut;

  final payload = JwtDecoder.tryDecode(token);
  if (payload == null) {
    await JwtStorage.instance.clear();
    return AppSession.loggedOut;
  }

  if (JwtDecoder.isExpired(payload)) {
    await JwtStorage.instance.clear();
    return AppSession.loggedOut;
  }

  final userInfo = await JwtStorage.instance.getUserInfo();
  if (userInfo == null) {
    await JwtStorage.instance.clear();
    return AppSession.loggedOut;
  }

  // Restore active farmId so farm-scoped APIs work after page refresh.
  final activeFarmId = await JwtStorage.instance.getActiveFarmId();
  if (activeFarmId != null) {
    ApiClient.instance.setActiveFarmId(activeFarmId);
  }

  return AppSession.authenticated(
    role: UserRole.fromString(payload['role'] as String? ?? ''),
    accessToken: token,
    userId: userInfo['id'] as int?,
    userName: userInfo['name'] as String?,
    phone: userInfo['phone'] as String?,
    tenantId: userInfo['tenantId'] as int?,
    username: userInfo['username'] as String?,
    activeFarmId: activeFarmId,
  );
}
// build-1783647087
