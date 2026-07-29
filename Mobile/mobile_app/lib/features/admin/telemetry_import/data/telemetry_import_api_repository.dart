import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/admin/telemetry_import/domain/telemetry_import_models.dart';

/// Platform-level (non farm-scoped) repository for the telemetry import admin
/// API (NIX-79).
///
/// Base path: /api/v1/admin/telemetry-import
class TelemetryImportApiRepository {
  const TelemetryImportApiRepository();

  static const _base = '/admin/telemetry-import';

  /// Parse an xlsx export for preview (parse-only, no persistence).
  Future<TelemetryParseResult> parse(
      List<int> fileBytes, String fileName) async {
    final data = await ApiClient.instance
        .uploadFile('$_base/parse', fileBytes, fileName);
    return TelemetryParseResult.fromJson(data);
  }

  /// Upload an xlsx export and persist the importable rows.
  Future<TelemetryImportResult> importTelemetry(
      List<int> fileBytes, String fileName) async {
    final data = await ApiClient.instance
        .uploadFile('$_base/import', fileBytes, fileName);
    return TelemetryImportResult.fromJson(data);
  }
}
