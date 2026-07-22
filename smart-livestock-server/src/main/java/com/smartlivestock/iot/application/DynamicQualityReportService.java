package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.CalibrationStatus;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DynamicTestRoute;
import com.smartlivestock.iot.domain.model.DynamicTestRoutePoint;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.model.RtkReferencePoint;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.port.dto.DynamicQualityStats;
import com.smartlivestock.iot.domain.port.dto.GpsPointWithTelemetry;
import com.smartlivestock.iot.domain.port.dto.RoutePoint;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DynamicTestRoutePointRepository;
import com.smartlivestock.iot.domain.repository.DynamicTestRouteRepository;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.domain.repository.RtkReferencePointRepository;
import com.smartlivestock.iot.domain.service.DynamicQualityCalculator;
import com.smartlivestock.iot.domain.service.GpsQualityCalculator;
import com.smartlivestock.iot.interfaces.admin.dto.DynamicComparisonDto;
import com.smartlivestock.iot.interfaces.admin.dto.DynamicQualityReportDto;
import com.smartlivestock.iot.interfaces.admin.dto.DynamicQualityReportDto.MatchedPass;
import com.smartlivestock.iot.interfaces.admin.dto.DynamicQualityReportDto.PerRtkPointSummary;
import com.smartlivestock.iot.interfaces.admin.dto.DynamicQualityReportDto.StaticComparison;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Assembles dynamic GPS quality reports by joining test → route → route points →
 * GPS logs, then delegating matching to {@link DynamicQualityCalculator}.
 * <p>
 * Also computes the static-vs-dynamic comparison for the same device when a
 * matching STATIC test exists.
 */
@Service
@RequiredArgsConstructor
public class DynamicQualityReportService {

    /** Default matching threshold (meters). See spec §4.1. */
    private static final double DEFAULT_THRESHOLD = 30.0;

    private final GpsQualityTestRepository testRepository;
    private final DynamicTestRouteRepository routeRepository;
    private final DynamicTestRoutePointRepository routePointRepository;
    private final RtkReferencePointRepository rtkPointRepository;
    private final GpsLogRepository gpsLogRepository;
    private final DeviceRepository deviceRepository;
    private final GpsQualityReportService staticReportService;

    private final DynamicQualityCalculator dynamicCalculator = new DynamicQualityCalculator();
    private final GpsQualityCalculator distanceHelper = new GpsQualityCalculator();

