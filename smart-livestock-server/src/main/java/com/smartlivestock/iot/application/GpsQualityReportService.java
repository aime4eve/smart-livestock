package com.smartlivestock.iot.application;

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
 * Assembles static GPS quality reports by joining test → RTK truth → GPS points,
 * then delegating statistics to {@link GpsQualityCalculator}.
 * <p>
 * The test directly provides the truth reference (rtkPointId), device info (deviceCode/deviceId),
 * and time range (startedAt/endedAt). No session indirection.
 */
@Service
@RequiredArgsConstructor
public class GpsQualityReportService {

    private final GpsQualityTestRepository testRepository;
    private final RtkReferencePointRepository rtkPointRepository;
    private final GpsLogRepository gpsLogRepository;
    private final DeviceRepository deviceRepository;

    private final GpsQualityCalculator calculator = new GpsQualityCalculator();

    public ReportResult generate(Long testId, boolean excludeSuspect) {
        GpsQualityTest test = testRepository.findById(testId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Test not found: " + testId));
        if (!"READY".equals(test.getStatus())) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "Cannot generate report for test " + testId
                    + ": status is " + test.getStatus());
        }
        RtkReferencePoint rtk = rtkPointRepository.findById(test.getRtkPointId())
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "RTK point not found: " + test.getRtkPointId()));

        Long deviceId = test.getDeviceId();
        String deviceCode = test.getDeviceCode();
        if (deviceCode == null && deviceId != null) {
            deviceCode = deviceRepository.findById(deviceId)
                    .map(Device::getDeviceCode).orElse(null);
        }

        Instant endTime = test.getEndedAt() != null ? test.getEndedAt() : Instant.now();
        List<GpsPointWithTelemetry> points = gpsLogRepository.findByDeviceIdAndTimeRangeWithTelemetry(
                deviceId, test.getStartedAt(), endTime);

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

        return new ReportResult(test, rtk, deviceCode, stats, excludeSuspect, scatter);
    }

    public ComparisonResult generateComparison(Long rtkPointId) {
        RtkReferencePoint rtk = rtkPointRepository.findById(rtkPointId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "RTK point not found: " + rtkPointId));

        List<ComparisonEntry> entries = new ArrayList<>();
        for (GpsQualityTest test : testRepository.findByRtkPointId(rtkPointId)) {
            Long deviceId = test.getDeviceId();
            if (deviceId == null) continue;

            String code = test.getDeviceCode();
            if (code == null) {
                code = deviceRepository.findById(deviceId)
                        .map(Device::getDeviceCode).orElse(null);
            }
            Instant endTime2 = test.getEndedAt() != null ? test.getEndedAt() : Instant.now();
            List<GpsPointWithTelemetry> points = gpsLogRepository.findByDeviceIdAndTimeRangeWithTelemetry(
                    deviceId, test.getStartedAt(), endTime2);
            GpsQualityStats stats = calculator.calculate(points, rtk.getLatitude(), rtk.getLongitude(), true);
            entries.add(new ComparisonEntry(test.getId(), deviceId, code, stats));
        }
        return new ComparisonResult(rtk, entries);
    }

    public record ScatterPoint(BigDecimal latitude, BigDecimal longitude, double error,
                               Instant recordedAt, boolean suspect) {}

    public record ReportResult(GpsQualityTest test, RtkReferencePoint rtk,
                               String deviceCode, GpsQualityStats stats, boolean excludeSuspect,
                               List<ScatterPoint> scatter) {}

    public record ComparisonEntry(Long testId, Long deviceId, String deviceCode, GpsQualityStats stats) {}

    public record ComparisonResult(RtkReferencePoint rtk, List<ComparisonEntry> entries) {}
}
