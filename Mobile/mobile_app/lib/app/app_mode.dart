import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode {
  mock,
  live,
}

extension AppModeX on AppMode {
  String get envValue => name;

  String get label {
    switch (this) {
      case AppMode.mock:
        return 'Mock 场景';
      case AppMode.live:
        return 'Live 联调';
    }
  }

  bool get isMock => this == AppMode.mock;

  bool get isLive => this == AppMode.live;
}

AppMode parseAppMode(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'live':
      return AppMode.live;
    case 'mock':
    case null:
    case '':
      return AppMode.mock;
    default:
      return AppMode.mock;
  }
}

final appModeProvider = Provider<AppMode>((ref) {
  return parseAppMode(
    const String.fromEnvironment('APP_MODE', defaultValue: 'mock'),
  );
});
