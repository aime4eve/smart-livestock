/// Parsing helpers for device EUI values carried in QR codes and barcodes.
library;

/// A payload that is exactly 16 hex digits, e.g. the QR code on TB ear tags.
final RegExp _bareEuiPattern = RegExp(r'^[0-9a-fA-F]{16}$');

/// A 16-hex-digit run bounded by non-hex characters (or string edges), e.g.
/// `DevEui:0095690A00008C91` printed under the Code128 barcode on GAT labels.
final RegExp _boundedEuiPattern =
    RegExp(r'(?<![0-9a-fA-F])[0-9a-fA-F]{16}(?![0-9a-fA-F])');

/// Parses a scanned barcode payload into a normalized 16-hex-digit EUI.
///
/// Device labels carry either the bare EUI (e.g. `70B3D57ED0069A12`) or a
/// wider string that embeds it (e.g. `DevEui:70B3D57ED0069A12`). Returns the
/// lowercased EUI, or `null` when the payload contains no bounded 16-hex run —
/// the caller should fall back to manual entry in that case.
String? parseDeviceEui(String raw) {
  final value = raw.trim();
  if (_bareEuiPattern.hasMatch(value)) return value.toLowerCase();
  return _boundedEuiPattern.firstMatch(value)?.group(0)?.toLowerCase();
}
