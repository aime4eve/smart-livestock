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
  @override
  Future<QualityCheckListResult> build() async {
    return ref
        .read(gpsQualityApiRepositoryProvider)
        .fetchChecks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gpsQualityApiRepositoryProvider).fetchChecks(),
    );
  }

  Future<void> fetchFiltered({
    String? status,
    String? eui,
    int? deviceId,
    int page = 0,
    int size = 20,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gpsQualityApiRepositoryProvider).fetchChecks(
        status: status,
        eui: eui,
        deviceId: deviceId,
        page: page,
        size: size,
      ),
    );
  }
}

final checksProvider =
    AsyncNotifierProvider<ChecksController, QualityCheckListResult>(
  ChecksController.new,
);
