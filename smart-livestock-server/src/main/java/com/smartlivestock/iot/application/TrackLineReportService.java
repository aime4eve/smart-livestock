package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.GpsQualityLineDeviation;
import com.smartlivestock.iot.domain.model.GpsQualityLineResult;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.QualityGrade;
import com.smartlivestock.iot.domain.model.StandardTrackLine;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.repository.GpsQualityLineDeviationRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityLinePointRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityLineResultRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.domain.repository.StandardTrackLinePointRepository;
import com.smartlivestock.iot.domain.repository.StandardTrackLineRepository;
import com.smartlivestock.iot.interfaces.admin.dto.CheckSummaryDto;
import com.smartlivestock.iot.interfaces.admin.dto.DynamicQualityReportDto;
import com.smartlivestock.iot.interfaces.admin.dto.LineComparisonDto;
import com.smartlivestock.iot.interfaces.admin.dto.LineDeviationDto;
import com.smartlivestock.iot.interfaces.admin.dto.LineQualityReportDto;
import com.smartlivestock.iot.interfaces.admin.dto.LineTrackPointDto;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryQualityReportDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * LINE reports, unified per-device summary and cross-device line comparison
 * (NIX-68, spec §7.4-§7.6). Everything reads the D4 snapshots — gps_logs is
 * never re-queried.
 */
@Service
@RequiredArgsConstructor
public class TrackLineReportService {

    private final GpsQualityTestRepository testRepository;
    private final GpsQualityLinePointRepository linePointRepository;
    private final GpsQualityLineResultRepository lineResultRepository;
    private final GpsQualityLineDeviationRepository lineDeviationRepository;
    private final StandardTrackLineRepository trackLineRepository;
    private final StandardTrackLinePointRepository trackLinePointRepository;
    private final GpsQualityReportService staticReportService;
    private final DynamicQualityReportService dynamicReportService;
    private final TrajectoryReportService trajectoryReportService;

    // ------------------------------------------------------------------
    // LINE report (spec §7.4): summary + track/deviations sub-resources
    // ------------------------------------------------------------------

    public LineQualityReportDto generateLineReport(Long testId) {
        GpsQualityTest test = requireLineTest(testId);
        GpsQualityLineResult result = lineResultRepository.findByTestId(testId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "LINE result snapshot not found for test: " + testId));

