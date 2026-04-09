import 'package:flutter/widgets.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/demo_app.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appMode = parseAppMode(
    const String.fromEnvironment('APP_MODE', defaultValue: 'mock'),
  );

  if (appMode.isLive) {
    const apiRole = String.fromEnvironment('API_ROLE', defaultValue: 'owner');
    await ApiCache.instance.init(apiRole);
  }

  runApp(const DemoApp());
}
