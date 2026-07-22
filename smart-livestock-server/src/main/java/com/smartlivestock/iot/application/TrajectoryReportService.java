package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.GpsQualityTrackPoint;
import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.model.TrackMatchSource;
import com.smartlivestock.iot.domain.port.dto.TrajectoryQualityStats;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTrackPointRepository;
import com.smartlivestock.iot.domain.service.TrajectoryPairingService;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryComparisonDto;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryQualityReportDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
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
                    p.getTimeDiffSeconds()));
        }

        TrajectoryQualityReportDto dto = new TrajectoryQualityReportDto();
        dto.setTestId(test.getId());
        dto.setDeviceCode(test.getDeviceCode());
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
