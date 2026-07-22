import 'package:flutter/foundation.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/web_file_utils.dart';

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
        sessionId: (json['testId'] ?? json['sessionId']) as int,
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

  // ── Reports & analysis ──────────────────────────────────────────

  Future<GpsQualityReport> fetchReport(
    int sessionId, {
    bool excludeSuspect = false,
  }) async {
   final data = await ApiClient.instance.get(
      '$_base/tests/$sessionId/report?excludeSuspect=$excludeSuspect',
   );
   return GpsQualityReport.fromJson(data);
 }

 Future<ComparisonResult> fetchComparison({int? rtkPointId}) async {
   final qs = rtkPointId != null ? '?rtkPointId=$rtkPointId' : '';
   final data = await ApiClient.instance.get('$_base/comparison$qs');
   return ComparisonResult.fromJson(data);
 }

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

  Future<DynamicQualityReport> fetchDynamicReport(
    int sessionId, {
    double threshold = 5.0,
  }) async {
   final data = await ApiClient.instance
        .get('$_base/tests/$sessionId/dynamic-report?threshold=$threshold');
    return DynamicQualityReport.fromJson(data);
  }

  // ── NIX-21: Batch import ──────────────────────────────────────────

  /// Parse an Excel file for batch import preview (parse-only, no persistence).
  Future<BatchParseResult> parseBatch(
      List<int> fileBytes, String fileName) async {
    final data = await ApiClient.instance
        .uploadFile('$_base/batch/parse', fileBytes, fileName);
    return BatchParseResult.fromJson(data);
  }

  /// Upload an Excel file for batch GPS quality check import.
  /// [excludeRows] skips the given parse row indexes (1-based rowIndex).
  Future<BatchImportResult> batchImport(
      List<int> fileBytes, String fileName,
      {List<int>? excludeRows}) async {
    final data = await ApiClient.instance.uploadFile(
      '$_base/batch/import',
      fileBytes,
      fileName,
      fields: (excludeRows != null && excludeRows.isNotEmpty)
          ? {'excludeRows': excludeRows.join(',')}
          : null,
    );
    return BatchImportResult.fromJson(data);
  }

  /// Download the batch import Excel template.
  /// Uses getBytes for binary download, then triggers browser download on web.
  Future<void> downloadBatchTemplate() async {
    final bytes = await ApiClient.instance.getBytes('$_base/batch/template');
    await downloadBytes('gps-quality-import-template.xlsx', bytes);
  }

  /// Retry device registration for all pending checks (or specific ones).
  Future<List<RowResult>> retryRegistration({List<int>? checkIds}) async {
    final data = await ApiClient.instance.post(
      '$_base/batch/retry-registration',
      body: checkIds != null ? {'checkIds': checkIds} : null,
    );
    final rawItems = (data['value'] ?? data['items'] ?? data) as List;
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(RowResult.fromJson)
        .toList();
  }

  /// Retry a single failed batch import row.
  Future<RowResult> retryRow({
    required String eui,
    required String checkType,
    required DateTime startedAt,
    DateTime? endedAt,
  }) async {
    final data = await ApiClient.instance.post('$_base/batch/retry-row', body: {
      'eui': eui,
      'testType': checkType,
      'startedAt': startedAt.toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt.toIso8601String(),
    });
    return RowResult.fromJson(data);
  }

  /// Delete all tests belonging to a batch import.
  Future<void> deleteBatch(int batchId) async {
    await ApiClient.instance.delete('$_base/batch/$batchId');
  }

  // ── NIX-21: Check-centric API (replaces session-based) ─────────────

  /// Create a single quality check (EUI-driven).
  Future<QualityCheck> createCheck({
    required String eui,
    String? deviceCode,
    required String checkType,
    int? rtkPointId,
    int? routeId,
    required DateTime startedAt,
    DateTime? endedAt,
  }) async {
    final data = await ApiClient.instance.post('$_base/checks', body: {
      'eui': eui,
      if (deviceCode != null) 'deviceCode': deviceCode,
      'testType': checkType,
      if (rtkPointId != null) 'rtkPointId': rtkPointId,
      if (routeId != null) 'routeId': routeId,
      'startedAt': startedAt.toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt.toIso8601String(),
    });
    return QualityCheck.fromJson(data);
  }

  /// Fetch paginated quality checks.
  Future<QualityCheckListResult> fetchChecks({
    String? status,
    String? eui,
    int? deviceId,
    int page = 0,
    int size = 200,
  }) async {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (eui != null) params.add('eui=${Uri.encodeQueryComponent(eui)}');
    if (deviceId != null) params.add('deviceId=$deviceId');
    params.add('page=$page');
    params.add('size=$size');
    final data =
        await ApiClient.instance.get('$_base/checks?${params.join('&')}');
    return QualityCheckListResult.fromJson(data);
  }

  /// Delete all quality checks of a device (the device itself is kept).
  /// Returns the number of deleted check records.
  Future<int> deleteChecksByDevice(int deviceId) async {
    final data =
        await ApiClient.instance.deleteJson('$_base/checks/by-device/$deviceId');
    return (data['deleted'] as num?)?.toInt() ?? 0;
  }

  /// Delete a single quality check by id.
  Future<void> deleteCheck(int id) async {
    await ApiClient.instance.delete('$_base/tests/$id');
  }

  /// Fetch the dynamic quality comparison across devices for a route.
  Future<DynamicComparisonResult> fetchDynamicComparison(int routeId) async {
    final data = await ApiClient.instance
        .get('$_base/comparison/dynamic?routeId=$routeId');
    return DynamicComparisonResult.fromJson(data);
  }

  // ── NIX-22: RTK trajectory import ──────────────────────────────

  /// Parse + pairing preview of a trajectory file (no persistence).
  Future<TrajectoryParseResult> parseTrajectory(
      List<int> fileBytes, String fileName, int toleranceSec) async {
    final data = await ApiClient.instance.uploadFile(
      '$_base/trajectory/parse',
      fileBytes,
      fileName,
      fields: {'toleranceSec': '$toleranceSec'},
    );
    return TrajectoryParseResult.fromJson(data);
  }

  /// Import a trajectory file: one TRAJECTORY check per device.
  Future<TrajectoryImportResult> importTrajectory(
      List<int> fileBytes, String fileName, int toleranceSec) async {
    final data = await ApiClient.instance.uploadFile(
      '$_base/trajectory/import',
      fileBytes,
      fileName,
      fields: {'toleranceSec': '$toleranceSec'},
    );
    return TrajectoryImportResult.fromJson(data);
  }

  /// Download the trajectory import CSV template.
  Future<void> downloadTrajectoryTemplate() async {
   final bytes =
       await ApiClient.instance.getBytes('$_base/trajectory/template');
   await downloadBytes('trajectory-import-template.csv', bytes);
 }
  /// Manually register a device for trajectory import.
  /// Returns (deviceId, deviceCode, platformBound).
  Future<({int deviceId, String deviceCode, bool platformBound})>
      registerTrajectoryDevice(String eui, String? deviceCode) async {
    final body = <String, dynamic>{'eui': eui};
    if (deviceCode != null && deviceCode.isNotEmpty) body['deviceCode'] = deviceCode;
    final data = await ApiClient.instance.post('$_base/trajectory/register-device', body: body);
    return (
      deviceId: data['id'] as int,
      deviceCode: data['deviceCode'] as String,
      platformBound: data['platformBound'] as bool? ?? false,
    );
  }

  /// Fetch the TRAJECTORY quality report of one check.
  Future<TrajectoryQualityReport> fetchTrajectoryReport(int testId) async {
    final data =
        await ApiClient.instance.get('$_base/tests/$testId/trajectory-report');
    return TrajectoryQualityReport.fromJson(data);
  }

  /// Fetch the cross-device trajectory comparison.
  Future<List<TrajectoryComparisonRow>> fetchTrajectoryComparison() async {
    final data = await ApiClient.instance.get('$_base/comparison/trajectory');
    final items = (data['devices'] as List? ?? []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(TrajectoryComparisonRow.fromJson)
        .toList();
  }
}
