import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';

final gpsQualityApiRepositoryProvider = Provider<GpsQualityApiRepository>(
  (ref) => const GpsQualityApiRepository(),
);

// ── RTK points ────────────────────────────────────────────────────

class RtkPointsController extends AsyncNotifier<List<RtkPoint>> {
  @override
  Future<List<RtkPoint>> build() =>
      ref.read(gpsQualityApiRepositoryProvider).fetchRtkPoints();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gpsQualityApiRepositoryProvider).fetchRtkPoints(),
    );
  }

  Future<bool> createPoint({
    required String locationName,
    required String pointLabel,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await ref.read(gpsQualityApiRepositoryProvider).createRtkPoint(
            locationName: locationName,
            pointLabel: pointLabel,
            latitude: latitude,
            longitude: longitude,
          );
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePoint(int id) async {
    try {
      await ref.read(gpsQualityApiRepositoryProvider).deleteRtkPoint(id);
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final rtkPointsProvider =
    AsyncNotifierProvider<RtkPointsController, List<RtkPoint>>(
  RtkPointsController.new,
);

// ── Devices ───────────────────────────────────────────────────────

class GpsDevicesController extends AsyncNotifier<List<DeviceBrief>> {
  @override
  Future<List<DeviceBrief>> build() =>
      ref.read(gpsQualityApiRepositoryProvider).fetchDevices();
}

final gpsDevicesProvider =
    AsyncNotifierProvider<GpsDevicesController, List<DeviceBrief>>(
  GpsDevicesController.new,
);

// ── Quality report (family by test + excludeSuspect) ─────────────

/// Query key for fetching a quality report.
typedef GpsReportQuery = ({int sessionId, bool excludeSuspect});

final qualityReportProvider =
    FutureProvider.family<GpsQualityReport, GpsReportQuery>(
  (ref, query) => ref
      .read(gpsQualityApiRepositoryProvider)
      .fetchReport(query.sessionId, excludeSuspect: query.excludeSuspect),
);

// ── Comparison (family by rtkPointId) ─────────────────────────────

final comparisonProvider = FutureProvider.family<ComparisonResult, int>(
  (ref, rtkPointId) => ref
      .read(gpsQualityApiRepositoryProvider)
      .fetchComparison(rtkPointId: rtkPointId),
);

// ── Dynamic comparison (family by routeId) ────────────────────────

final dynamicComparisonProvider =
    FutureProvider.family<DynamicComparisonResult, int>(
  (ref, routeId) => ref
      .read(gpsQualityApiRepositoryProvider)
      .fetchDynamicComparison(routeId),
);

// ── Dynamic test routes ───────────────────────────────────────────

class DynamicRoutesController extends AsyncNotifier<List<DynamicRoute>> {
  @override
  Future<List<DynamicRoute>> build() =>
      ref.read(gpsQualityApiRepositoryProvider).fetchDynamicRoutes();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gpsQualityApiRepositoryProvider).fetchDynamicRoutes(),
    );
  }
}

final dynamicRoutesProvider =
    AsyncNotifierProvider<DynamicRoutesController, List<DynamicRoute>>(
  DynamicRoutesController.new,
);

// ── Route points (family by routeId) ──────────────────────────────

final routePointsProvider =
    FutureProvider.family<List<DynamicRoutePoint>, int>(
  (ref, routeId) =>
      ref.read(gpsQualityApiRepositoryProvider).fetchRoutePoints(routeId),
);

// ── Dynamic quality report (family by sessionId) ──────────────────

/// Query key for fetching a dynamic quality report.
typedef DynamicReportQuery = ({int sessionId, double threshold});

final dynamicReportProvider =
    FutureProvider.family<DynamicQualityReport, DynamicReportQuery>(
  (ref, query) => ref
      .read(gpsQualityApiRepositoryProvider)
      .fetchDynamicReport(query.sessionId, threshold: query.threshold),
);

// ── Sessions (data window) ────────────────────────────────────────
// ── NIX-21: Checks (top-level, replaces session-based provider) ──
// ── NIX-21: Checks (top-level, check-centric) ────────────────────

class ChecksController extends AsyncNotifier<QualityCheckListResult> {
  static const _pageSize = 200;
  String? _status;
  String? _eui;
  int? _deviceId;
  bool _loadingMore = false;

  @override
  Future<QualityCheckListResult> build() async {
    _status = null;
    _eui = null;
    _deviceId = null;
    _loadingMore = false;
    return ref.read(gpsQualityApiRepositoryProvider)
        .fetchChecks(page: 0, size: _pageSize);
  }

  Future<void> refresh() => fetchFiltered(
        status: _status,
        eui: _eui,
        deviceId: _deviceId,
      );

  Future<void> fetchFiltered({
    String? status,
    String? eui,
    int? deviceId,
  }) async {
    _status = status;
    _eui = eui;
    _deviceId = deviceId;
    _loadingMore = false;
    state = const AsyncLoading();
    final keyword = eui?.trim();
    state = await AsyncValue.guard(() => ref
        .read(gpsQualityApiRepositoryProvider)
        .fetchChecks(
          status: status,
          eui: keyword == null || keyword.isEmpty ? null : keyword,
          deviceId: deviceId,
          page: 0,
          size: _pageSize,
        ));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (_loadingMore || current == null) return;
    if ((current.page + 1) * current.pageSize >= current.total) return;

    _loadingMore = true;
    try {
      final nextPage = current.page + 1;
      final result = await ref.read(gpsQualityApiRepositoryProvider).fetchChecks(
            status: _status,
            eui: _eui?.trim(),
            deviceId: _deviceId,
            page: nextPage,
            size: current.pageSize,
          );
      state = AsyncData(QualityCheckListResult(
        items: [...current.items, ...result.items],
        page: result.page,
        pageSize: result.pageSize,
        total: result.total,
      ));
    } finally {
      _loadingMore = false;
    }
  }
}

final checksProvider =
    AsyncNotifierProvider<ChecksController, QualityCheckListResult>(
  ChecksController.new,
);

// ── NIX-22: Trajectory report + comparison ───────────────────────

class TrajectoryReportController extends AsyncNotifier<TrajectoryQualityReport> {
  TrajectoryReportController(this.testId);
  final int testId;

  @override
  Future<TrajectoryQualityReport> build() => ref
      .read(gpsQualityApiRepositoryProvider)
      .fetchTrajectoryReport(testId);

  /// Re-pair with a new tolerance, persist on server, refresh local state.
  Future<void> rePair(int toleranceSec) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref
        .read(gpsQualityApiRepositoryProvider)
        .rePairTrajectory(testId, toleranceSec));
  }
}

