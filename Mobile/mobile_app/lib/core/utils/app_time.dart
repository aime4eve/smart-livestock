import 'package:intl/intl.dart';

/// Single entry point for rendering backend timestamps.
///
/// The backend stores and serves every instant as UTC (ISO-8601 with `Z`).
/// Everything the user sees must go through [parseApiTime] or the format
/// helpers below so it is rendered in the ACTIVE FARM's timezone — the
/// farm → tenant → platform chain resolved server-side and delivered as
/// `utcOffsetMinutes` on the farm payload (ruling 2026-10-12). Before that
/// value is known we fall back to the device timezone, the pre-tenant
/// behavior.

int? _tenantOffsetMinutes;

/// Called by the farm switcher when the active farm (or its list) resolves.
/// null = no farm offset known → device timezone fallback.
void setTenantOffsetMinutes(int? minutes) {
  _tenantOffsetMinutes = minutes;
}

/// Active presentation offset: tenant/farm chain first, device fallback.
int activeTzOffsetMinutes() =>
    _tenantOffsetMinutes ?? DateTime.now().timeZoneOffset.inMinutes;

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
/// the farm/tenant chain when known, else the device offset. Sent with
/// bucketing requests so the server groups days/hours on the farm's
/// calendar; see each endpoint's `tzOffsetMinutes` param.
int localTzOffsetMinutes() => activeTzOffsetMinutes();
