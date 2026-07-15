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
    required this.rtkPointId,
    required this.deviceId,
    required this.deviceCode,
    required this.startedAt,
    this.endedAt,
    required this.status,
  });

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
          latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
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
