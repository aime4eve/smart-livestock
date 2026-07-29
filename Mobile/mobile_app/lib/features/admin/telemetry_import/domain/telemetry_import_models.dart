import 'package:flutter/foundation.dart';

/// Defensive numeric coercion: accepts num or its string form.
int _asInt(Object? v) => _asIntOrNull(v) ?? 0;

int? _asIntOrNull(Object? v) =>
    v is num ? v.toInt() : (v == null ? null : int.tryParse('$v'));

double? _asDoubleOrNull(Object? v) =>
    v is num ? v.toDouble() : (v == null ? null : double.tryParse('$v'));

/// Row classification of a parsed telemetry frame (spec §4.1 Row.status).
enum TelemetryRowStatus {
  importable,
  duplicate,
  skippedDownlink,
  skippedUnsupported,
  invalid,
  unknown,
}

/// Device match outcome for the uploaded file (spec §4.1 DeviceMatchDto).
@immutable
class TelemetryDeviceMatch {
  const TelemetryDeviceMatch({
    required this.matched,
    this.devEui = '',
    this.deviceCode = '',
    this.deviceType = '',
    this.livestockName = '',
    this.farmName = '',
    this.error,
  });

  final bool matched;
  final String devEui;
  final String deviceCode;
  final String deviceType;
  final String livestockName;
  final String farmName;

  /// Backend message key (e.g. error.telemetryImport.deviceNotRegistered)
  /// explaining why the device did not match; null when matched.
  final String? error;

  factory TelemetryDeviceMatch.fromJson(Map<String, dynamic> json) =>
      TelemetryDeviceMatch(
        matched: json['matched'] as bool? ?? false,
        devEui: json['devEui'] as String? ?? '',
        deviceCode: json['deviceCode'] as String? ?? '',
        deviceType: json['deviceType'] as String? ?? '',
        livestockName: json['livestockName'] as String? ?? '',
        farmName: json['farmName'] as String? ?? '',
        error: json['error'] as String?,
      );
}

/// One parsed xlsx row in the preview (spec §4.1 Row).
@immutable
class TelemetryRowPreview {
  const TelemetryRowPreview({
    required this.rowNo,
    this.frameCounter = '',
    this.recordTime,
    this.battery,
    this.latitude,
    this.longitude,
    this.stepCount,
    this.status = TelemetryRowStatus.unknown,
    this.error,
  });

  final int rowNo;
  final String frameCounter;
  final DateTime? recordTime;
  final int? battery;
  final double? latitude;
  final double? longitude;
  final int? stepCount;
  final TelemetryRowStatus status;

  /// Row-level backend message key (e.g. error.telemetryImport.invalidHex).
  final String? error;

  factory TelemetryRowPreview.fromJson(Map<String, dynamic> json) =>
      TelemetryRowPreview(
        rowNo: _asInt(json['rowNo']),
        frameCounter: '${json['frameCounter'] ?? ''}',
        recordTime: DateTime.tryParse('${json['recordTime'] ?? ''}'),
        battery: _asIntOrNull(json['battery']),
        latitude: _asDoubleOrNull(json['latitude']),
        longitude: _asDoubleOrNull(json['longitude']),
        stepCount: _asIntOrNull(json['stepCount']),
        status: _parseStatus(json['status'] as String? ?? ''),
        error: json['error'] as String?,
      );

  static TelemetryRowStatus _parseStatus(String s) => switch (s) {
        'IMPORTABLE' => TelemetryRowStatus.importable,
        'DUPLICATE' => TelemetryRowStatus.duplicate,
        'SKIPPED_DOWNLINK' => TelemetryRowStatus.skippedDownlink,
        'SKIPPED_UNSUPPORTED' => TelemetryRowStatus.skippedUnsupported,
        'INVALID' => TelemetryRowStatus.invalid,
        _ => TelemetryRowStatus.unknown,
      };
}

/// Parse-only preview result (spec §4.1 TelemetryParseResultDto, zero persistence).
@immutable
class TelemetryParseResult {
  const TelemetryParseResult({
    this.totalRows = 0,
    this.uplinkRows = 0,
    this.decodableRows = 0,
    this.importableRows = 0,
    this.gpsPointRows = 0,
    this.duplicateRows = 0,
    this.skippedRows = 0,
    this.invalidRows = 0,
    this.device = const TelemetryDeviceMatch(matched: false),
    this.rows = const [],
  });

  final int totalRows;
  final int uplinkRows;
  final int decodableRows;
  final int importableRows;
  final int gpsPointRows;
  final int duplicateRows;
  final int skippedRows;
  final int invalidRows;
  final TelemetryDeviceMatch device;
  final List<TelemetryRowPreview> rows;

  factory TelemetryParseResult.fromJson(Map<String, dynamic> json) =>
      TelemetryParseResult(
        totalRows: _asInt(json['totalRows']),
        uplinkRows: _asInt(json['uplinkRows']),
        decodableRows: _asInt(json['decodableRows']),
        importableRows: _asInt(json['importableRows']),
        gpsPointRows: _asInt(json['gpsPointRows']),
        duplicateRows: _asInt(json['duplicateRows']),
        skippedRows: _asInt(json['skippedRows']),
        invalidRows: _asInt(json['invalidRows']),
        device: json['device'] is Map<String, dynamic>
            ? TelemetryDeviceMatch.fromJson(
                json['device'] as Map<String, dynamic>)
            : const TelemetryDeviceMatch(matched: false),
        rows: (json['rows'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TelemetryRowPreview.fromJson)
            .toList(),
      );
}

/// Import execution result (spec §4.1 TelemetryImportResultDto).
@immutable
class TelemetryImportResult {
  const TelemetryImportResult({
    this.telemetryCreated = 0,
    this.gpsCreated = 0,
    this.duplicateSkipped = 0,
    this.skippedRows = 0,
    this.invalidRows = 0,
    this.failedRows = 0,
    this.devEui = '',
    this.deviceCode = '',
  });

  final int telemetryCreated;
  final int gpsCreated;
  final int duplicateSkipped;
  final int skippedRows;
  final int invalidRows;
  final int failedRows;
  final String devEui;
  final String deviceCode;

  factory TelemetryImportResult.fromJson(Map<String, dynamic> json) =>
      TelemetryImportResult(
        telemetryCreated: _asInt(json['telemetryCreated']),
        gpsCreated: _asInt(json['gpsCreated']),
        duplicateSkipped: _asInt(json['duplicateSkipped']),
        skippedRows: _asInt(json['skippedRows']),
        invalidRows: _asInt(json['invalidRows']),
        failedRows: _asInt(json['failedRows']),
        devEui: json['devEui'] as String? ?? '',
        deviceCode: json['deviceCode'] as String? ?? '',
      );
}
