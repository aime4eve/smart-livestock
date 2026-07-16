package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.CalibrationStatus;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.RtkReferencePoint;
import com.smartlivestock.iot.domain.port.dto.GpsPointWithTelemetry;
import com.smartlivestock.iot.domain.port.dto.GpsQualityStats;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
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
 * Assembles GPS quality reports by joining session → RTK truth → GPS points,
 * then delegating statistics to {@link GpsQualityCalculator}.
 */
@Service
@RequiredArgsConstructor
public class GpsQualityReportService {

    private final GpsQualityTestRepository sessionRepository;
    private final RtkReferencePointRepository rtkPointRepository;
    private final GpsLogRepository gpsLogRepository;
    private final DeviceRepository deviceRepository;

    // Stateless domain service; safe to instantiate once.
    private final GpsQualityCalculator calculator = new GpsQualityCalculator();

    public ReportResult generate(Long sessionId, boolean excludeSuspect) {
        GpsQualityTest session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Calibration session not found: " + sessionId));
        RtkReferencePoint rtk = rtkPointRepository.findById(session.getRtkPointId())
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "RTK point not found: " + session.getRtkPointId()));
        String deviceCode = deviceRepository.findById(session.getDeviceId())
                .map(Device::getDeviceCode).orElse(null);

        List<GpsPointWithTelemetry> points = gpsLogRepository.findByDeviceIdAndTimeRangeWithTelemetry(
                session.getDeviceId(), session.getStartedAt(), session.getEndedAt());

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

        return new ReportResult(session, rtk, deviceCode, stats, excludeSuspect, scatter);
    }

    public ComparisonResult generateComparison(Long rtkPointId) {
        RtkReferencePoint rtk = rtkPointRepository.findById(rtkPointId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "RTK point not found: " + rtkPointId));

        List<ComparisonEntry> entries = new ArrayList<>();
        for (GpsQualityTest s : sessionRepository.findByRtkPointIdOrderByStartedAtDesc(rtkPointId)) {
            if (s.getStatus() != CalibrationStatus.COMPLETED) {
                continue;
            }
            String code = deviceRepository.findById(s.getDeviceId())
                    .map(Device::getDeviceCode).orElse(null);
            List<GpsPointWithTelemetry> points = gpsLogRepository.findByDeviceIdAndTimeRangeWithTelemetry(
                    s.getDeviceId(), s.getStartedAt(), s.getEndedAt());
            // Comparison uses excludeSuspect=true for a fair across-device comparison.
            GpsQualityStats stats = calculator.calculate(points, rtk.getLatitude(), rtk.getLongitude(), true);
            entries.add(new ComparisonEntry(s.getId(), s.getDeviceId(), code, stats));
        }
        return new ComparisonResult(rtk, entries);
    }

    /** A single scatter/trajectory point with its error vs RTK truth and suspect flag. */
    public record ScatterPoint(BigDecimal latitude, BigDecimal longitude, double error,
                               Instant recordedAt, boolean suspect) {
    }

    public record ReportResult(GpsQualityTest session, RtkReferencePoint rtk, String deviceCode,
                               GpsQualityStats stats, boolean excludeSuspect, List<ScatterPoint> scatter) {
    }

    public record ComparisonEntry(Long sessionId, Long deviceId, String deviceCode, GpsQualityStats stats) {
    }

    public record ComparisonResult(RtkReferencePoint rtk, List<ComparisonEntry> entries) {
    }
}
