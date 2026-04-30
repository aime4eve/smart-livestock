import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/app/url_strategy.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';

SemanticsHandle? _webSemanticsHandle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategyIfWeb();
  if (kIsWeb) {
    _webSemanticsHandle ??= WidgetsBinding.instance.ensureSemantics();
  }

  final appMode = parseAppMode(
    const String.fromEnvironment('APP_MODE', defaultValue: 'mock'),
  );

  if (appMode.isLive) {
    const apiRole = String.fromEnvironment('API_ROLE', defaultValue: 'owner');
    await ApiCache.instance.initWithRoleAuth(apiRole);
  }

  runApp(DemoApp(appMode: appMode));
}
