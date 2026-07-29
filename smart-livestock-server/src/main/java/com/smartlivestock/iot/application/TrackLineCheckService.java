package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.GpsLog;
import com.smartlivestock.iot.domain.model.GpsQualityLineDeviation;
import com.smartlivestock.iot.domain.model.GpsQualityLinePoint;
import com.smartlivestock.iot.domain.model.GpsQualityLineResult;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.model.StandardTrackLine;
import com.smartlivestock.iot.domain.model.StandardTrackLinePoint;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.port.dto.LineQualityStats;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityLineDeviationRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityLinePointRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityLineResultRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.domain.repository.StandardTrackLinePointRepository;
import com.smartlivestock.iot.domain.repository.StandardTrackLineRepository;
import com.smartlivestock.iot.domain.service.TrackLineCalculator;
import com.smartlivestock.iot.interfaces.admin.dto.LineCheckCreateResultDto;
import com.smartlivestock.iot.interfaces.admin.dto.LineCheckDeviceDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * LINE check creation (NIX-68, spec §7.3): lists devices having any gps_logs
 * data, then creates one READY LINE test per device — point-list snapshot +
 * synchronous spatial matching (corridor + trip segmentation, no time
 * window) + result snapshot (D4).
 * <p>
 * Synchronous by design (spec §6.5 load estimate: worst case &lt;10s, no
 * DEVICE_PENDING flow). Intentionally NOT @Transactional, same rationale as
 * {@link TrajectoryImportService}: per-device saves must not poison a shared
 * Hibernate session.
 */
@Service
@RequiredArgsConstructor
public class TrackLineCheckService {

    private final DeviceRepository deviceRepository;
    private final GpsLogRepository gpsLogRepository;
    private final GpsQualityTestRepository testRepository;
    private final StandardTrackLineRepository trackLineRepository;
    private final StandardTrackLinePointRepository trackLinePointRepository;
    private final GpsQualityLinePointRepository linePointRepository;
    private final GpsQualityLineResultRepository lineResultRepository;
    private final GpsQualityLineDeviationRepository lineDeviationRepository;

    private final TrackLineCalculator calculator = new TrackLineCalculator();

    /**
     * Refresh all LINE tests for one standard track: delete every existing
     * LINE test (+ snapshots) for this trackLine, then re-create tests for all
     * devices that currently have gps_logs data. Returns the creation result.
     */
    @Transactional
    public LineCheckCreateResultDto refreshLineChecks(Long trackLineId) {
        // Validate the track line exists before deleting anything.
        trackLineRepository.findById(trackLineId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Standard track line not found: " + trackLineId));

        // Delete old LINE tests and their snapshots for this track line.
        for (GpsQualityTest old : testRepository.findByTrackLineIdOrderByStartedAt(trackLineId)) {
            if (old.getTestType() != TestType.LINE) continue;
            linePointRepository.deleteByTestId(old.getId());
            lineResultRepository.deleteByTestId(old.getId());
            lineDeviationRepository.deleteByTestId(old.getId());
            testRepository.deleteById(old.getId());
        }

        // Re-create tests for all devices that currently have gps_logs data.
       List<String> deviceCodes = findDevicesWithLogs().stream()
                .map(LineCheckDeviceDto::deviceCode)
               .toList();
        if (deviceCodes.isEmpty()) {
            LineCheckCreateResultDto dto = new LineCheckCreateResultDto();
            dto.setDevices(List.of());
            return dto;
        }
        return createLineChecks(trackLineId, deviceCodes);
    }

    /**
     * Devices having at least one gps_logs report (no time window),
     * with point count and first/last report time.
     */
    public List<LineCheckDeviceDto> findDevicesWithLogs() {
        List<LineCheckDeviceDto> devices = new ArrayList<>();
        for (Device device : deviceRepository.findAllTrackers()) {
            List<GpsLog> logs = sortedLogs(device.getId());
            if (logs.isEmpty()) continue;
            devices.add(new LineCheckDeviceDto(
                    device.getDeviceCode(), device.getId(), logs.size(),
                    logs.get(0).getRecordedAt(), logs.get(logs.size() - 1).getRecordedAt()));
        }
        return devices;
    }

    /**
     * Create one LINE test per device: snapshot the standard track points,
     * spatially match the device's full report history against the polyline
     * (corridor + trip segmentation), and snapshot statistics + grade.
     * Devices without any gps_logs are skipped (no test created). All created
     * tests are READY on return.
     */
    public LineCheckCreateResultDto createLineChecks(Long trackLineId, List<String> deviceCodes) {
        StandardTrackLine line = trackLineRepository.findById(trackLineId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Standard track line not found: " + trackLineId));
        List<StandardTrackLinePoint> trackPoints =
                trackLinePointRepository.findByLineIdOrderBySequenceNo(trackLineId);
        if (trackPoints.size() < 2) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "Standard track line " + trackLineId + " has fewer than 2 points");
        }
        List<TrackLineCalculator.LinePoint> polyline = trackPoints.stream()
                .map(p -> new TrackLineCalculator.LinePoint(
                        p.getLatitude().doubleValue(), p.getLongitude().doubleValue()))
                .toList();

        List<LineCheckCreateResultDto.DeviceResult> results = new ArrayList<>();
        for (String deviceCode : deviceCodes) {
            Device device = deviceRepository.findByDeviceCode(deviceCode)
                    .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                            "Device not found: " + deviceCode));
            List<GpsLog> logs = sortedLogs(device.getId());
            if (logs.isEmpty()) {
                // Nothing to analyze; no test is created for this device.
                results.add(new LineCheckCreateResultDto.DeviceResult(
                        null, device.getDeviceCode(), 0, QualityGrade.UNAVAILABLE.name()));
                continue;
            }

