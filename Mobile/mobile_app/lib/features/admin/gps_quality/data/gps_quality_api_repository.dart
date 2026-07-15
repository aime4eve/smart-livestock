import 'package:flutter/foundation.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';

/// Paginated calibration session list result.
@immutable
class SessionListResult {
  const SessionListResult({required this.items, this.total = 0, this.page = 1, this.size = 200});
  final List<CalibrationSession> items;
  final int total;
  final int page;
  final int size;
}

/// A single device comparison entry (one device tested at one RTK point).
@immutable
class DeviceComparison {
  const DeviceComparison({
    required this.sessionId,
    required this.deviceCode,
    required this.stats,
    required this.grade,
  });

  final int sessionId;
  final String deviceCode;
  final GpsQualityStats stats;
  final QualityGrade grade;

  factory DeviceComparison.fromJson(Map<String, dynamic> json) =>
      DeviceComparison(
        sessionId: json['sessionId'] as int,
        deviceCode: json['deviceCode'] as String? ?? '',
        stats: GpsQualityStats.fromJson(
            json['stats'] as Map<String, dynamic>? ?? const {}),
        grade: _parseGrade(json['grade'] as String? ?? 'UNAVAILABLE'),
      );

  static QualityGrade _parseGrade(String s) => switch (s) {
        'EXCELLENT' => QualityGrade.excellent,
        'USABLE' => QualityGrade.usable,
        'MARGINAL' => QualityGrade.marginal,
        _ => QualityGrade.unavailable,
      };
}

/// Multi-device comparison result for a single RTK point.
@immutable
class ComparisonResult {
  const ComparisonResult({required this.rtkPoint, required this.devices});

  final RtkPoint rtkPoint;
  final List<DeviceComparison> devices;

  factory ComparisonResult.fromJson(Map<String, dynamic> json) =>
      ComparisonResult(
        rtkPoint:
            RtkPoint.fromJson(json['rtkPoint'] as Map<String, dynamic>),
        devices: (json['devices'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DeviceComparison.fromJson)
            .toList(),
      );
}

/// A single GPS trajectory point.
@immutable
class TrajectoryPoint {
  const TrajectoryPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  factory TrajectoryPoint.fromJson(Map<String, dynamic> json) =>
      TrajectoryPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );
}

/// Platform-level (non farm-scoped) repository for the GPS quality admin API.
///
/// Base path: /api/v1/admin/gps-quality
class GpsQualityApiRepository {
  const GpsQualityApiRepository();

  static const _base = '/admin/gps-quality';

  // ── RTK points ──────────────────────────────────────────────────

  Future<List<RtkPoint>> fetchRtkPoints({String? locationName}) async {
    final qs = (locationName != null && locationName.isNotEmpty)
        ? '?locationName=${Uri.encodeQueryComponent(locationName)}'
        : '';
    final data = await ApiClient.instance.get('$_base/rtk-points$qs');
    final items = (data['value'] ?? data['items']) as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(RtkPoint.fromJson)
        .toList();
  }

  Future<RtkPoint> createRtkPoint({
    required String locationName,
    required String pointLabel,
    required double latitude,
    required double longitude,
  }) async {
    final data = await ApiClient.instance.post('$_base/rtk-points', body: {
      'locationName': locationName,
      'pointLabel': pointLabel,
      'latitude': latitude,
      'longitude': longitude,
    });
    return RtkPoint.fromJson(data);
  }

  Future<void> updateRtkPoint(
    int id, {
    required String locationName,
    required String pointLabel,
    required double latitude,
    required double longitude,
  }) async {
    await ApiClient.instance.put('$_base/rtk-points/$id', body: {
      'locationName': locationName,
      'pointLabel': pointLabel,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<void> deleteRtkPoint(int id) async {
    await ApiClient.instance.delete('$_base/rtk-points/$id');
  }

  // ── Devices ─────────────────────────────────────────────────────

  Future<List<DeviceBrief>> fetchDevices() async {
    final data = await ApiClient.instance.get('$_base/devices');
    final items = (data['value'] ?? data['items']) as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(DeviceBrief.fromJson)
        .toList();
  }

  // ── Calibration sessions ────────────────────────────────────────

  Future<SessionListResult> fetchSessions({
    int? rtkPointId,
    CalibrationStatus? status,
    int page = 1,
    int size = 200,
  }) async {
    final params = <String>[];
    if (rtkPointId != null) params.add('rtkPointId=$rtkPointId');
    if (status != null) params.add('status=${_statusParam(status)}');
    params.add('page=$page');
    params.add('size=$size');
    final data = await ApiClient.instance
        .get('$_base/sessions?${params.join('&')}');
    final items = ((data['value'] ?? data['items']) as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CalibrationSession.fromJson)
        .toList();
    return SessionListResult(
      items: items,
      total: data['total'] as int? ?? items.length,
      page: page,
      size: size,
    );
  }

  Future<CalibrationSession> createSession({
    required int rtkPointId,
    required int deviceId,
    required DateTime startedAt,
    DateTime? endedAt,
  }) async {
    final data = await ApiClient.instance.post('$_base/sessions', body: {
      'rtkPointId': rtkPointId,
      'deviceId': deviceId,
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt.toUtc().toIso8601String(),
    });
    return CalibrationSession.fromJson(data);
  }

  Future<void> endSession(int id) async {
    await ApiClient.instance.patch('$_base/sessions/$id/end');
  }

  Future<void> deleteSession(int id) async {
    await ApiClient.instance.delete('$_base/sessions/$id');
  }

  // ── Reports & analysis ──────────────────────────────────────────

  Future<GpsQualityReport> fetchReport(
    int sessionId, {
    bool excludeSuspect = false,
  }) async {
    final data = await ApiClient.instance.get(
      '$_base/sessions/$sessionId/report?excludeSuspect=$excludeSuspect',
    );
    return GpsQualityReport.fromJson(data);
  }

  Future<List<TrajectoryPoint>> fetchTrajectory(int sessionId) async {
    final data = await ApiClient.instance
        .get('$_base/sessions/$sessionId/trajectory');
    return ((data['points'] ?? (data['value'] is List ? data['value'] : (data['value'] is Map ? data['value']['points'] : null))) as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TrajectoryPoint.fromJson)
        .toList();
  }

  Future<ComparisonResult> fetchComparison({int? rtkPointId}) async {
    final qs = rtkPointId != null ? '?rtkPointId=$rtkPointId' : '';
    final data = await ApiClient.instance.get('$_base/comparison$qs');
    return ComparisonResult.fromJson(data);
  }

  String _statusParam(CalibrationStatus s) => switch (s) {
        CalibrationStatus.inProgress => 'IN_PROGRESS',
        CalibrationStatus.completed => 'COMPLETED',
        CalibrationStatus.canceled => 'CANCELED',
      };
}
