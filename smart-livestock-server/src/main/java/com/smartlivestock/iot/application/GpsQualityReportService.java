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
import java.time.temporal.ChronoUnit;
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

    /**
     * GPS recorded_at values come from the blade platform's reportTime, which
     * is a Beijing-time (UTC+8) number stored without a timezone designator.
     * The platform sync treats these as plain UTC, so recorded_at values run
     * ~8 h ahead of the server's true UTC clock. When endedAt is null we must
     * shift the upper bound forward by the same offset, otherwise the query
     * window misses data that the platform has already delivered.
     */
    private static final int PLATFORM_TZ_OFFSET_HOURS = 8;

    /**
     * Scatter only feeds a chart — beyond ~1k points the plot is visually
     * saturated while the payload (and its client-side JSON parse) keeps
     * growing with every synced frame. Statistics are always computed over
     * the FULL point set; only the returned scatter is decimated.
     */
    static final int MAX_SCATTER_POINTS = 1000;

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
       String deviceEui = null;
       // deviceCode may be denormalized on the test, but EUI always comes
       // from the Device entity, so resolve it whenever deviceId is present.
       if (deviceId != null) {
           Device device = deviceRepository.findById(deviceId).orElse(null);
           if (device != null) {
               if (deviceCode == null) deviceCode = device.getDeviceCode();
               deviceEui = device.getDevEui();
           }
       }

       Instant endTime = resolveReportWindowEnd(test.getDeviceId(), test.getStartedAt(), test.getEndedAt());
        List<GpsPointWithTelemetry> points = gpsLogRepository.findByDeviceIdAndTimeRangeWithTelemetry(
                deviceId, test.getStartedAt(), endTime);

        GpsQualityStats stats = calculator.calculate(
                points, rtk.getLatitude(), rtk.getLongitude(), excludeSuspect);

        List<ScatterPoint> scatter = downsample(points.stream()
                .map(p -> new ScatterPoint(
                        p.latitude(),
                        p.longitude(),
                        calculator.distance(rtk.getLatitude(), rtk.getLongitude(), p.latitude(), p.longitude()),
                        p.recordedAt(),
                        p.stepNumber() != null && p.stepNumber() > 0))
                .toList(), MAX_SCATTER_POINTS);

        return new ReportResult(test, rtk, deviceCode, deviceEui, stats, excludeSuspect, scatter);
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
           Instant endTime2 = resolveReportWindowEnd(test.getDeviceId(), test.getStartedAt(), test.getEndedAt());
           List<GpsPointWithTelemetry> points = gpsLogRepository.findByDeviceIdAndTimeRangeWithTelemetry(
                   deviceId, test.getStartedAt(), endTime2);
            GpsQualityStats stats = calculator.calculate(points, rtk.getLatitude(), rtk.getLongitude(), true);
            entries.add(new ComparisonEntry(test.getId(), deviceId, code, stats));
        }
        return new ComparisonResult(rtk, entries);
    }

    /**
     * Open-ended checks used to scan up to now+offset, so reports grew (and
     * slowed) forever as the device kept reporting. Cap the fallback at the
     * device's last known point + the platform offset: blade reportTime runs
     * ~8h ahead of true UTC, so every frame the platform has delivered stays
     * inside, while an 8h reporting gap ends the window instead of silently
     * absorbing future data.
     */
    private Instant resolveReportWindowEnd(Long deviceId, Instant startedAt, Instant endedAt) {
        if (endedAt != null) return endedAt;
        if (deviceId == null) return startedAt.plus(PLATFORM_TZ_OFFSET_HOURS, ChronoUnit.HOURS);
        return gpsLogRepository.findLastRecordedAtAtOrAfter(deviceId, startedAt)
                .map(ts -> ts.plus(PLATFORM_TZ_OFFSET_HOURS, ChronoUnit.HOURS))
                .orElseGet(() -> startedAt.plus(PLATFORM_TZ_OFFSET_HOURS, ChronoUnit.HOURS));
    }

    /** Even-stride decimation keeping the first and last point. */
    static <T> List<T> downsample(List<T> points, int maxPoints) {
        int n = points.size();
        if (n <= maxPoints || maxPoints < 2) return points;
        List<T> out = new ArrayList<>(maxPoints);
        double stride = (double) (n - 1) / (maxPoints - 1);
        for (int i = 0; i < maxPoints; i++) {
            out.add(points.get((int) Math.round(i * stride)));
        }
        return out;
    }

    public record ScatterPoint(BigDecimal latitude, BigDecimal longitude, double error,
                               Instant recordedAt, boolean suspect) {}

    public record ReportResult(GpsQualityTest test, RtkReferencePoint rtk,
                               String deviceCode, String deviceEui, GpsQualityStats stats, boolean excludeSuspect,
                               List<ScatterPoint> scatter) {}

    public record ComparisonEntry(Long testId, Long deviceId, String deviceCode, GpsQualityStats stats) {}

    public record ComparisonResult(RtkReferencePoint rtk, List<ComparisonEntry> entries) {}
}
