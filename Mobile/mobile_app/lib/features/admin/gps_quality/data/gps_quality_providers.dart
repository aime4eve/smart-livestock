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

// ── Calibration sessions (family by rtkPointId) ───────────────────

class CalibrationSessionsController
    extends AsyncNotifier<List<CalibrationSession>> {
  CalibrationSessionsController(this.rtkPointId);

  final int rtkPointId;

  @override
  Future<List<CalibrationSession>> build() async {
    final result = await ref
        .read(gpsQualityApiRepositoryProvider)
        .fetchSessions(rtkPointId: rtkPointId);
    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final r = await ref
          .read(gpsQualityApiRepositoryProvider)
          .fetchSessions(rtkPointId: rtkPointId);
      return r.items;
    });
  }

  Future<void> createSession({
    required int deviceId,
    required DateTime startedAt,
    DateTime? endedAt,
  }) async {
    // Let exceptions propagate — the caller shows the error message
    await ref.read(gpsQualityApiRepositoryProvider).createSession(
          rtkPointId: rtkPointId,
          deviceId: deviceId,
          startedAt: startedAt,
          endedAt: endedAt,
        );
    ref.invalidateSelf();
    ref.invalidate(comparisonProvider(rtkPointId));
  }

  /// Batch-create sessions. Returns per-row success/failure so the
  /// caller can report which rows failed. Invalidates caches regardless.
  Future<BatchCreateResult> createSessionsBatch(
      List<BatchSessionRequest> rows) async {
    final result = await ref
        .read(gpsQualityApiRepositoryProvider)
        .createSessionBatch(rows);
    ref.invalidateSelf();
    ref.invalidate(comparisonProvider(rtkPointId));
    return result;
  }

  Future<bool> endSession(int id) async {
    try {
      await ref.read(gpsQualityApiRepositoryProvider).endSession(id);
      ref.invalidateSelf();
      ref.invalidate(comparisonProvider(rtkPointId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSession(int id) async {
    try {
      await ref.read(gpsQualityApiRepositoryProvider).deleteSession(id);
      ref.invalidateSelf();
      ref.invalidate(comparisonProvider(rtkPointId));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final calibrationSessionsProvider = AsyncNotifierProvider.family<
    CalibrationSessionsController, List<CalibrationSession>, int>(
  CalibrationSessionsController.new,
);

// ── Quality report (family by session + excludeSuspect) ───────────

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

class GpsSessionsController extends AsyncNotifier<List<GpsQualitySession>> {
  @override
  Future<List<GpsQualitySession>> build() async {
    final result = await ref.read(gpsQualityApiRepositoryProvider).fetchGpsSessions();
    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final r = await ref.read(gpsQualityApiRepositoryProvider).fetchGpsSessions();
      return r.items;
    });
  }
}

final gpsSessionsProvider =
    AsyncNotifierProvider<GpsSessionsController, List<GpsQualitySession>>(
  GpsSessionsController.new,
);

// ── Tests by session (family) ─────────────────────────────────────

final sessionTestsProvider =
    FutureProvider.family<List<CalibrationSession>, int>(
  (ref, sessionId) =>
      ref.read(gpsQualityApiRepositoryProvider).fetchTestsBySession(sessionId),
);
