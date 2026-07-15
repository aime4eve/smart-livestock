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

  Future<bool> createSession({
    required int deviceId,
    required DateTime startedAt,
    DateTime? endedAt,
  }) async {
    try {
      await ref.read(gpsQualityApiRepositoryProvider).createSession(
            rtkPointId: rtkPointId,
            deviceId: deviceId,
            startedAt: startedAt,
            endedAt: endedAt,
          );
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> endSession(int id) async {
    try {
      await ref.read(gpsQualityApiRepositoryProvider).endSession(id);
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSession(int id) async {
    try {
      await ref.read(gpsQualityApiRepositoryProvider).deleteSession(id);
      ref.invalidateSelf();
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
