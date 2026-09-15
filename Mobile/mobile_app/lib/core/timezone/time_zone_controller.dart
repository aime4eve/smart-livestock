import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted client time-zone preference (null = follow system).
final initialTimeZoneIdProvider = Provider<String?>((ref) => null);

/// IANA ids that resolve to China Standard Time (UTC+8, 北京/上海时区).
/// GCJ-02 coverage is mainland China; HK/MO included for practical purposes.
const _chinaTimeZoneIds = <String>{
  'Asia/Shanghai',
  'Asia/Chongqing',
  'Asia/Harbin',
  'Asia/Urumqi',
  'Asia/Hong_Kong',
  'Asia/Macau',
  'Asia/Taipei',
};

/// True when [id] is a China time zone. Null [id] (follow system) falls back
/// to a UTC+8 offset heuristic — IANA ids are not reliably exposed on iOS.
bool isChinaTimeZone(String? id) {
  if (id != null) return _chinaTimeZoneIds.contains(id);
  return DateTime.now().timeZoneOffset == const Duration(hours: 8);
}

/// Curated picker options (id → display). Null id = follow system.
const timeZonePickerOptions = <String?>[
  null,
  'Asia/Shanghai',
  'Asia/Hong_Kong',
  'UTC',
  'Europe/London',
  'America/New_York',
  'Australia/Sydney',
];

class TimeZoneController extends Notifier<String?> {
  static const _prefsKey = 'app_time_zone';

  @override
  String? build() => ref.read(initialTimeZoneIdProvider);

  /// Whether maps should use the GCJ-02 Chinese source (高德) right now.
  bool get useChinaTileSource => isChinaTimeZone(state);

  /// Reads the persisted time zone. Call once before runApp (mirrors the
  /// locale-restore flow).
  static Future<String?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }

  /// Sets the time zone and persists it. Null = follow system.
  Future<void> setTimeZone(String? id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_prefsKey, id);
    } else {
      await prefs.remove(_prefsKey);
    }
  }
}

final timeZoneControllerProvider =
    NotifierProvider<TimeZoneController, String?>(TimeZoneController.new);