final trajectoryReportProvider =
    AsyncNotifierProvider.family<
        TrajectoryReportController, TrajectoryQualityReport, int>(
  TrajectoryReportController.new,
);

final trajectoryComparisonProvider =
    FutureProvider<List<TrajectoryComparisonRow>>(
  (ref) =>
      ref.read(gpsQualityApiRepositoryProvider).fetchTrajectoryComparison(),
);

// ── NIX-68: Standard track lines ─────────────────────────────────

class TrackLinesController extends AsyncNotifier<List<StandardTrackLine>> {
  @override
  Future<List<StandardTrackLine>> build() =>
      ref.read(gpsQualityApiRepositoryProvider).fetchTrackLines();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gpsQualityApiRepositoryProvider).fetchTrackLines(),
    );
  }
}

final trackLinesProvider =
    AsyncNotifierProvider<TrackLinesController, List<StandardTrackLine>>(
  TrackLinesController.new,
);

/// Point list of one candidate (map preview), family by trackLineId.
final trackLinePointsProvider =
    FutureProvider.family<List<LineTrackPoint>, int>(
  (ref, lineId) =>
      ref.read(gpsQualityApiRepositoryProvider).fetchTrackLinePoints(lineId),
);

// ── NIX-68: LINE reports ─────────────────────────────────────────

/// LINE report statistics summary, family by testId.
final lineReportProvider = FutureProvider.family<LineQualityReport, int>(
  (ref, testId) =>
      ref.read(gpsQualityApiRepositoryProvider).fetchLineReport(testId),
);

/// Standard track point list snapshot, family by testId.
final lineReportTrackProvider =
    FutureProvider.family<List<LineTrackPoint>, int>(
  (ref, testId) =>
      ref.read(gpsQualityApiRepositoryProvider).fetchLineReportTrack(testId),
);

/// Per-point deviations, family by testId.
final lineReportDeviationsProvider =
    FutureProvider.family<List<LineDeviation>, int>(
  (ref, testId) => ref
      .read(gpsQualityApiRepositoryProvider)
      .fetchLineReportDeviations(testId),
);

// ── NIX-68: Unified per-device check summary ─────────────────────

/// Latest test of each type for one device, family by deviceCode.
final checksSummaryProvider =
    FutureProvider.family<List<CheckSummaryItem>, String>(
  (ref, deviceCode) => ref
      .read(gpsQualityApiRepositoryProvider)
      .fetchChecksSummary(deviceCode),
);

// ── NIX-68: LINE comparison ──────────────────────────────────────

/// Query key for the LINE comparison endpoint. A null [deviceCode] returns
/// only the stats table + standard track; a value lazily loads one device's
/// track points. Spatial matching: no time window.
typedef LineComparisonQuery = ({
  int trackLineId,
  String? deviceCode,
});

final lineComparisonProvider =
    FutureProvider.family<LineComparisonResult, LineComparisonQuery>(
  (ref, query) =>
      ref.read(gpsQualityApiRepositoryProvider).fetchLineComparison(
            trackLineId: query.trackLineId,
            deviceCode: query.deviceCode,
          ),
);
