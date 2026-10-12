import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hkt_livestock_agentic/core/utils/app_time.dart';

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

/// Tile-datum verdict for a FARM-configured timezone (ruling 2026-10-12):
/// a farm's explicit timezone declares which coordinate datum its registry
/// coordinates use — China-zone ids mean GCJ-02 (高德), anything else means
/// WGS-84 (OSM). Returns null when the farm has no timezone configured, so
/// callers fall back to the user/device heuristic.
bool? farmTimezoneTileDatumIsChina(String? farmTimezone) {
  if (farmTimezone == null || farmTimezone.isEmpty) return null;
  return _chinaTimeZoneIds.contains(farmTimezone);
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

/// Standard UTC offsets (minutes) for the curated picker ids. DST shifts are
/// not reflected — the curated list matches the settings UI semantics.
const timeZoneStandardOffsets = <String, int>{
  'Asia/Shanghai': 480,
  'Asia/Hong_Kong': 480,
  'UTC': 0,
  'Europe/London': 0,
  'America/New_York': -300,
  'Australia/Sydney': 600,
};

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

  /// Sets the time zone and persists it. Null = 跟随牧场/系统 (the farm →
  /// tenant → platform chain drives presentation again, ruling 2026-10-12).
  Future<void> setTimeZone(String? id) async {
    state = id;
    setUserOverrideOffsetMinutes(id == null ? null : timeZoneStandardOffsets[id]);
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
