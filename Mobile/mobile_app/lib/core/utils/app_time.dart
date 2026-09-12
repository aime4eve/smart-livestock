import 'package:intl/intl.dart';

/// Single entry point for rendering backend timestamps.
///
/// The backend stores and serves every instant as UTC (ISO-8601 with `Z`).
/// Everything the user sees must go through [parseApiTime] or the format
/// helpers below so it is rendered in the device timezone — never format a
/// raw parsed DateTime without [toLocal], never build display text from
/// `.hour`/`.month` of an unparsed value.

/// Parses a backend UTC ISO timestamp into device-local time.
/// Returns null for null/unparseable input; callers decide the fallback text.
DateTime? parseApiTime(String? iso) {
  if (iso == null) return null;
  final dt = DateTime.tryParse(iso);
  return dt?.toLocal();
}

/// `M/d HH:mm` in device time — user-facing pages and data-point labels.
String formatMdhm(DateTime dt) => DateFormat('M/d HH:mm').format(dt.toLocal());

/// `MM-dd HH:mm` in device time — admin pages (GPS quality etc.).
String formatDashMdhm(DateTime dt) =>
    DateFormat('MM-dd HH:mm').format(dt.toLocal());

/// `yyyy-MM-dd HH:mm` in device time.
String formatYmdhm(DateTime dt) =>
    DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());

/// `HH:mm` in device time.
String formatHm(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());

/// `HH:mm:ss` in device time.
String formatHms(DateTime dt) => DateFormat('HH:mm:ss').format(dt.toLocal());

/// The device's current UTC offset in minutes (e.g. 480 for UTC+8).
/// Sent with bucketing requests so the server groups days/hours on the
/// user's local calendar; see each endpoint's `tzOffsetMinutes` param.
int localTzOffsetMinutes() => DateTime.now().timeZoneOffset.inMinutes;
