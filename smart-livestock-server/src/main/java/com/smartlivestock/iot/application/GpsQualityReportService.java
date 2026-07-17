package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.GpsQualitySession;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.RtkReferencePoint;
import com.smartlivestock.iot.domain.port.dto.GpsPointWithTelemetry;
import com.smartlivestock.iot.domain.port.dto.GpsQualityStats;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.iot.domain.repository.GpsQualitySessionRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.domain.repository.RtkReferencePointRepository;
import com.smartlivestock.iot.domain.service.GpsQualityCalculator;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Assembles static GPS quality reports by joining test → session → RTK truth → GPS points,
 * then delegating statistics to {@link GpsQualityCalculator}.
 * <p>
 * The test provides the truth reference (rtkPointId) and sub-range (testStartedAt/testEndedAt).
 * The session provides the deviceId for GPS data lookup.
 */
@Service
@RequiredArgsConstructor
public class GpsQualityReportService {

    private final GpsQualityTestRepository testRepository;
    private final GpsQualitySessionRepository sessionRepository;
    private final RtkReferencePointRepository rtkPointRepository;
    private final GpsLogRepository gpsLogRepository;
    private final DeviceRepository deviceRepository;

    private final GpsQualityCalculator calculator = new GpsQualityCalculator();

    public ReportResult generate(Long testId, boolean excludeSuspect) {
        GpsQualityTest test = testRepository.findById(testId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Test not found: " + testId));
        GpsQualitySession session = sessionRepository.findById(test.getSessionId())
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Session not found: " + test.getSessionId()));
        RtkReferencePoint rtk = rtkPointRepository.findById(test.getRtkPointId())
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "RTK point not found: " + test.getRtkPointId()));
        String deviceCode = deviceRepository.findById(session.getDeviceId())
                .map(Device::getDeviceCode).orElse(null);

        List<GpsPointWithTelemetry> points = gpsLogRepository.findByDeviceIdAndTimeRangeWithTelemetry(
                session.getDeviceId(), test.getTestStartedAt(), test.getTestEndedAt());

        GpsQualityStats stats = calculator.calculate(
                points, rtk.getLatitude(), rtk.getLongitude(), excludeSuspect);

        List<ScatterPoint> scatter = points.stream()
                .map(p -> new ScatterPoint(
                        p.latitude(),
                        p.longitude(),
                        calculator.distance(rtk.getLatitude(), rtk.getLongitude(), p.latitude(), p.longitude()),
                        p.recordedAt(),
                        p.stepNumber() != null && p.stepNumber() > 0))
                .toList();

        return new ReportResult(test, session, rtk, deviceCode, stats, excludeSuspect, scatter);
    }

    public ComparisonResult generateComparison(Long rtkPointId) {
        RtkReferencePoint rtk = rtkPointRepository.findById(rtkPointId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "RTK point not found: " + rtkPointId));

        List<ComparisonEntry> entries = new ArrayList<>();
        for (GpsQualityTest test : testRepository.findByRtkPointId(rtkPointId)) {
            GpsQualitySession session = sessionRepository.findById(test.getSessionId()).orElse(null);
            if (session == null) continue;

            String code = deviceRepository.findById(session.getDeviceId())
                    .map(Device::getDeviceCode).orElse(null);
            List<GpsPointWithTelemetry> points = gpsLogRepository.findByDeviceIdAndTimeRangeWithTelemetry(
                    session.getDeviceId(), test.getTestStartedAt(), test.getTestEndedAt());
            GpsQualityStats stats = calculator.calculate(points, rtk.getLatitude(), rtk.getLongitude(), true);
            entries.add(new ComparisonEntry(test.getId(), session.getDeviceId(), code, stats));
        }
        return new ComparisonResult(rtk, entries);
    }

    public record ScatterPoint(BigDecimal latitude, BigDecimal longitude, double error,
                               Instant recordedAt, boolean suspect) {}

    public record ReportResult(GpsQualityTest test, GpsQualitySession session, RtkReferencePoint rtk,
                               String deviceCode, GpsQualityStats stats, boolean excludeSuspect,
                               List<ScatterPoint> scatter) {}

    public record ComparisonEntry(Long testId, Long deviceId, String deviceCode, GpsQualityStats stats) {}

    public record ComparisonResult(RtkReferencePoint rtk, List<ComparisonEntry> entries) {}
}