    public DynamicQualityReportDto generate(Long testId, Double thresholdOverride) {
        GpsQualityTest test = testRepository.findById(testId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "GPS quality test not found: " + testId));
        if (!"READY".equals(test.getStatus())) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "Cannot generate dynamic report for test " + testId
                    + ": status is " + test.getStatus());
        }
        if (test.getTestType() != TestType.DYNAMIC) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "Test " + testId + " is not a DYNAMIC test (got " + test.getTestType() + ")");
        }

        DynamicTestRoute route = routeRepository.findById(test.getRouteId())
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Route not found: " + test.getRouteId()));

        Long deviceId = test.getDeviceId();
        String deviceCode = test.getDeviceCode();
        if (deviceCode == null && deviceId != null) {
            deviceCode = deviceRepository.findById(deviceId)
                    .map(Device::getDeviceCode).orElse(null);
        }

        double threshold = thresholdOverride != null ? thresholdOverride : DEFAULT_THRESHOLD;

        // --- assemble route points with RTK coordinates ---
        List<DynamicTestRoutePoint> routePoints =
                routePointRepository.findByRouteIdOrderBySequenceNoAsc(route.getId());
        List<RoutePoint> calculatorInput = new ArrayList<>(routePoints.size());
        Map<Integer, RtkMeta> rtkMetaBySeq = new HashMap<>();
        for (DynamicTestRoutePoint rp : routePoints) {
            RtkReferencePoint rtk = rtkPointRepository.findById(rp.getRtkPointId())
                    .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                            "RTK point not found: " + rp.getRtkPointId()));
            int seq = rp.getSequenceNo() != null ? rp.getSequenceNo() : 0;
            calculatorInput.add(new RoutePoint(rtk.getLatitude(), rtk.getLongitude(), seq));
            rtkMetaBySeq.put(seq, new RtkMeta(rtk.getId(), rtk.getLocationName(), rtk.getPointLabel(),
                    rtk.getLatitude(), rtk.getLongitude()));
        }

       // --- fetch GPS logs in the test window ---
       List<GpsPointWithTelemetry> gpsPoints = gpsLogRepository.findByDeviceIdAndTimeRangeWithTelemetry(
                deviceId, test.getStartedAt(), test.getEndedAt() != null
                        ? test.getEndedAt()
                        : Instant.now().plus(8, ChronoUnit.HOURS));

        // --- run matching ---
        DynamicQualityStats stats = dynamicCalculator.calculate(calculatorInput, gpsPoints, threshold);

        // --- grade (dynamic thresholds, tighter than static) ---
        QualityGrade grade = determineDynamicGrade(stats);

        // --- per-point breakdown ---
        List<PerPointMatch> matches = computePerPointMatches(calculatorInput, gpsPoints, threshold);
        List<PerRtkPointSummary> perPoint = new ArrayList<>(matches.size());
        List<MatchedPass> passes = new ArrayList<>();
        for (PerPointMatch m : matches) {
            RtkMeta meta = rtkMetaBySeq.get(m.sequenceNo);
            PerRtkPointSummary summary = new PerRtkPointSummary(
                    meta != null ? meta.id() : null,
                    meta != null ? meta.locationName() : null,
                    meta != null ? meta.label() : null,
                    m.sequenceNo,
                    m.passed,
                    m.ambiguous,
                    m.passed ? m.error : null,
                    m.passed && m.matchedPoint != null ? m.matchedPoint.recordedAt() : null);
            perPoint.add(summary);
            if (m.passed && m.matchedPoint != null && meta != null) {
                passes.add(new MatchedPass(m.sequenceNo,
                        m.matchedPoint.latitude(), m.matchedPoint.longitude(),
                        meta.latitude(), meta.longitude(),
                        m.error, m.ambiguous, m.matchedPoint.recordedAt()));
            }
        }

       // --- static-vs-dynamic comparison (best-effort) ---
       StaticComparison comparison = buildStaticComparison(test, stats.p95());

       // --- assemble DTO ---
       DynamicQualityReportDto dto = new DynamicQualityReportDto();
       dto.setTestId(test.getId());
       dto.setDeviceId(deviceId);
       dto.setDeviceCode(deviceCode);
       dto.setRouteId(route.getId());
       dto.setRouteName(route.getName());
       dto.setStartedAt(test.getStartedAt());
       dto.setEndedAt(test.getEndedAt());
       dto.setThreshold(threshold);
       dto.setGrade(grade);
       dto.setStats(stats);
       dto.setPerPoint(perPoint);
       dto.setPasses(passes);
       dto.setStaticComparison(comparison);
       return dto;
   }

    // ------------------------------------------------------------------
    // Route-level dynamic comparison (latest READY test per device)
    // ------------------------------------------------------------------

    /**
     * Compare all devices' dynamic quality on one route: takes the latest READY
     * dynamic test per device and reuses {@link #generate(Long, Double)} for the
     * per-device summary.
     */
    public DynamicComparisonDto generateRouteComparison(Long routeId) {
        DynamicTestRoute route = routeRepository.findById(routeId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Route not found: " + routeId));

        // Latest READY dynamic test per device (by startedAt, then id)
        Map<Long, GpsQualityTest> latestByDevice = new LinkedHashMap<>();
        for (GpsQualityTest t : testRepository.findByRouteIdAndStatus(routeId, "READY")) {
            if (t.getTestType() != TestType.DYNAMIC || t.getDeviceId() == null) continue;
            latestByDevice.merge(t.getDeviceId(), t, (a, b) -> {
                int cmp = a.getStartedAt().compareTo(b.getStartedAt());
                if (cmp != 0) return cmp > 0 ? a : b;
                return a.getId() >= b.getId() ? a : b;
            });
        }

        List<DynamicComparisonDto.DeviceSummary> devices = latestByDevice.values().stream()
                .sorted(Comparator.comparing(t -> t.getDeviceCode() != null ? t.getDeviceCode() : ""))
                .map(t -> {
                    DynamicQualityReportDto report = generate(t.getId(), null);
                    DynamicQualityStats s = report.getStats();
                    return new DynamicComparisonDto.DeviceSummary(
                            t.getDeviceId(), report.getDeviceCode(), t.getId(),
                            s.coverage(), s.matchedCount(), s.missedCount(), s.ambiguousCount(),
                            s.inOrder(), s.meanError(), s.p50(), s.p95(),
                            t.getStartedAt(), t.getEndedAt());
                })
                .toList();

        DynamicComparisonDto dto = new DynamicComparisonDto();
        dto.setRouteId(route.getId());
        dto.setRouteName(route.getName());
        dto.setDevices(devices);
        return dto;
    }

    // ------------------------------------------------------------------
    // Dynamic grade (spec §4.4 — tighter than static thresholds)
    // ------------------------------------------------------------------

    private QualityGrade determineDynamicGrade(DynamicQualityStats s) {
        if (s.matchedCount() < 4) return QualityGrade.UNAVAILABLE;
        if (s.p95() <= 10.0 && s.coverage() >= 50.0) return QualityGrade.EXCELLENT;
        if (s.p95() <= 20.0 && s.coverage() >= 30.0) return QualityGrade.USABLE;
        if (s.p95() <= 35.0 && s.coverage() >= 20.0) return QualityGrade.MARGINAL;
        return QualityGrade.UNAVAILABLE;
    }

    // ------------------------------------------------------------------
    // Per-point match reconstruction
    // ------------------------------------------------------------------

    private record RtkMeta(Long id, String locationName, String label,
                           BigDecimal latitude, BigDecimal longitude) {
    }

    private record PerPointMatch(int sequenceNo, boolean passed, boolean ambiguous,
                                 double error, GpsPointWithTelemetry matchedPoint) {
    }

    /**
     * Recompute per-point nearest-match outcomes.
     */
    private List<PerPointMatch> computePerPointMatches(
            List<RoutePoint> route, List<GpsPointWithTelemetry> gpsPoints, double threshold) {
        List<PerPointMatch> results = new ArrayList<>(route.size());
        int lastMatchedGpsIndex = -1;
        for (RoutePoint rp : route) {
            if (gpsPoints.isEmpty()) {
                results.add(new PerPointMatch(rp.sequenceNo(), false, false, 0, null));
                continue;
            }
            int nearestIdx = 0;
            double nearestDist = Double.MAX_VALUE;
            for (int i = 0; i < gpsPoints.size(); i++) {
                double d = distanceHelper.distance(rp.latitude(), rp.longitude(),
                        gpsPoints.get(i).latitude(), gpsPoints.get(i).longitude());
                if (d < nearestDist) {
                    nearestDist = d;
                    nearestIdx = i;
                }
            }
            boolean passed = nearestDist <= threshold;
            boolean ambiguous = passed && lastMatchedGpsIndex == nearestIdx;
            results.add(new PerPointMatch(rp.sequenceNo(), passed, ambiguous,
                    nearestDist, passed ? gpsPoints.get(nearestIdx) : null));
            if (passed) {
                lastMatchedGpsIndex = nearestIdx;
            }
        }
        return results;
    }

    // ------------------------------------------------------------------
    // Static-vs-dynamic comparison (same device, most recent STATIC test)
    // ------------------------------------------------------------------

    private StaticComparison buildStaticComparison(GpsQualityTest dynamicTest, double dynamicP95) {
        try {
            Long deviceId = dynamicTest.getDeviceId();
            if (deviceId == null) return null;

            // Find the most recent STATIC test for the same device
            GpsQualityTest staticTest = testRepository.findByDeviceIdOrderByStartedAt(deviceId).stream()
                    .filter(t -> t.getTestType() == TestType.STATIC)
                    .findFirst().orElse(null);
            if (staticTest == null) {
                return null;
            }
            GpsQualityReportService.ReportResult staticResult =
                    staticReportService.generate(staticTest.getId(), true);
            double staticP95 = staticResult.stats().p95();
            double delta = dynamicP95 - staticP95;
            return new StaticComparison(staticTest.getId(), staticP95,
                    staticResult.stats().grade(), delta);
        } catch (Exception ignored) {
            return null;
        }
    }
}