        LineQualityReportDto dto = new LineQualityReportDto();
        dto.setTestId(test.getId());
        dto.setDeviceCode(test.getDeviceCode());
        dto.setStartedAt(test.getStartedAt());
        dto.setEndedAt(test.getEndedAt());
        dto.setTrackLineId(test.getTrackLineId());
        dto.setTrackLineName(test.getNote()); // snapshot-time name survives candidate deletion
        dto.setGrade(QualityGrade.valueOf(result.getGrade()));
        dto.setSampleCount(result.getSampleCount());
        dto.setTripCount(result.getTripCount() != null ? result.getTripCount() : 0);
        dto.setMeanDeviation(result.getMeanDeviationM().doubleValue());
        dto.setP50(result.getP50M().doubleValue());
        dto.setP95(result.getP95M().doubleValue());
        dto.setMaxDeviation(result.getMaxDeviationM().doubleValue());
        dto.setWithin15mPct(result.getWithin15mPct().doubleValue());
        dto.setWithin25mPct(result.getWithin25mPct().doubleValue());
        dto.setWithin40mPct(result.getWithin40mPct().doubleValue());
        return dto;
    }

    /** Standard track point-list snapshot of a LINE test (map green line). */
    public List<LineTrackPointDto> getTrack(Long testId) {
        requireLineTest(testId);
        return linePointRepository.findByTestIdOrderBySequenceNo(testId).stream()
                .map(p -> new LineTrackPointDto(p.getSequenceNo(), p.getLongitude(), p.getLatitude()))
                .toList();
    }

    /** Per-point deviations of a LINE test, ascending by time; optional limit. */
    public List<LineDeviationDto> getDeviations(Long testId, Integer limit) {
        requireLineTest(testId);
        List<GpsQualityLineDeviation> deviations =
                lineDeviationRepository.findByTestIdOrderBySequenceNo(testId);
        if (limit != null && limit > 0 && deviations.size() > limit) {
            deviations = deviations.subList(0, limit);
        }
        return deviations.stream()
                .map(d -> new LineDeviationDto(d.getSequenceNo(), d.getRecordedAt(),
                        d.getLongitude(), d.getLatitude(), d.getDeviationM(), d.getSegmentNo()))
                .toList();
    }

    private GpsQualityTest requireLineTest(Long testId) {
        GpsQualityTest test = testRepository.findById(testId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "GPS quality test not found: " + testId));
        if (test.getTestType() != TestType.LINE) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "Test " + testId + " is not a LINE test (got " + test.getTestType() + ")");
        }
        return test;
    }

    // ------------------------------------------------------------------
    // Unified summary (spec §7.5): latest test per type for one device
    // ------------------------------------------------------------------

    public CheckSummaryDto summary(String deviceCode) {
        Map<TestType, GpsQualityTest> latestByType = new LinkedHashMap<>();
        for (GpsQualityTest t : testRepository.findByDeviceCodeOrderByStartedAt(deviceCode)) {
            if (!"READY".equals(t.getStatus())) continue;
            latestByType.merge(t.getTestType(), t, (a, b) -> {
                int cmp = a.getStartedAt().compareTo(b.getStartedAt());
                if (cmp != 0) return cmp > 0 ? a : b;
                return a.getId() >= b.getId() ? a : b;
            });
        }

        List<CheckSummaryDto.Item> items = new ArrayList<>();
        for (Map.Entry<TestType, GpsQualityTest> entry : latestByType.entrySet()) {
            CheckSummaryDto.Item item = buildSummaryItem(entry.getKey(), entry.getValue());
            if (item != null) items.add(item);
        }
        items.sort(Comparator.comparing(CheckSummaryDto.Item::checkType));

        CheckSummaryDto dto = new CheckSummaryDto();
        dto.setItems(items);
        return dto;
    }

    /** Best-effort metric assembly; a failing type is omitted, never fatal. */
    private CheckSummaryDto.Item buildSummaryItem(TestType type, GpsQualityTest test) {
        try {
            return switch (type) {
                case STATIC -> {
                    GpsQualityReportService.ReportResult r =
                            staticReportService.generate(test.getId(), true);
                    yield new CheckSummaryDto.Item(type.name(), test.getId(), test.getEndedAt(),
                            r.stats().grade() != null ? r.stats().grade().name() : null,
                            String.format(Locale.ROOT, "p95 %.1fm", r.stats().p95()));
                }
                case DYNAMIC -> {
                    DynamicQualityReportDto r = dynamicReportService.generate(test.getId(), null);
                    yield new CheckSummaryDto.Item(type.name(), test.getId(), test.getEndedAt(),
                            r.getGrade() != null ? r.getGrade().name() : null,
                            String.format(Locale.ROOT, "p95 %.1fm", r.getStats().p95()));
                }
                case TRAJECTORY -> {
                    TrajectoryQualityReportDto r = trajectoryReportService.generate(test.getId());
                    yield new CheckSummaryDto.Item(type.name(), test.getId(), test.getEndedAt(),
                            r.getGrade() != null ? r.getGrade().name() : null,
                            String.format(Locale.ROOT, "mean %.1fm · pair %.0f%%",
                                    r.getMeanError(), r.getPairRate()));
                }
                case LINE -> {
                    GpsQualityLineResult r = lineResultRepository.findByTestId(test.getId())
                            .orElse(null);
                    if (r == null) yield null;
                    yield new CheckSummaryDto.Item(type.name(), test.getId(), test.getEndedAt(),
                            r.getGrade(),
                            String.format(Locale.ROOT, "mean %.1fm · p95 %.1fm",
                                    r.getMeanDeviationM().doubleValue(), r.getP95M().doubleValue()));
                }
            };
        } catch (Exception ignored) {
            return null;
        }
    }

    // ------------------------------------------------------------------
    // Line comparison (spec §7.6): stats table + track, lazy device track
    // ------------------------------------------------------------------

    public LineComparisonDto comparison(Long trackLineId, String deviceCode) {
        StandardTrackLine line = trackLineRepository.findById(trackLineId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Standard track line not found: " + trackLineId));

        LineComparisonDto dto = new LineComparisonDto();
        dto.setTrackLine(trackLinePointRepository.findByLineIdOrderBySequenceNo(line.getId()).stream()
                .map(p -> new LineTrackPointDto(p.getSequenceNo(), p.getLongitude(), p.getLatitude()))
                .toList());

        // Latest READY LINE test per device on this standard track
        Map<String, GpsQualityTest> latestByDevice = new LinkedHashMap<>();
        for (GpsQualityTest t : testRepository.findByTrackLineIdOrderByStartedAt(trackLineId)) {
            if (!"READY".equals(t.getStatus())) continue;
            latestByDevice.merge(t.getDeviceCode(), t, (a, b) -> {
                int cmp = a.getStartedAt().compareTo(b.getStartedAt());
                if (cmp != 0) return cmp > 0 ? a : b;
                return a.getId() >= b.getId() ? a : b;
            });
        }

        List<LineComparisonDto.Row> rows = new ArrayList<>();
        for (GpsQualityTest t : latestByDevice.values()) {
            GpsQualityLineResult r = lineResultRepository.findByTestId(t.getId()).orElse(null);
            if (r == null) continue;
            rows.add(new LineComparisonDto.Row(
                    t.getId(), t.getDeviceCode(), r.getSampleCount(),
                    r.getTripCount() != null ? r.getTripCount() : 0,
                    r.getMeanDeviationM().doubleValue(), r.getP50M().doubleValue(),
                    r.getP95M().doubleValue(), r.getMaxDeviationM().doubleValue(),
                    r.getWithin15mPct().doubleValue(), r.getWithin25mPct().doubleValue(),
                    r.getWithin40mPct().doubleValue(), r.getGrade(),
                    t.getStartedAt(), t.getEndedAt()));
        }
        rows.sort(Comparator.comparing(LineComparisonDto.Row::deviceCode));
        dto.setRows(rows);

        // Device track points only on explicit request (lazy per-device loading)
        if (deviceCode != null && !deviceCode.isBlank()) {
            GpsQualityTest chosen = latestByDevice.get(deviceCode);
            dto.setDeviceTrack(chosen == null ? List.of()
                    : lineDeviationRepository.findByTestIdOrderBySequenceNo(chosen.getId()).stream()
                            .map(d -> new LineTrackPointDto(d.getSequenceNo(),
                                    d.getLongitude(), d.getLatitude()))
                            .toList());
        }
        return dto;
    }
}
