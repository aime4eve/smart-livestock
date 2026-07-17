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

/// A single row in a batch-create request.
@immutable
class BatchSessionRequest {
  const BatchSessionRequest({
    this.testType = TestType.static_,
    this.routeId,
    required this.rtkPointId,
    required this.deviceId,
    required this.startedAt,
    this.endedAt,
  });
  final TestType testType;
  final int? routeId;
  final int rtkPointId;
  final int deviceId;
  final DateTime startedAt;
  final DateTime? endedAt;
}

/// Per-row failure info from a batch create.
@immutable
class BatchFailure {
  const BatchFailure({required this.rowIndex, required this.error});
  final int rowIndex;
  final String error;
}

/// Result of a batch create operation.
@immutable
class BatchCreateResult {
  const BatchCreateResult({required this.succeeded, required this.failed});
  final List<int> succeeded;
  final List<BatchFailure> failed;
}

/// A single device comparison entry (one device tested at one RTK point).
@immutable
class DeviceComparison {
  const DeviceComparison({
    required this.sessionId,
    required this.deviceCode,
    required this.stats,
    required this.grade,
    this.locationName = '',
    this.pointLabel = '',
  });

  final int sessionId;
  final String deviceCode;
  final GpsQualityStats stats;
  final QualityGrade grade;
  final String locationName;
  final String pointLabel;

  factory DeviceComparison.fromJson(Map<String, dynamic> json) =>
      DeviceComparison(
        sessionId: json['sessionId'] as int,
        deviceCode: json['deviceCode'] as String? ?? '',
        locationName: json['locationName'] as String? ?? '',
        pointLabel: json['pointLabel'] as String? ?? '',
        // Backend ComparisonDto.DeviceSummary has flat fields (not nested stats)
        stats: GpsQualityStats(
          totalPoints: json['totalPoints'] as int? ??
              json['effectivePoints'] as int? ?? 0,
          suspectPoints: 0,
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
        ),
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
        // Backend ComparisonDto has flat fields: rtkPointId, locationName, label
        rtkPoint: RtkPoint(
          id: json['rtkPointId'] as int? ?? 0,
          locationName: json['locationName'] as String? ?? '',
          pointLabel: json['label'] as String? ?? '',
          latitude: 0,
          longitude: 0,
        ),
        devices: (json['devices'] as List)
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
    final items = (data['value'] ?? data['items']) as List;
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
    final items = (data['value'] ?? data['items']) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(DeviceBrief.fromJson)
        .toList();
  }

  // ── Calibration sessions ────────────────────────────────────────

 Future<SessionListResult> fetchSessions({
   int? rtkPointId,
   int? deviceId,
   CalibrationStatus? status,
   int page = 0,
   int size = 200,
 }) async {
   final params = <String>[];
   if (rtkPointId != null) params.add('rtkPointId=$rtkPointId');
   if (deviceId != null) params.add('deviceId=$deviceId');
   if (status != null) params.add('status=${_statusParam(status)}');
    params.add('page=$page');
    params.add('size=$size');
    final data = await ApiClient.instance
        .get('$_base/sessions?${params.join('&')}');
    // Sessions endpoint returns Spring Data Page: {content: [...], totalElements: N}
    final rawItems = (data['content'] ?? data['value'] ?? data['items']) as List;
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(CalibrationSession.fromJson)
        .toList();
    return SessionListResult(
      items: items,
      total: data['totalElements'] as int? ?? data['total'] as int? ?? items.length,
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

  /// Batch-create sessions by calling the single-session endpoint
  /// sequentially. Returns per-row success/failure so the caller can
  /// highlight which rows failed.
  Future<BatchCreateResult> createSessionBatch(
      List<BatchSessionRequest> rows) async {
    final succeeded = <int>[];
    final failed = <BatchFailure>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      try {
        await ApiClient.instance.post('$_base/sessions', body: {
          'rtkPointId': r.rtkPointId,
          'deviceId': r.deviceId,
          'startedAt': r.startedAt.toUtc().toIso8601String(),
          if (r.endedAt != null) 'endedAt': r.endedAt!.toUtc().toIso8601String(),
        });
        succeeded.add(i);
      } catch (e) {
        failed.add(BatchFailure(rowIndex: i, error: e.toString()));
      }
    }
    return BatchCreateResult(succeeded: succeeded, failed: failed);
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
    return ((data['points'] ?? (data['value'] is List ? data['value'] : (data['value'] is Map ? data['value']['points'] : null))) as List)
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

  // ── Dynamic test routes ─────────────────────────────────────────

Future<List<DynamicRoute>> fetchDynamicRoutes() async {
  final data = await ApiClient.instance.get('$_base/dynamic-routes');
  final items = (data is List)
      ? data as List
      : (data['value'] ?? data['items'] ?? []) as List;
  return items
      .whereType<Map<String, dynamic>>()
      .map(DynamicRoute.fromJson)
      .toList();
}

  Future<DynamicRoute> createDynamicRoute({
    required String name,
    String? description,
  }) async {
    final data = await ApiClient.instance.post('$_base/dynamic-routes', body: {
      'name': name,
      if (description != null) 'description': description,
    });
    return DynamicRoute.fromJson(data);
  }

  Future<void> deleteDynamicRoute(int id) async {
    await ApiClient.instance.delete('$_base/dynamic-routes/$id');
  }

  Future<List<DynamicRoutePoint>> fetchRoutePoints(int routeId) async {
    final data =
        await ApiClient.instance.get('$_base/dynamic-routes/$routeId/points');
    final items = (data is List)
        ? data as List
        : (data['value'] ?? data['items'] ?? []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(DynamicRoutePoint.fromJson)
        .toList();
  }

  Future<void> replaceRoutePoints(
    int routeId,
    List<({int rtkPointId, int sequenceNo})> points,
  ) async {
    await ApiClient.instance.put(
      '$_base/dynamic-routes/$routeId/points',
      body: points
          .map((p) => {'rtkPointId': p.rtkPointId, 'sequenceNo': p.sequenceNo})
          .toList(),
    );
  }

  // ── Dynamic test sessions ───────────────────────────────────────

  Future<CalibrationSession> createDynamicSession({
    required int deviceId,
    required int routeId,
    required DateTime startedAt,
    DateTime? endedAt,
  }) async {
    final data =
        await ApiClient.instance.post('$_base/sessions/dynamic', body: {
      'deviceId': deviceId,
      'routeId': routeId,
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt.toUtc().toIso8601String(),
    });
    return CalibrationSession.fromJson(data);
  }

  Future<DynamicQualityReport> fetchDynamicReport(
    int sessionId, {
    double threshold = 5.0,
  }) async {
    final data = await ApiClient.instance
        .get('$_base/sessions/$sessionId/dynamic-report?threshold=$threshold');
    return DynamicQualityReport.fromJson(data);
  }
}