            List<TrackLineCalculator.TrackSample> samples = logs.stream()
                    .map(l -> new TrackLineCalculator.TrackSample(l.getRecordedAt(),
                            l.getLatitude().doubleValue(), l.getLongitude().doubleValue()))
                    .toList();
            TrackLineCalculator.LineMatch match = calculator.matchLine(polyline, samples);
            List<TrackLineCalculator.MatchedPoint> matched = match.points();

            // Test window = first/last matched sample; started_at is NOT NULL,
            // so without valid segments fall back to the device's data span.
            Instant startedAt = !matched.isEmpty()
                    ? matched.get(0).sample().recordedAt()
                    : logs.get(0).getRecordedAt();
            Instant endedAt = !matched.isEmpty()
                    ? matched.get(matched.size() - 1).sample().recordedAt()
                    : logs.get(logs.size() - 1).getRecordedAt();

            GpsQualityTest test = new GpsQualityTest(
                    device.getDeviceCode(), TestType.LINE, null, null, trackLineId, startedAt);
            test.setDeviceId(device.getId());
            test.setEndedAt(endedAt);
            test.setStatus("READY");
            test.setNote(line.getName()); // snapshot-time track name (spec §6.1)
            GpsQualityTest saved = testRepository.save(test);

            // D4: point-list snapshot at test creation time
            List<GpsQualityLinePoint> snapshot = new ArrayList<>(trackPoints.size());
            int seq = 1;
            for (StandardTrackLinePoint tp : trackPoints) {
                GpsQualityLinePoint p = new GpsQualityLinePoint();
                p.setTestId(saved.getId());
                p.setSequenceNo(seq++);
                p.setLongitude(tp.getLongitude());
                p.setLatitude(tp.getLatitude());
                snapshot.add(p);
            }
            linePointRepository.saveAll(snapshot);

            // Deviation snapshot: only the valid trip-segment points
            List<GpsQualityLineDeviation> deviations = new ArrayList<>(matched.size());
            int devSeq = 1;
            for (TrackLineCalculator.MatchedPoint p : matched) {
                GpsQualityLineDeviation d = new GpsQualityLineDeviation();
                d.setTestId(saved.getId());
                d.setSequenceNo(devSeq++);
                d.setRecordedAt(p.sample().recordedAt());
                d.setLongitude(BigDecimal.valueOf(p.sample().longitude()));
                d.setLatitude(BigDecimal.valueOf(p.sample().latitude()));
                d.setDeviationM(BigDecimal.valueOf(p.deviationMeters())
                        .setScale(2, RoundingMode.HALF_UP));
                d.setSegmentNo(p.segmentNo());
                deviations.add(d);
            }
            lineDeviationRepository.saveAll(deviations);

            LineQualityStats stats = match.stats();
            QualityGrade grade = calculator.determineLineGrade(stats);

            GpsQualityLineResult result = new GpsQualityLineResult();
            result.setTestId(saved.getId());
            result.setSampleCount(stats.sampleCount());
            result.setTripCount(stats.tripCount());
            result.setMeanDeviationM(decimal2(stats.meanDeviation()));
            result.setP50M(decimal2(stats.p50()));
            result.setP95M(decimal2(stats.p95()));
            result.setMaxDeviationM(decimal2(stats.maxDeviation()));
            result.setWithin15mPct(decimal1(stats.within15mPct()));
            result.setWithin25mPct(decimal1(stats.within25mPct()));
            result.setWithin40mPct(decimal1(stats.within40mPct()));
            result.setGrade(grade.name());
            if (!matched.isEmpty()) {
                result.setFirstRecordedAt(matched.get(0).sample().recordedAt());
                result.setLastRecordedAt(matched.get(matched.size() - 1).sample().recordedAt());
            }
            lineResultRepository.save(result);

            results.add(new LineCheckCreateResultDto.DeviceResult(
                    saved.getId(), device.getDeviceCode(), stats.sampleCount(), grade.name()));
        }

        LineCheckCreateResultDto dto = new LineCheckCreateResultDto();
        dto.setDevices(results);
        return dto;
    }

    private List<GpsLog> sortedLogs(Long deviceId) {
        return gpsLogRepository.findByDeviceId(deviceId).stream()
                .sorted(Comparator.comparing(GpsLog::getRecordedAt))
                .toList();
    }

    private static BigDecimal decimal2(double v) {
        return BigDecimal.valueOf(v).setScale(2, RoundingMode.HALF_UP);
    }

    private static BigDecimal decimal1(double v) {
        return BigDecimal.valueOf(v).setScale(1, RoundingMode.HALF_UP);
    }
}
