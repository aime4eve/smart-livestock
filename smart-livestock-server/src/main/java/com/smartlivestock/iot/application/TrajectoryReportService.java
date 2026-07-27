package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.GpsQualityTrackPoint;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.GpsLog;
import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.model.TrackMatchSource;
import com.smartlivestock.iot.domain.port.dto.TrackPairCandidate;
import com.smartlivestock.iot.domain.port.dto.TrackPairResult;
import com.smartlivestock.iot.domain.port.dto.TrajectoryQualityStats;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTrackPointRepository;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.iot.domain.service.TrajectoryPairingService;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryComparisonDto;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryQualityReportDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Assembles TRAJECTORY quality reports from the persisted pairing snapshot
 * (spec D2: gps_logs is never re-queried), plus the cross-device trajectory
 * comparison (spec D10).
 */
@Service
@RequiredArgsConstructor
public class TrajectoryReportService {

   private final GpsQualityTestRepository testRepository;
   private final GpsQualityTrackPointRepository trackPointRepository;
   private final GpsQualityReportService staticReportService;
   private final DeviceRepository deviceRepository;
    private final GpsLogRepository gpsLogRepository;

    private final TrajectoryPairingService pairingService = new TrajectoryPairingService();

    public TrajectoryQualityReportDto generate(Long testId) {
        GpsQualityTest test = testRepository.findById(testId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "GPS quality test not found: " + testId));
        if (test.getTestType() != TestType.TRAJECTORY) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "Test " + testId + " is not a TRAJECTORY test (got " + test.getTestType() + ")");
        }
        if (!"READY".equals(test.getStatus())) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "Cannot generate trajectory report for test " + testId
                    + ": status is " + test.getStatus());
        }

        List<GpsQualityTrackPoint> points = trackPointRepository.findByTestIdOrderByCollectedAt(testId);
        TrajectoryQualityStats stats = pairingService.aggregate(points);
        QualityGrade grade = pairingService.determineTrajectoryGrade(stats);

        List<TrajectoryQualityReportDto.TrackPoint> rows = new ArrayList<>(points.size());
        for (GpsQualityTrackPoint p : points) {
            boolean paired = p.getMatchSource() != TrackMatchSource.UNPAIRED;
           rows.add(new TrajectoryQualityReportDto.TrackPoint(
                   p.getSequenceNo(),
                   p.getCollectedAt(),
                   p.getRtkLatitude(),
                   p.getRtkLongitude(),
                   p.getDeviceLatitude(),
                   p.getDeviceLongitude(),
                   paired ? pairingService.errorMeters(p) : null,
                   p.getMatchSource().name(),
                    p.getTimeDiffSeconds(),
                    p.getNearestGpsLogSeconds()));
        }

        TrajectoryQualityReportDto dto = new TrajectoryQualityReportDto();
        dto.setTestId(test.getId());
        dto.setDeviceCode(test.getDeviceCode());
        // Best-effort: backfill deviceEui (and deviceCode if missing) from Device.
        Long deviceId = test.getDeviceId();
        String deviceCode = test.getDeviceCode();
        String deviceEui = null;
        if (deviceId != null) {
            Device device = deviceRepository.findById(deviceId).orElse(null);
            if (device != null) {
                if (deviceCode == null) deviceCode = device.getDeviceCode();
                deviceEui = device.getDevEui();
            }
        }
        if (deviceCode != null) dto.setDeviceCode(deviceCode);
        dto.setDeviceEui(deviceEui);
        dto.setStartedAt(test.getStartedAt());
        dto.setEndedAt(test.getEndedAt());
        dto.setToleranceSec(points.isEmpty() || points.get(0).getToleranceSeconds() == null
                ? TrajectoryPairingService.DEFAULT_TOLERANCE_SECONDS
                : points.get(0).getToleranceSeconds());
        dto.setGrade(grade);
        dto.setTotalPoints(stats.totalPoints());
        dto.setFilePaired(stats.filePaired());
        dto.setLogPaired(stats.logPaired());
        dto.setUnpaired(stats.unpaired());
        dto.setPairRate(stats.pairRate());
        dto.setMeanError(stats.meanError());
        dto.setP50(stats.p50());
        dto.setP95(stats.p95());
        dto.setMaxError(stats.maxError());
        dto.setPoints(rows);
       dto.setStaticComparison(buildStaticComparison(test, stats.p95()));
       return dto;
   }

    // ------------------------------------------------------------------
    // Re-pair: re-query gps_logs with a new tolerance and persist results
    // ------------------------------------------------------------------

    /**
     * Re-pair all track points of a TRAJECTORY test against gps_logs using the
     * given tolerance, persist the updated snapshot, and return the fresh report.
     * <p>
     * Points originally paired from FILE (device coordinate in the import file)
     * keep their FILE source and are not affected. Only GPS_LOG / UNPAIRED
     * points are re-evaluated.
     */
    public TrajectoryQualityReportDto rePair(Long testId, int toleranceSec) {
        GpsQualityTest test = testRepository.findById(testId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "GPS quality test not found: " + testId));
        if (test.getTestType() != TestType.TRAJECTORY) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "Test " + testId + " is not a TRAJECTORY test");
        }
        if (test.getDeviceId() == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "Test " + testId + " has no device; cannot re-pair");
        }

        List<GpsQualityTrackPoint> points =
                trackPointRepository.findByTestIdOrderByCollectedAt(testId);
        if (points.isEmpty()) {
            return generate(testId);
        }

        // Determine the expanded time window from collected_at ± tolerance
        Instant minCollected = points.stream().map(GpsQualityTrackPoint::getCollectedAt)
                .min(Comparator.naturalOrder()).orElse(Instant.now());
        Instant maxCollected = points.stream().map(GpsQualityTrackPoint::getCollectedAt)
                .max(Comparator.naturalOrder()).orElse(Instant.now());

        // Load GPS candidates once for the entire window (with extra margin so
        // we can compute nearestGpsLogSeconds even for UNPAIRED points)
        Instant from = minCollected.minusSeconds(toleranceSec);
        Instant to = maxCollected.plusSeconds(toleranceSec);
        List<GpsLog> logs = gpsLogRepository.findByDeviceIdAndRecordedAtBetween(
                test.getDeviceId(), from, to);

        for (GpsQualityTrackPoint p : points) {
            // FILE points are immutable — device coordinate came from the file
            if (p.getMatchSource() == TrackMatchSource.FILE) {
                p.setToleranceSeconds(toleranceSec);
                continue;
            }

            // Build candidate list and pair
            List<TrackPairCandidate> candidates = logs.stream()
                    .map(l -> new TrackPairCandidate(l.getId(), l.getLatitude(),
                            l.getLongitude(), l.getRecordedAt()))
                    .toList();
            TrackPairResult pair = pairingService.pair(
                    p.getCollectedAt(), null, null, candidates, toleranceSec);

            p.setMatchSource(pair.matchSource());
            p.setMatchedGpsLogId(pair.matchedGpsLogId());
            p.setDeviceLatitude(pair.deviceLatitude());
            p.setDeviceLongitude(pair.deviceLongitude());
            p.setTimeDiffSeconds(pair.timeDiffSeconds());
            p.setToleranceSeconds(toleranceSec);

            // Compute nearest GPS log distance for diagnostic display
            if (pair.matchSource() == TrackMatchSource.UNPAIRED && !logs.isEmpty()) {
                long nearest = logs.stream()
                        .mapToLong(l -> Math.abs(Duration.between(
                                p.getCollectedAt(), l.getRecordedAt()).getSeconds()))
                        .min().orElse(0);
                p.setNearestGpsLogSeconds((int) nearest);
            } else {
                p.setNearestGpsLogSeconds(null);
            }
        }

        trackPointRepository.saveAll(points);

        // Also update test note to reflect new tolerance
        String note = test.getNote();
        if (note != null) {
            // Replace the old "±Ns" suffix if present
            String updated = note.replaceAll(" ±\\d+s$", " ±" + toleranceSec + "s");
            test.setNote(updated);
            testRepository.save(test);
        }

        return generate(testId);
    }

    // ------------------------------------------------------------------
    // Cross-device comparison: latest READY TRAJECTORY test per device
    // ------------------------------------------------------------------

    public TrajectoryComparisonDto generateComparison() {
        Map<Long, GpsQualityTest> latestByDevice = new LinkedHashMap<>();
        for (GpsQualityTest t : testRepository.findByStatus("READY")) {
            if (t.getTestType() != TestType.TRAJECTORY || t.getDeviceId() == null) continue;
            latestByDevice.merge(t.getDeviceId(), t, (a, b) -> {
                int cmp = a.getStartedAt().compareTo(b.getStartedAt());
                if (cmp != 0) return cmp > 0 ? a : b;
                return a.getId() >= b.getId() ? a : b;
            });
        }

        List<TrajectoryComparisonDto.DeviceSummary> devices = latestByDevice.values().stream()
                .sorted(Comparator.comparing(t -> t.getDeviceCode() != null ? t.getDeviceCode() : ""))
                .map(t -> {
                    TrajectoryQualityStats s = pairingService.aggregate(
                            trackPointRepository.findByTestIdOrderByCollectedAt(t.getId()));
                    QualityGrade grade = pairingService.determineTrajectoryGrade(s);
                    int paired = s.filePaired() + s.logPaired();
                    return new TrajectoryComparisonDto.DeviceSummary(
                            t.getId(), t.getDeviceId(), t.getDeviceCode(),
                            s.totalPoints(), paired, s.pairRate(),
                            s.meanError(), s.p50(), s.p95(), grade.name(),
                            t.getStartedAt(), t.getEndedAt());
                })
                .toList();

        TrajectoryComparisonDto dto = new TrajectoryComparisonDto();
        dto.setDevices(devices);
        return dto;
    }

    // ------------------------------------------------------------------
    // Static-vs-trajectory comparison (same device, most recent STATIC test)
    // ------------------------------------------------------------------

    private TrajectoryQualityReportDto.StaticComparison buildStaticComparison(
            GpsQualityTest trajectoryTest, double trajectoryP95) {
        try {
            Long deviceId = trajectoryTest.getDeviceId();
            if (deviceId == null) return null;

            GpsQualityTest staticTest = testRepository.findByDeviceIdOrderByStartedAt(deviceId).stream()
                    .filter(t -> t.getTestType() == TestType.STATIC)
                    .findFirst().orElse(null);
            if (staticTest == null) {
                return null;
            }
            GpsQualityReportService.ReportResult staticResult =
                    staticReportService.generate(staticTest.getId(), true);
            double staticP95 = staticResult.stats().p95();
            return new TrajectoryQualityReportDto.StaticComparison(
                    staticTest.getId(), staticP95,
                    staticResult.stats().grade(), trajectoryP95 - staticP95);
        } catch (Exception ignored) {
            return null;
        }
    }
}
