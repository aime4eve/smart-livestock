import 'package:flutter/foundation.dart';

/// Quality grade based on P95 and effective points.
enum QualityGrade { excellent, usable, marginal, unavailable }

/// RTK reference point — ground-truth coordinate for static GPS testing.
@immutable
class RtkPoint {
  const RtkPoint({
    required this.id,
    required this.locationName,
    required this.pointLabel,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String locationName;
  final String pointLabel;
  final double latitude;
  final double longitude;

  factory RtkPoint.fromJson(Map<String, dynamic> json) => RtkPoint(
        id: json['id'] as int,
        locationName: json['locationName'] as String,
        pointLabel: json['pointLabel'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'locationName': locationName,
        'pointLabel': pointLabel,
        'latitude': latitude,
        'longitude': longitude,
      };
}
/// A reusable dynamic test route definition.
@immutable
class DynamicRoute {
  const DynamicRoute({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DynamicRoute.fromJson(Map<String, dynamic> json) => DynamicRoute(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
      };
}

/// A single ordered point in a dynamic test route.
@immutable
class DynamicRoutePoint {
  const DynamicRoutePoint({
    required this.id,
    required this.routeId,
    required this.rtkPointId,
    required this.sequenceNo,
  });

  final int id;
  final int routeId;
  final int rtkPointId;
  final int sequenceNo;

  factory DynamicRoutePoint.fromJson(Map<String, dynamic> json) =>
      DynamicRoutePoint(
        id: json['id'] as int? ?? 0,
        routeId: json['routeId'] as int,
        rtkPointId: json['rtkPointId'] as int,
        sequenceNo: json['sequenceNo'] as int,
      );
}

/// Dynamic quality report — route-driven matching results.
@immutable
class DynamicQualityReport {
  const DynamicQualityReport({
    required this.testId,
    required this.deviceId,
    required this.deviceCode,
    required this.routeId,
    required this.routeName,
    required this.startedAt,
    this.endedAt,
    required this.threshold,
    required this.grade,
    required this.stats,
    required this.perPoint,
    this.passes = const [],
    this.staticComparison,
  });

  final int testId;
  final int deviceId;
  final String deviceCode;
  final int routeId;
  final String routeName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double threshold;
  final QualityGrade grade;
  final DynamicQualityStats stats;
  final List<DynamicPointSummary> perPoint;
  final List<DynamicMatchedPass> passes;
  final DynamicStaticComparison? staticComparison;

  factory DynamicQualityReport.fromJson(Map<String, dynamic> json) =>
      DynamicQualityReport(
        testId: json['testId'] as int? ?? 0,
        deviceId: json['deviceId'] as int? ?? 0,
        deviceCode: json['deviceCode'] as String? ?? '',
        routeId: json['routeId'] as int? ?? 0,
        routeName: json['routeName'] as String? ?? '',
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : DateTime.now(),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
        grade: _parseGrade(json['grade'] as String? ?? 'UNAVAILABLE'),
        stats: DynamicQualityStats.fromJson(
            json['stats'] as Map<String, dynamic>? ?? const {}),
        perPoint: (json['perPoint'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DynamicPointSummary.fromJson)
            .toList(),
        passes: (json['passes'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DynamicMatchedPass.fromJson)
            .toList(),
        staticComparison: json['staticComparison'] != null
            ? DynamicStaticComparison.fromJson(
                json['staticComparison'] as Map<String, dynamic>)
            : null,
      );

  static QualityGrade _parseGrade(String s) => switch (s) {
        'EXCELLENT' => QualityGrade.excellent,
        'USABLE' => QualityGrade.usable,
        'MARGINAL' => QualityGrade.marginal,
        'UNAVAILABLE' => QualityGrade.unavailable,
        _ => QualityGrade.unavailable,
      };
}

/// Dynamic quality statistics (route-driven matching metrics).
@immutable
class DynamicQualityStats {
  const DynamicQualityStats({
    this.routePointCount = 0,
    this.matchedCount = 0,
    this.missedCount = 0,
    this.ambiguousCount = 0,
    this.transitCount = 0,
    this.inOrder = true,
    this.coverage = 0,
    this.meanError = 0,
    this.p50 = 0,
    this.p95 = 0,
    this.maxError = 0,
  });

  final int routePointCount;
  final int matchedCount;
  final int missedCount;
  final int ambiguousCount;
  final int transitCount;
  final bool inOrder;
  final double coverage;
  final double meanError;
  final double p50;
  final double p95;
  final double maxError;

  factory DynamicQualityStats.fromJson(Map<String, dynamic> json) =>
      DynamicQualityStats(
        routePointCount: json['routePointCount'] as int? ?? 0,
        matchedCount: json['matchedCount'] as int? ?? 0,
        missedCount: json['missedCount'] as int? ?? 0,
        ambiguousCount: json['ambiguousCount'] as int? ?? 0,
        transitCount: json['transitCount'] as int? ?? 0,
        inOrder: json['inOrder'] as bool? ?? true,
        coverage: (json['coverage'] as num?)?.toDouble() ?? 0,
        meanError: (json['meanError'] as num?)?.toDouble() ?? 0,
        p50: (json['p50'] as num?)?.toDouble() ?? 0,
        p95: (json['p95'] as num?)?.toDouble() ?? 0,
        maxError: (json['maxError'] as num?)?.toDouble() ?? 0,
      );
}

/// One route point's match outcome in a dynamic test.
@immutable
class DynamicPointSummary {
  const DynamicPointSummary({
    required this.rtkPointId,
    required this.locationName,
    required this.label,
    required this.sequenceNo,
    required this.passed,
    required this.ambiguous,
    this.error,
    this.matchedAt,
  });

  final int rtkPointId;
  final String locationName;
  final String label;
  final int sequenceNo;
  final bool passed;
  final bool ambiguous;
  final double? error;
  final DateTime? matchedAt;

  factory DynamicPointSummary.fromJson(Map<String, dynamic> json) =>
      DynamicPointSummary(
        rtkPointId: json['rtkPointId'] as int? ?? 0,
        locationName: json['locationName'] as String? ?? '',
        label: json['label'] as String? ?? '',
        sequenceNo: json['sequenceNo'] as int? ?? 0,
        passed: json['passed'] as bool? ?? false,
        ambiguous: json['ambiguous'] as bool? ?? false,
        error: (json['error'] as num?)?.toDouble(),
        matchedAt: json['matchedAt'] != null
            ? DateTime.parse(json['matchedAt'] as String)
            : null,
      );
}

/// A matched GPS sample in a dynamic test (for map rendering).
@immutable
class DynamicMatchedPass {
  const DynamicMatchedPass({
    required this.sequenceNo,
    required this.latitude,
    required this.longitude,
    required this.rtkLatitude,
    required this.rtkLongitude,
    required this.error,
    required this.ambiguous,
    required this.recordedAt,
  });

  final int sequenceNo;
  final double latitude;
  final double longitude;
  final double rtkLatitude;
  final double rtkLongitude;
  final double error;
  final bool ambiguous;
  final DateTime recordedAt;

  factory DynamicMatchedPass.fromJson(Map<String, dynamic> json) =>
      DynamicMatchedPass(
        sequenceNo: json['sequenceNo'] as int? ?? 0,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        rtkLatitude: (json['rtkLatitude'] as num?)?.toDouble() ?? 0,
        rtkLongitude: (json['rtkLongitude'] as num?)?.toDouble() ?? 0,
        error: (json['error'] as num?)?.toDouble() ?? 0,
        ambiguous: json['ambiguous'] as bool? ?? false,
        recordedAt: json['recordedAt'] != null
            ? DateTime.parse(json['recordedAt'] as String)
            : DateTime.now(),
      );
}

/// Static-vs-dynamic comparison for the same device.
@immutable
class DynamicStaticComparison {
  const DynamicStaticComparison({
    required this.staticTestId,
    required this.staticP95,
    required this.staticGrade,
    required this.deltaP95,
  });

  final int staticTestId;
  final double staticP95;
  final QualityGrade staticGrade;
  final double deltaP95;

  factory DynamicStaticComparison.fromJson(Map<String, dynamic> json) =>
      DynamicStaticComparison(
        staticTestId: json['staticTestId'] as int? ?? 0,
        staticP95: (json['staticP95'] as num?)?.toDouble() ?? 0,
        staticGrade: _parseGradeStatic(json['staticGrade'] as String? ?? 'UNAVAILABLE'),
        deltaP95: (json['deltaP95'] as num?)?.toDouble() ?? 0,
      );

  static QualityGrade _parseGradeStatic(String s) => switch (s) {
        'EXCELLENT' => QualityGrade.excellent,
        'USABLE' => QualityGrade.usable,
        'MARGINAL' => QualityGrade.marginal,
        _ => QualityGrade.unavailable,
      };
}

/// GPS quality statistics for a single calibration session.
@immutable
class GpsQualityReport {
  const GpsQualityReport({
    required this.sessionId,
    required this.deviceCode,
    required this.rtkPoint,
    required this.startedAt,
    this.endedAt,
    required this.stats,
    required this.grade,
    required this.scatter,
  });

  final int sessionId;
  final String deviceCode;
  final RtkPoint rtkPoint;
  final DateTime startedAt;
  final DateTime? endedAt;
  final GpsQualityStats stats;
  final QualityGrade grade;
  final List<ScatterPoint> scatter;

  factory GpsQualityReport.fromJson(Map<String, dynamic> json) =>
      GpsQualityReport(
        sessionId: (json['testId'] ?? json['sessionId']) as int,
        deviceCode: json['deviceCode'] as String? ?? '',
        // Backend QualityReportDto has flat fields: rtkPointId, locationName,
        // label (no nested rtkPoint object, no lat/lng).
        rtkPoint: RtkPoint(
          id: json['rtkPointId'] as int? ?? 0,
          locationName: json['locationName'] as String? ?? '',
          pointLabel: json['label'] as String? ?? '',
          latitude: (json['rtkLatitude'] as num?)?.toDouble() ??
              (json['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (json['rtkLongitude'] as num?)?.toDouble() ??
              (json['longitude'] as num?)?.toDouble() ?? 0,
        ),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : DateTime.now(),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        stats: GpsQualityStats.fromJson(
            json['stats'] as Map<String, dynamic>? ?? const {}),
        grade: _parseGrade(json['grade'] as String? ?? 'UNAVAILABLE'),
        scatter: (json['scatter'] as List<dynamic>? ?? [])
            .map((e) => ScatterPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static QualityGrade _parseGrade(String s) => switch (s) {
        'EXCELLENT' => QualityGrade.excellent,
        'USABLE' => QualityGrade.usable,
        'MARGINAL' => QualityGrade.marginal,
        'UNAVAILABLE' => QualityGrade.unavailable,
        _ => QualityGrade.unavailable,
      };
}

/// Statistics computed from GPS points within a calibration window.
@immutable
class GpsQualityStats {
  const GpsQualityStats({
    required this.totalPoints,
    required this.suspectPoints,
    required this.effectivePoints,
    required this.meanError,
    required this.p50,
    required this.p95,
    this.p99,
    required this.maxError,
    required this.jitterDiameter,
    required this.outlierCount,
    required this.within15m,
    required this.within25m,
    required this.within40m,
  });

  final int totalPoints;
  final int suspectPoints;
  final int effectivePoints;
  final double meanError;
  final double p50;
  final double p95;
  final double? p99;
  final double maxError;
  final double jitterDiameter;
  final int outlierCount;
  final double within15m;
  final double within25m;
  final double within40m;

  factory GpsQualityStats.fromJson(Map<String, dynamic> json) =>
      GpsQualityStats(
        totalPoints: json['totalPoints'] as int? ?? 0,
        suspectPoints: json['suspectPoints'] as int? ?? 0,
        effectivePoints: json['effectivePoints'] as int? ?? 0,
        meanError: (json['meanError'] as num?)?.toDouble() ?? 0,
        p50: (json['p50'] as num?)?.toDouble() ?? 0,
        p95: (json['p95'] as num?)?.toDouble() ?? 0,
        p99: (json['p99'] as num?)?.toDouble(),
        maxError: (json['maxError'] as num?)?.toDouble() ?? 0,
        jitterDiameter: (json['jitterDiameter'] as num?)?.toDouble() ?? 0,
        outlierCount: json['outlierCount'] as int? ?? 0,
        within15m: (json['within15m'] as num?)?.toDouble() ?? 0,
        within25m: (json['within25m'] as num?)?.toDouble() ?? 0,
        within40m: (json['within40m'] as num?)?.toDouble() ?? 0,
      );
}

/// A single GPS scatter point with deviation from RTK truth.
@immutable
class ScatterPoint {
  const ScatterPoint({
    required this.latitude,
    required this.longitude,
    required this.error,
    required this.suspect,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final double error;
  final bool suspect;
  final DateTime recordedAt;

  factory ScatterPoint.fromJson(Map<String, dynamic> json) => ScatterPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        error: (json['error'] as num?)?.toDouble() ?? 0,
        suspect: json['suspect'] as bool? ?? false,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );
}

/// Brief device info for session creation selection.
@immutable
class DeviceBrief {
  const DeviceBrief({
    required this.id,
    required this.deviceCode,
  });

  final int id;
  final String deviceCode;

  factory DeviceBrief.fromJson(Map<String, dynamic> json) => DeviceBrief(
        id: json['id'] as int,
        deviceCode: json['deviceCode'] as String? ?? '',
      );
}

// ── NIX-21: New check-centric models ──────────────────────────────

/// A single GPS quality check (replaces session-based model).
/// Maps to GpsQualityTestDto from backend.
@immutable
class QualityCheck {
  const QualityCheck({
    required this.id,
    required this.deviceCode,
    this.deviceId,
    required this.checkType,
    this.rtkPointId,
    this.routeId,
    required this.startedAt,
    this.endedAt,
    this.status = 'READY',
    this.errorMessage,
    this.batchImportId,
    this.createdAt,
  });

  final int id;
  final String deviceCode;
  final int? deviceId;
  final String checkType; // STATIC / DYNAMIC / TRAJECTORY
  final int? rtkPointId;
  final int? routeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status; // READY / DEVICE_PENDING / FAILED
  final String? errorMessage;
  final int? batchImportId;
  final DateTime? createdAt;

  factory QualityCheck.fromJson(Map<String, dynamic> json) => QualityCheck(
        id: json['id'] as int,
        deviceCode: json['deviceCode'] as String? ?? '',
        deviceId: json['deviceId'] as int?,
        checkType: json['testType'] as String? ?? 'STATIC',
        rtkPointId: json['rtkPointId'] as int?,
        routeId: json['routeId'] as int?,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : DateTime.now(),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        status: json['status'] as String? ?? 'READY',
        errorMessage: json['errorMessage'] as String?,
        batchImportId: json['batchImportId'] as int?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

/// Paginated quality check list returned by GET /checks.
@immutable
class QualityCheckListResult {
  const QualityCheckListResult({
    required this.items,
    this.page = 0,
    this.pageSize = 20,
    this.total = 0,
  });

  final List<QualityCheck> items;
  final int page;
  final int pageSize;
  final int total;

  factory QualityCheckListResult.fromJson(Map<String, dynamic> json) =>
      QualityCheckListResult(
        items: (json['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(QualityCheck.fromJson)
            .toList(),
        page: json['page'] as int? ?? 0,
        pageSize: json['pageSize'] as int? ?? 20,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

/// Result of a batch GPS quality check import (Excel upload).
/// Maps to BatchImportResultDto from backend.
@immutable
class BatchImportResult {
  const BatchImportResult({
    this.batchId,
    this.totalRows = 0,
    this.totalSuccess = 0,
    this.totalPending = 0,
    this.totalFailed = 0,
    this.rows = const [],
  });

  final int? batchId;
  final int totalRows;
  final int totalSuccess;
  final int totalPending;
  final int totalFailed;
  final List<RowResult> rows;

  factory BatchImportResult.fromJson(Map<String, dynamic> json) =>
      BatchImportResult(
        batchId: json['batchId'] as int?,
        totalRows: json['totalRows'] as int? ?? 0,
        totalSuccess: json['totalSuccess'] as int? ?? 0,
        totalPending: json['totalPending'] as int? ?? 0,
        totalFailed: json['totalFailed'] as int? ?? 0,
        rows: (json['rows'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(RowResult.fromJson)
                .toList() ??
            [],
      );
}

/// A single row result within a batch import.
/// Maps to BatchImportResultDto.RowResult from backend.
@immutable
class RowResult {
  const RowResult({
    this.rowIndex = 0,
    this.status = '',
    this.eui = '',
    this.deviceCode,
    this.deviceId,
    this.checkId,
    this.message,
  });

  final int rowIndex;
  final String status; // READY / DEVICE_PENDING / FAILED / SKIPPED
  final String eui;
  final String? deviceCode;
  final int? deviceId;
  final int? checkId;
  final String? message;

  factory RowResult.fromJson(Map<String, dynamic> json) => RowResult(
        rowIndex: json['rowIndex'] as int? ?? 0,
        status: json['status'] as String? ?? '',
        eui: json['eui'] as String? ?? '',
        deviceCode: json['deviceCode'] as String?,
        deviceId: json['deviceId'] as int?,
        checkId: json['checkId'] as int?,
        message: json['message'] as String?,
      );
}

/// Result of parsing a batch import Excel file (parse-only, nothing persisted).
/// Maps to the response of POST /batch/parse.
@immutable
class BatchParseResult {
  const BatchParseResult({
    this.totalRows = 0,
    this.okCount = 0,
    this.warnCount = 0,
    this.errorCount = 0,
    this.rows = const [],
  });

  final int totalRows;
  final int okCount;
  final int warnCount;
  final int errorCount;
  final List<BatchParseRow> rows;

  factory BatchParseResult.fromJson(Map<String, dynamic> json) =>
      BatchParseResult(
        totalRows: json['totalRows'] as int? ?? 0,
        okCount: json['okCount'] as int? ?? 0,
        warnCount: json['warnCount'] as int? ?? 0,
        errorCount: json['errorCount'] as int? ?? 0,
        rows: (json['rows'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(BatchParseRow.fromJson)
                .toList() ??
            [],
      );
}

/// A single parsed row within a batch import preview.
@immutable
class BatchParseRow {
  const BatchParseRow({
    this.rowIndex = 0,
    this.eui = '',
    this.deviceCode,
    this.testType = 'STATIC',
    this.refName = '',
    this.rtkPointId,
    this.routeId,
    this.startedAt,
    this.endedAt,
    this.preStatus = '',
    this.message,
  });

  final int rowIndex;
  final String eui;
  final String? deviceCode;
  final String testType; // STATIC / DYNAMIC
  final String refName;
  final int? rtkPointId;
  final int? routeId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String preStatus; // OK / WARN / ERROR
  final String? message;

  factory BatchParseRow.fromJson(Map<String, dynamic> json) => BatchParseRow(
        rowIndex: json['rowIndex'] as int? ?? 0,
        eui: json['eui'] as String? ?? '',
        deviceCode: json['deviceCode'] as String?,
        testType: json['testType'] as String? ?? 'STATIC',
        refName: json['refName'] as String? ?? '',
        rtkPointId: json['rtkPointId'] as int?,
        routeId: json['routeId'] as int?,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        preStatus: json['preStatus'] as String? ?? '',
        message: json['message'] as String?,
      );
}

/// Multi-device dynamic comparison result for a single route.
/// Maps to the response of GET /comparison/dynamic.
@immutable
class DynamicComparisonResult {
  const DynamicComparisonResult({
    this.routeId = 0,
    this.routeName = '',
    this.devices = const [],
  });

  final int routeId;
  final String routeName;
  final List<DynamicComparisonRow> devices;

  factory DynamicComparisonResult.fromJson(Map<String, dynamic> json) =>
      DynamicComparisonResult(
        routeId: json['routeId'] as int? ?? 0,
        routeName: json['routeName'] as String? ?? '',
        devices: (json['devices'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(DynamicComparisonRow.fromJson)
                .toList() ??
            [],
      );
}

/// A single device's dynamic comparison summary within a route.
@immutable
class DynamicComparisonRow {
  const DynamicComparisonRow({
    this.deviceId = 0,
    this.deviceCode = '',
    this.eui = '',
    this.checkId = 0,
    this.coverage = 0,
    this.matchedCount = 0,
    this.missedCount = 0,
    this.ambiguousCount = 0,
    this.inOrder = true,
    this.meanError = 0,
    this.p50 = 0,
    this.p95 = 0,
    this.startedAt,
    this.endedAt,
  });

  final int deviceId;
  final String deviceCode;
  final String eui;
  final int checkId;
  final double coverage;
  final int matchedCount;
  final int missedCount;
  final int ambiguousCount;
  final bool inOrder;
  final double meanError;
  final double p50;
  final double p95;
  final DateTime? startedAt;
  final DateTime? endedAt;

  factory DynamicComparisonRow.fromJson(Map<String, dynamic> json) =>
      DynamicComparisonRow(
        deviceId: json['deviceId'] as int? ?? 0,
        deviceCode: json['deviceCode'] as String? ?? '',
        eui: json['eui'] as String? ?? '',
        checkId: json['checkId'] as int? ?? 0,
        coverage: (json['coverage'] as num?)?.toDouble() ?? 0,
        matchedCount: json['matchedCount'] as int? ?? 0,
        missedCount: json['missedCount'] as int? ?? 0,
        ambiguousCount: json['ambiguousCount'] as int? ?? 0,
        inOrder: json['inOrder'] as bool? ?? true,
        meanError: (json['meanError'] as num?)?.toDouble() ?? 0,
        p50: (json['p50'] as num?)?.toDouble() ?? 0,
        p95: (json['p95'] as num?)?.toDouble() ?? 0,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
      );
}

// ── NIX-22: RTK trajectory import (TRAJECTORY checks) ─────────────

QualityGrade trajectoryGradeFrom(String? s) => switch (s) {
      'EXCELLENT' => QualityGrade.excellent,
      'USABLE' => QualityGrade.usable,
      'MARGINAL' => QualityGrade.marginal,
      _ => QualityGrade.unavailable,
    };

/// One parsed file row of a trajectory import preview.
@immutable
class TrajectoryParseRow {
  const TrajectoryParseRow({
    required this.rowNo,
    required this.deviceEui,
    this.collectedAt,
    this.rtkLatitude,
    this.rtkLongitude,
    this.deviceLatitude,
    this.deviceLongitude,
    required this.matchMode, // FILE / GPS_LOG / UNPAIRED / INVALID
    this.error,
    this.matchedRecordedAt,
    this.timeDiffSec,
  });

  final int rowNo;
  final String deviceEui;
  final DateTime? collectedAt;
  final double? rtkLatitude;
  final double? rtkLongitude;
  final double? deviceLatitude;
  final double? deviceLongitude;
  final String matchMode;
  final String? error;
  final DateTime? matchedRecordedAt;
  final int? timeDiffSec;

  factory TrajectoryParseRow.fromJson(Map<String, dynamic> json) =>
      TrajectoryParseRow(
        rowNo: json['rowNo'] as int? ?? 0,
        deviceEui: json['deviceEui'] as String? ?? '',
        collectedAt: json['collectedAt'] != null
            ? DateTime.parse(json['collectedAt'] as String)
            : null,
        rtkLatitude: (json['rtkLatitude'] as num?)?.toDouble(),
        rtkLongitude: (json['rtkLongitude'] as num?)?.toDouble(),
        deviceLatitude: (json['deviceLatitude'] as num?)?.toDouble(),
        deviceLongitude: (json['deviceLongitude'] as num?)?.toDouble(),
        matchMode: json['matchMode'] as String? ?? 'INVALID',
        error: json['error'] as String?,
        matchedRecordedAt: json['matchedRecordedAt'] != null
            ? DateTime.parse(json['matchedRecordedAt'] as String)
            : null,
        timeDiffSec: json['timeDiffSec'] as int?,
      );
}

/// Server-side parse + pairing preview of a trajectory file.
@immutable
class TrajectoryParseResult {
  const TrajectoryParseResult({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    required this.deviceCount,
    required this.filePaired,
    required this.logPaired,
    required this.unpaired,
   required this.rows,
    required this.autoRegisteredEuis,
 });

  final int totalRows;
  final int validRows;
  final int invalidRows;
  final int deviceCount;
  final int filePaired;
  final int logPaired;
  final int unpaired;
 final List<TrajectoryParseRow> rows;
  final List<String> autoRegisteredEuis;

  factory TrajectoryParseResult.fromJson(Map<String, dynamic> json) =>
      TrajectoryParseResult(
        totalRows: json['totalRows'] as int? ?? 0,
        validRows: json['validRows'] as int? ?? 0,
        invalidRows: json['invalidRows'] as int? ?? 0,
        deviceCount: json['deviceCount'] as int? ?? 0,
        filePaired: json['filePaired'] as int? ?? 0,
        logPaired: json['logPaired'] as int? ?? 0,
        unpaired: json['unpaired'] as int? ?? 0,
       autoRegisteredEuis: (json['autoRegisteredEuis'] as List? ?? [])
           .whereType<String>()
           .toList(),
       rows: (json['rows'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TrajectoryParseRow.fromJson)
            .toList(),
      );
}

/// Per-device outcome of a trajectory import.
@immutable
class TrajectoryDeviceResult {
  const TrajectoryDeviceResult({
    required this.deviceEui,
    this.testId,
    required this.status, // CREATED / SKIPPED_DUPLICATE
    required this.totalPoints,
    required this.filePaired,
    required this.logPaired,
    required this.unpaired,
  });

  final String deviceEui;
  final int? testId;
  final String status;
  final int totalPoints;
  final int filePaired;
  final int logPaired;
  final int unpaired;

  factory TrajectoryDeviceResult.fromJson(Map<String, dynamic> json) =>
      TrajectoryDeviceResult(
        deviceEui: json['deviceEui'] as String? ?? '',
        testId: json['testId'] as int?,
        status: json['status'] as String? ?? '',
        totalPoints: json['totalPoints'] as int? ?? 0,
        filePaired: json['filePaired'] as int? ?? 0,
        logPaired: json['logPaired'] as int? ?? 0,
        unpaired: json['unpaired'] as int? ?? 0,
      );
}

/// Result of a trajectory import (one TRAJECTORY check per device).
@immutable
class TrajectoryImportResult {
  const TrajectoryImportResult({
    required this.createdCount,
    required this.skippedCount,
   required this.devices,
    required this.autoRegisteredCount,
 });

 final int createdCount;
 final int skippedCount;
  final int autoRegisteredCount;
 final List<TrajectoryDeviceResult> devices;

  factory TrajectoryImportResult.fromJson(Map<String, dynamic> json) =>
      TrajectoryImportResult(
        createdCount: json['createdCount'] as int? ?? 0,
        skippedCount: json['skippedCount'] as int? ?? 0,
        autoRegisteredCount: json['autoRegisteredCount'] as int? ?? 0,
       devices: (json['devices'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TrajectoryDeviceResult.fromJson)
            .toList(),
      );
}

/// One paired track point of a trajectory report.
@immutable
class TrajectoryTrackPoint {
  const TrajectoryTrackPoint({
    required this.sequenceNo,
    required this.collectedAt,
    required this.rtkLatitude,
    required this.rtkLongitude,
    this.deviceLatitude,
    this.deviceLongitude,
    this.error,
    required this.matchSource, // FILE / GPS_LOG / UNPAIRED
    this.timeDiffSec,
  });

  final int sequenceNo;
  final DateTime collectedAt;
  final double rtkLatitude;
  final double rtkLongitude;
  final double? deviceLatitude;
  final double? deviceLongitude;
  final double? error;
  final String matchSource;
  final int? timeDiffSec;

  bool get paired => matchSource != 'UNPAIRED';

  factory TrajectoryTrackPoint.fromJson(Map<String, dynamic> json) =>
      TrajectoryTrackPoint(
        sequenceNo: json['sequenceNo'] as int? ?? 0,
        collectedAt: DateTime.parse(json['collectedAt'] as String),
        rtkLatitude: (json['rtkLatitude'] as num).toDouble(),
        rtkLongitude: (json['rtkLongitude'] as num).toDouble(),
        deviceLatitude: (json['deviceLatitude'] as num?)?.toDouble(),
        deviceLongitude: (json['deviceLongitude'] as num?)?.toDouble(),
        error: (json['error'] as num?)?.toDouble(),
        matchSource: json['matchSource'] as String? ?? 'UNPAIRED',
        timeDiffSec: json['timeDiffSec'] as int?,
      );
}

/// Same-device static-vs-trajectory comparison.
@immutable
class TrajectoryStaticComparison {
  const TrajectoryStaticComparison({
    this.staticTestId,
    required this.staticP95,
    required this.staticGrade,
    required this.deltaP95,
  });

  final int? staticTestId;
  final double staticP95;
  final QualityGrade staticGrade;
  final double deltaP95;

  factory TrajectoryStaticComparison.fromJson(Map<String, dynamic> json) =>
      TrajectoryStaticComparison(
        staticTestId: json['staticTestId'] as int?,
        staticP95: (json['staticP95'] as num?)?.toDouble() ?? 0,
        staticGrade: trajectoryGradeFrom(json['staticGrade'] as String?),
        deltaP95: (json['deltaP95'] as num?)?.toDouble() ?? 0,
      );
}

/// TRAJECTORY quality report assembled from the pairing snapshot.
@immutable
class TrajectoryQualityReport {
  const TrajectoryQualityReport({
    required this.testId,
    required this.deviceCode,
    required this.startedAt,
    this.endedAt,
    required this.toleranceSec,
    required this.grade,
    required this.totalPoints,
    required this.filePaired,
    required this.logPaired,
    required this.unpaired,
    required this.pairRate,
    required this.meanError,
    required this.p50,
    required this.p95,
    required this.maxError,
    required this.points,
    this.staticComparison,
  });

  final int testId;
  final String deviceCode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int toleranceSec;
  final QualityGrade grade;
  final int totalPoints;
  final int filePaired;
  final int logPaired;
  final int unpaired;
  final double pairRate;
  final double meanError;
  final double p50;
  final double p95;
  final double maxError;
  final List<TrajectoryTrackPoint> points;
  final TrajectoryStaticComparison? staticComparison;

  factory TrajectoryQualityReport.fromJson(Map<String, dynamic> json) =>
      TrajectoryQualityReport(
        testId: json['testId'] as int? ?? 0,
        deviceCode: json['deviceCode'] as String? ?? '',
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        toleranceSec: json['toleranceSec'] as int? ?? 60,
        grade: trajectoryGradeFrom(json['grade'] as String?),
        totalPoints: json['totalPoints'] as int? ?? 0,
        filePaired: json['filePaired'] as int? ?? 0,
        logPaired: json['logPaired'] as int? ?? 0,
        unpaired: json['unpaired'] as int? ?? 0,
        pairRate: (json['pairRate'] as num?)?.toDouble() ?? 0,
        meanError: (json['meanError'] as num?)?.toDouble() ?? 0,
        p50: (json['p50'] as num?)?.toDouble() ?? 0,
        p95: (json['p95'] as num?)?.toDouble() ?? 0,
        maxError: (json['maxError'] as num?)?.toDouble() ?? 0,
        points: (json['points'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TrajectoryTrackPoint.fromJson)
            .toList(),
        staticComparison: json['staticComparison'] != null
            ? TrajectoryStaticComparison.fromJson(
                json['staticComparison'] as Map<String, dynamic>)
            : null,
      );
}

/// One device row of the cross-device trajectory comparison.
@immutable
class TrajectoryComparisonRow {
  const TrajectoryComparisonRow({
    required this.testId,
    required this.deviceId,
    required this.deviceCode,
    required this.totalPoints,
    required this.paired,
    required this.pairRate,
    required this.meanError,
    required this.p50,
    required this.p95,
    required this.grade,
    this.startedAt,
    this.endedAt,
  });

  final int testId;
  final int deviceId;
  final String deviceCode;
  final int totalPoints;
  final int paired;
  final double pairRate;
  final double meanError;
  final double p50;
  final double p95;
  final QualityGrade grade;
  final DateTime? startedAt;
  final DateTime? endedAt;

  factory TrajectoryComparisonRow.fromJson(Map<String, dynamic> json) =>
      TrajectoryComparisonRow(
        testId: json['testId'] as int? ?? 0,
        deviceId: json['deviceId'] as int? ?? 0,
        deviceCode: json['deviceCode'] as String? ?? '',
        totalPoints: json['totalPoints'] as int? ?? 0,
        paired: json['paired'] as int? ?? 0,
        pairRate: (json['pairRate'] as num?)?.toDouble() ?? 0,
        meanError: (json['meanError'] as num?)?.toDouble() ?? 0,
        p50: (json['p50'] as num?)?.toDouble() ?? 0,
        p95: (json['p95'] as num?)?.toDouble() ?? 0,
        grade: trajectoryGradeFrom(json['grade'] as String?),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
      );
}
