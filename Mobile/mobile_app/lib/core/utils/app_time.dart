import 'package:intl/intl.dart';

/// Single entry point for rendering backend timestamps.
///
/// The backend stores and serves every instant as UTC (ISO-8601 with `Z`).
/// Everything the user sees must go through [parseApiTime] or the format
/// helpers below so it is rendered in the ACTIVE PRESENTATION timezone —
/// resolved as (ruling 2026-10-12):
///
///   "我的"手动时区选择 → 活跃牧场(→租户→平台默认)链 → 设备时区
///
/// The farm switcher feeds [setFarmChainOffsetMinutes]; the mine settings
/// feed [setUserOverrideOffsetMinutes]. Storage stays UTC everywhere.

int? _userOverrideOffsetMinutes;
int? _farmChainOffsetMinutes;

/// User's manual choice from 我的手动设置 (null = 跟随牧场/系统).
void setUserOverrideOffsetMinutes(int? minutes) {
  _userOverrideOffsetMinutes = minutes;
}

/// Called by the farm switcher when the active farm (or its list) resolves.
/// null = no farm offset known.
void setFarmChainOffsetMinutes(int? minutes) {
  _farmChainOffsetMinutes = minutes;
}

/// Legacy alias kept for existing call sites.
void setTenantOffsetMinutes(int? minutes) => setFarmChainOffsetMinutes(minutes);

/// Active presentation offset: user override → farm chain → device.
int activeTzOffsetMinutes() =>
    _userOverrideOffsetMinutes ??
    _farmChainOffsetMinutes ??
    DateTime.now().timeZoneOffset.inMinutes;

/// Parses a backend UTC ISO timestamp into the active presentation timezone.
/// Returns null for null/unparseable input; callers decide the fallback text.
DateTime? parseApiTime(String? iso) {
  if (iso == null) return null;
  final dt = DateTime.tryParse(iso);
  if (dt == null) return null;
  final utc = dt.toUtc();
  return utc.add(Duration(minutes: activeTzOffsetMinutes()));
}

/// `M/d HH:mm` — user-facing pages and data-point labels.
String formatMdhm(DateTime dt) => DateFormat('M/d HH:mm').format(dt);

/// `MM-dd HH:mm` — admin pages (GPS quality etc.).
String formatDashMdhm(DateTime dt) => DateFormat('MM-dd HH:mm').format(dt);

/// `yyyy-MM-dd HH:mm`.
String formatYmdhm(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);

/// `HH:mm`.
String formatHm(DateTime dt) => DateFormat('HH:mm').format(dt);

/// `HH:mm:ss`.
String formatHms(DateTime dt) => DateFormat('HH:mm:ss').format(dt);

/// The active presentation UTC offset in minutes (e.g. 480 for UTC+8) —
/// user override → farm chain → device. Sent with bucketing requests so
/// the server groups days/hours on the active calendar; see each endpoint's
/// `tzOffsetMinutes` param.
int localTzOffsetMinutes() => activeTzOffsetMinutes();
