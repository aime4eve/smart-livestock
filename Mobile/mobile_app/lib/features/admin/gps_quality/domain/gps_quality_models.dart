import 'package:flutter/foundation.dart';

/// Calibration session status.
enum CalibrationStatus { inProgress, completed, canceled }

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

/// Calibration session — a static test window linking a device to an RTK point.
@immutable
class CalibrationSession {
  const CalibrationSession({
    required this.id,
    this.testType = TestType.static_,
    this.routeId,
    required this.rtkPointId,
    required this.deviceId,
    required this.deviceCode,
    required this.startedAt,
    this.endedAt,
    required this.status,
  });

  final TestType testType;
  final int? routeId;
  final int id;
  final int rtkPointId;
  final int deviceId;
  final String deviceCode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final CalibrationStatus status;

  factory CalibrationSession.fromJson(Map<String, dynamic> json) =>
      CalibrationSession(
        id: json['id'] as int,
        testType: TestType.fromString(json['testType'] as String? ?? 'STATIC'),
        routeId: json['routeId'] as int?,
        rtkPointId: json['rtkPointId'] as int,
        deviceId: json['deviceId'] as int,
        deviceCode: json['deviceCode'] as String? ?? '',
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        status: _parseStatus(json['status'] as String),
      );

  static CalibrationStatus _parseStatus(String s) => switch (s) {
        'IN_PROGRESS' => CalibrationStatus.inProgress,
        'COMPLETED' => CalibrationStatus.completed,
        'CANCELED' => CalibrationStatus.canceled,
        _ => CalibrationStatus.inProgress,
      };
}

/// Test type: STATIC (single RTK point) or DYNAMIC (route-driven).
enum TestType {
  static_,
  dynamic_;

  String get label => switch (this) {
        TestType.static_ => 'STATIC',
        TestType.dynamic_ => 'DYNAMIC',
      };

  static TestType fromString(String s) => switch (s.toUpperCase()) {
        'DYNAMIC' => TestType.dynamic_,
        _ => TestType.static_,
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
        sessionId: json['sessionId'] as int,
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
