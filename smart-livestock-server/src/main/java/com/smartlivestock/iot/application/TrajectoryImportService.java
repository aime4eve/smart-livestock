package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.GpsLog;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.GpsQualityTrackPoint;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.port.dto.TrackPairCandidate;
import com.smartlivestock.iot.domain.port.dto.TrackPairResult;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTrackPointRepository;
import com.smartlivestock.iot.domain.service.TrajectoryPairingService;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryImportResultDto;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryParseResultDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.DateUtil;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.DateTimeParseException;
import java.time.format.SignStyle;
import java.time.temporal.ChronoField;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * RTK trajectory import for TRAJECTORY tests (NIX-22, spec §3/§4/§6).
 * <p>
 * File format (fixed column order, optional header): device EUI, collection
 * time, RTK lat/lng, optional device lat/lng. Rows without device coordinates
 * are paired against gps_logs by EUI + collection time (±tolerance, D3);
 * pairing is recomputed at import and persisted as a snapshot (D2).
 * <p>
 * Intentionally NOT @Transactional, same rationale as
 * {@link GpsQualityBatchImportService}: per-device saves must not poison a
 * shared Hibernate session.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TrajectoryImportService {

    private static final int MAX_ROWS = 5000;
    private static final String UTF8_BOM = "﻿";
    private static final DateTimeFormatter DT_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /** Same flexible datetime acceptance as the batch import (dash/slash, seconds optional). */
    private static final List<DateTimeFormatter> DT_FORMATS = List.of(
            flexibleDateTime('-'),
            flexibleDateTime('/'));

    private static DateTimeFormatter flexibleDateTime(char sep) {
        return new DateTimeFormatterBuilder()
                .appendPattern("yyyy").appendLiteral(sep)
                .appendValue(ChronoField.MONTH_OF_YEAR, 1, 2, SignStyle.NORMAL).appendLiteral(sep)
                .appendValue(ChronoField.DAY_OF_MONTH, 1, 2, SignStyle.NORMAL)
                .appendLiteral(' ')
                .appendValue(ChronoField.HOUR_OF_DAY, 1, 2, SignStyle.NORMAL).appendLiteral(':')
                .appendValue(ChronoField.MINUTE_OF_HOUR, 1, 2, SignStyle.NORMAL)
                .optionalStart().appendLiteral(':')
                .appendValue(ChronoField.SECOND_OF_MINUTE, 1, 2, SignStyle.NORMAL)
                .optionalEnd()
                .toFormatter();
    }

    private final DeviceRepository deviceRepository;
    private final GpsQualityTestRepository testRepository;
    private final GpsQualityTrackPointRepository trackPointRepository;
    private final DeviceApplicationService deviceApplicationService;
    private final GpsLogRepository gpsLogRepository;

    private final TrajectoryPairingService pairingService = new TrajectoryPairingService();

    // ------------------------------------------------------------------
    // Row model
    // ------------------------------------------------------------------

    /** Raw cell text of one file row (rowIndex counts data rows from 1, header excluded). */
    private record RawRow(int rowIndex, String eui, String collectedAt,
                          String rtkLat, String rtkLng, String devLat, String devLng) {}

    /** A row that passed field validation (not yet paired). */
    private record ValidRow(int rowIndex, Device device, Instant collectedAt,
                            BigDecimal rtkLat, BigDecimal rtkLng,
                            BigDecimal devLat, BigDecimal devLng) {}

    /** A validated row with its pairing outcome. */
    private record PairedRow(ValidRow row, TrackPairResult pair, Instant matchedRecordedAt) {}

    // ------------------------------------------------------------------
    // Parse preview (no persistence)
    // ------------------------------------------------------------------

    public TrajectoryParseResultDto parse(MultipartFile file, int toleranceSec, Long tenantId) {
        List<RawRow> rawRows = readRows(file);
        List<ValidRow> valid = new ArrayList<>();
        Set<String> autoRegistered = new java.util.LinkedHashSet<>();
        List<TrajectoryParseResultDto.Row> preview = validate(rawRows, tenantId, valid, autoRegistered);
        List<PairedRow> paired = pairAll(valid, toleranceSec);

        int filePaired = 0, logPaired = 0, unpaired = 0;
        Map<Integer, PairedRow> pairedByIndex = new HashMap<>();
        for (PairedRow p : paired) {
            pairedByIndex.put(p.row().rowIndex(), p);
            switch (p.pair().matchSource()) {
                case FILE -> filePaired++;
                case GPS_LOG -> logPaired++;
                case UNPAIRED -> unpaired++;
            }
        }

        // Merge pairing outcomes into the preview rows
        List<TrajectoryParseResultDto.Row> rows = new ArrayList<>(preview.size());
        for (TrajectoryParseResultDto.Row r : preview) {
            PairedRow p = pairedByIndex.get(r.rowNo());
            if (p == null) {
                rows.add(r); // INVALID row, keep as-is
            } else {
                rows.add(new TrajectoryParseResultDto.Row(
                        r.rowNo(), r.deviceEui(), r.collectedAt(),
                        r.rtkLatitude(), r.rtkLongitude(), r.deviceLatitude(), r.deviceLongitude(),
                        p.pair().matchSource().name(), null,
                        p.matchedRecordedAt(), p.pair().timeDiffSeconds()));
            }
        }

        TrajectoryParseResultDto dto = new TrajectoryParseResultDto();
        dto.setTotalRows(rawRows.size());
        dto.setValidRows(valid.size());
        dto.setInvalidRows(rawRows.size() - valid.size());
        dto.setDeviceCount((int) valid.stream().map(r -> r.device().getId()).distinct().count());
        dto.setFilePaired(filePaired);
        dto.setLogPaired(logPaired);
        dto.setUnpaired(unpaired);
        dto.setRows(rows);
        dto.setAutoRegisteredEuis(new ArrayList<>(autoRegistered));
        return dto;
    }

    // ------------------------------------------------------------------
    // Import (creates one TRAJECTORY test per device + pairing snapshot)
    // ------------------------------------------------------------------

    public TrajectoryImportResultDto importFile(MultipartFile file, int toleranceSec, Long tenantId) {
        List<RawRow> rawRows = readRows(file);
        List<ValidRow> valid = new ArrayList<>();
        Set<String> autoRegistered = new java.util.LinkedHashSet<>();
        validate(rawRows, tenantId, valid, autoRegistered);
        List<PairedRow> paired = pairAll(valid, toleranceSec);
        String fileName = file.getOriginalFilename() != null ? file.getOriginalFilename() : "trajectory";

        // Group by device, preserving first-seen order
        Map<Long, List<PairedRow>> byDevice = new LinkedHashMap<>();
        for (PairedRow p : paired) {
            byDevice.computeIfAbsent(p.row().device().getId(), k -> new ArrayList<>()).add(p);
        }

        List<TrajectoryImportResultDto.DeviceResult> devices = new ArrayList<>();
        int created = 0;
        int skipped = 0;

        for (List<PairedRow> deviceRows : byDevice.values()) {
            List<PairedRow> rows = deviceRows.stream()
                    .sorted(Comparator.comparing(p -> p.row().collectedAt()))
                    .toList();
            Device device = rows.get(0).row().device();
            Instant startedAt = rows.get(0).row().collectedAt();
            Instant endedAt = rows.get(rows.size() - 1).row().collectedAt();
            String eui = device.getDevEui() != null ? device.getDevEui() : device.getDeviceCode();

            int filePaired = 0, logPaired = 0, unpaired = 0;
            for (PairedRow p : rows) {
                switch (p.pair().matchSource()) {
                    case FILE -> filePaired++;
                    case GPS_LOG -> logPaired++;
                    case UNPAIRED -> unpaired++;
                }
            }

            // D7 dedup: same device + identical time window already imported
            if (testRepository.existsTrajectoryWindow(eui, startedAt, endedAt)) {
                skipped++;
                devices.add(new TrajectoryImportResultDto.DeviceResult(
                        eui, null, "SKIPPED_DUPLICATE",
                        rows.size(), filePaired, logPaired, unpaired));
                continue;
            }

           // Use the resolved device's code (not the raw EUI) as deviceCode.
           GpsQualityTest test = new GpsQualityTest(device.getDeviceCode(), TestType.TRAJECTORY, null, null, startedAt);
           test.setDeviceId(device.getId());
           test.setEndedAt(endedAt);
           test.setStatus("READY");
           test.setNote(fileName + " · ±" + toleranceSec + "s");
           GpsQualityTest saved = testRepository.save(test);

            List<GpsQualityTrackPoint> points = new ArrayList<>(rows.size());
            int seq = 1;
            for (PairedRow p : rows) {
                GpsQualityTrackPoint point = new GpsQualityTrackPoint();
                point.setTestId(saved.getId());
                point.setSequenceNo(seq++);
                point.setCollectedAt(p.row().collectedAt());
                point.setRtkLatitude(p.row().rtkLat());
                point.setRtkLongitude(p.row().rtkLng());
                point.setDeviceLatitude(p.pair().deviceLatitude());
                point.setDeviceLongitude(p.pair().deviceLongitude());
                point.setMatchSource(p.pair().matchSource());
                point.setMatchedGpsLogId(p.pair().matchedGpsLogId());
                point.setTimeDiffSeconds(p.pair().timeDiffSeconds());
                point.setToleranceSeconds(toleranceSec);
                points.add(point);
            }
            trackPointRepository.saveAll(points);

            created++;
            devices.add(new TrajectoryImportResultDto.DeviceResult(
                    eui, saved.getId(), "CREATED",
                    rows.size(), filePaired, logPaired, unpaired));
        }

        TrajectoryImportResultDto dto = new TrajectoryImportResultDto();
        dto.setCreatedCount(created);
        dto.setSkippedCount(skipped);
        dto.setDevices(devices);
        dto.setAutoRegisteredCount(autoRegistered.size());
        return dto;
    }

    // ------------------------------------------------------------------
    // CSV template
    // ------------------------------------------------------------------

    public byte[] generateTemplate() {
        // BOM first so Excel opens the CSV as UTF-8
        String csv = UTF8_BOM + "设备EUI,采集时间,RTK纬度,RTK经度,设备纬度(可选),设备经度(可选)\n"
                + "A84041CEFE380733,2026-07-21 09:00:00,28.2284100,112.9387600,28.2283900,112.9387100\n"
                + "A84041CEFE380733,2026-07-21 09:30:05,28.2289000,112.9392100,,\n";
        return csv.getBytes(StandardCharsets.UTF_8);
    }

    // ------------------------------------------------------------------
    // Validation pass: raw rows → valid rows + INVALID preview rows
    // ------------------------------------------------------------------

    private List<TrajectoryParseResultDto.Row> validate(List<RawRow> rawRows, Long tenantId,
                                                        List<ValidRow> validOut,
                                                        Set<String> autoRegisteredOut) {
        List<TrajectoryParseResultDto.Row> preview = new ArrayList<>(rawRows.size());
        Map<String, Device> deviceCache = new HashMap<>();
        Set<String> seen = new HashSet<>();

        for (RawRow raw : rawRows) {
            String eui = raw.eui() != null ? raw.eui().trim() : "";
            String error = null;
            Device device = null;
            Instant collectedAt = null;
            BigDecimal rtkLat = null, rtkLng = null, devLat = null, devLng = null;

            // --- field validation (first failure wins) ---
            if (eui.isEmpty()) {
                error = "EUI 为空";
           } else {
                device = resolveDevice(deviceCache, eui, tenantId, autoRegisteredOut);
                if (device == null) error = "自动注册失败";
            }
            if (error == null) {
                try {
                    collectedAt = parseDateTime(raw.collectedAt());
                } catch (ApiException e) {
                    error = "时间格式错误";
                }
            }
            if (error == null) {
                rtkLat = parseCoordinate(raw.rtkLat(), -90, 90);
                rtkLng = parseCoordinate(raw.rtkLng(), -180, 180);
                if (rtkLat == null || rtkLng == null) error = "RTK 坐标格式错误或越界";
            }
            if (error == null) {
                boolean hasLat = raw.devLat() != null && !raw.devLat().isBlank();
                boolean hasLng = raw.devLng() != null && !raw.devLng().isBlank();
                if (hasLat != hasLng) {
                    error = "设备经纬度须同时填写或同时留空";
                } else if (hasLat) {
                    devLat = parseCoordinate(raw.devLat(), -90, 90);
                    devLng = parseCoordinate(raw.devLng(), -180, 180);
                    if (devLat == null || devLng == null) error = "设备坐标格式错误或越界";
                }
            }
            if (error == null && !seen.add(eui + "@" + collectedAt)) {
                error = "重复行（同设备同采集时间）";
            }

            if (error != null) {
                preview.add(new TrajectoryParseResultDto.Row(
                        raw.rowIndex(), eui, collectedAt, rtkLat, rtkLng, devLat, devLng,
                        "INVALID", error, null, null));
            } else {
                validOut.add(new ValidRow(raw.rowIndex(), device, collectedAt,
                        rtkLat, rtkLng, devLat, devLng));
                // Placeholder; pairing outcome merged in during parse()
                preview.add(new TrajectoryParseResultDto.Row(
                        raw.rowIndex(), eui, collectedAt, rtkLat, rtkLng, devLat, devLng,
                        null, null, null, null));
            }
        }
        return preview;
    }

    // ------------------------------------------------------------------
    // Pairing pass: per-device candidates loaded once over the full window
    // ------------------------------------------------------------------

    private List<PairedRow> pairAll(List<ValidRow> valid, int toleranceSec) {
        // Per-device time bounds so the gps_logs window is exact (no N+1, no truncation)
        Map<Long, Instant> minByDevice = new HashMap<>();
        Map<Long, Instant> maxByDevice = new HashMap<>();
        for (ValidRow r : valid) {
            if (r.devLat() != null) continue; // FILE rows need no candidates
            Long id = r.device().getId();
            minByDevice.merge(id, r.collectedAt(), (a, b) -> a.isBefore(b) ? a : b);
            maxByDevice.merge(id, r.collectedAt(), (a, b) -> a.isAfter(b) ? a : b);
        }

        Map<Long, List<TrackPairCandidate>> candidatesByDevice = new HashMap<>();
        Map<Long, Map<Long, Instant>> recordedAtByLogId = new HashMap<>();
        for (Map.Entry<Long, Instant> entry : minByDevice.entrySet()) {
            Long deviceId = entry.getKey();
            Instant from = entry.getValue().minusSeconds(toleranceSec);
            Instant to = maxByDevice.get(deviceId).plusSeconds(toleranceSec);
            List<GpsLog> logs = gpsLogRepository.findByDeviceIdAndRecordedAtBetween(deviceId, from, to);
            candidatesByDevice.put(deviceId, logs.stream().map(this::toCandidate).toList());
            Map<Long, Instant> byId = new HashMap<>();
            for (GpsLog log : logs) {
                byId.put(log.getId(), log.getRecordedAt());
            }
            recordedAtByLogId.put(deviceId, byId);
        }

        List<PairedRow> paired = new ArrayList<>(valid.size());
        for (ValidRow r : valid) {
            List<TrackPairCandidate> candidates = r.devLat() != null
                    ? List.of()
                    : candidatesByDevice.getOrDefault(r.device().getId(), List.of());
            TrackPairResult pair = pairingService.pair(
                    r.collectedAt(), r.devLat(), r.devLng(), candidates, toleranceSec);
            Instant matchedAt = pair.matchedGpsLogId() != null
                    ? recordedAtByLogId.getOrDefault(r.device().getId(), Map.of())
                            .get(pair.matchedGpsLogId())
                    : null;
            paired.add(new PairedRow(r, pair, matchedAt));
        }
        return paired;
    }

    private Device resolveDevice(Map<String, Device> cache, String eui, Long tenantId,
                                 Set<String> autoRegisteredOut) {
        if (cache.containsKey(eui)) {
            return cache.get(eui);
        }
        Device existing = deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(eui, tenantId).stream()
                .filter(d -> d.getDeletedAt() == null)
                .findFirst()
                .orElse(null);
        if (existing != null) {
            cache.put(eui, existing);
            return existing;
        }
        try {
            var dto = deviceApplicationService.findOrCreateByEui(eui, null, tenantId);
            Device created = deviceRepository.findById(dto.id()).orElse(null);
            if (created != null) {
                cache.put(eui, created);
                autoRegisteredOut.add(eui);
                return created;
            }
        } catch (Exception e) {
            log.warn("Auto-registration failed for EUI {}: {}", eui, e.getMessage());
        }
        return null;
    }

    private TrackPairCandidate toCandidate(GpsLog log) {
        return new TrackPairCandidate(log.getId(), log.getLatitude(), log.getLongitude(), log.getRecordedAt());
    }

    // ------------------------------------------------------------------
    // File reading (xlsx via POI, csv via lightweight parser)
    // ------------------------------------------------------------------

    private List<RawRow> readRows(MultipartFile file) {
        String name = file.getOriginalFilename() != null ? file.getOriginalFilename().toLowerCase() : "";
        List<List<String>> grid;
        try {
            if (name.endsWith(".xlsx")) {
                grid = readXlsx(file);
            } else if (name.endsWith(".csv")) {
                grid = parseCsv(new String(file.getBytes(), StandardCharsets.UTF_8));
            } else {
                throw new ApiException(ErrorCode.VALIDATION_ERROR,
                        "Unsupported file type (expected .csv or .xlsx): " + name);
            }
        } catch (IOException e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR, "Failed to read file: " + e.getMessage());
        }

        List<RawRow> rows = new ArrayList<>();
        int dataRow = 0;
        for (List<String> cells : grid) {
            boolean blank = cells.stream().allMatch(c -> c == null || c.isBlank());
            if (blank) continue;
            // Header auto-detection: RTK latitude/longitude columns are not numeric
            if (dataRow == 0 && parseCoordinate(cell(cells, 2), -90, 90) == null
                    && parseCoordinate(cell(cells, 3), -180, 180) == null) {
                dataRow++; // skip header, keep row numbering consistent
                continue;
            }
            dataRow++;
            rows.add(new RawRow(dataRow, cell(cells, 0), cell(cells, 1), cell(cells, 2),
                    cell(cells, 3), cell(cells, 4), cell(cells, 5)));
            if (rows.size() > MAX_ROWS) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR,
                        "Too many rows: " + rows.size() + " (max " + MAX_ROWS + ")");
            }
        }
        return rows;
    }

    private List<List<String>> readXlsx(MultipartFile file) throws IOException {
        List<List<String>> grid = new ArrayList<>();
        try (Workbook wb = new XSSFWorkbook(file.getInputStream())) {
            Sheet sheet = wb.getSheetAt(0);
            for (Row row : sheet) {
                List<String> cells = new ArrayList<>(6);
                for (int c = 0; c < 6; c++) {
                    cells.add(cellString(row.getCell(c)));
                }
                grid.add(cells);
            }
        }
        return grid;
    }

    /** Minimal CSV parser: comma separated, double-quoted fields, escaped quotes. */
    private List<List<String>> parseCsv(String content) {
        List<List<String>> rows = new ArrayList<>();
        List<String> current = new ArrayList<>();
        StringBuilder field = new StringBuilder();
        boolean inQuotes = false;
        for (int i = 0; i < content.length(); i++) {
            char c = content.charAt(i);
            if (inQuotes) {
                if (c == '"') {
                    if (i + 1 < content.length() && content.charAt(i + 1) == '"') {
                        field.append('"');
                        i++;
                    } else {
                        inQuotes = false;
                    }
                } else {
                    field.append(c);
                }
            } else if (c == '"') {
                inQuotes = true;
            } else if (c == ',') {
                current.add(field.toString());
                field.setLength(0);
            } else if (c == '\n' || c == '\r') {
                if (c == '\r' && i + 1 < content.length() && content.charAt(i + 1) == '\n') i++;
                current.add(field.toString());
                field.setLength(0);
                rows.add(current);
                current = new ArrayList<>();
            } else {
                field.append(c);
            }
        }
        if (field.length() > 0 || !current.isEmpty()) {
            current.add(field.toString());
            rows.add(current);
        }
        return rows;
    }

    private static String cell(List<String> cells, int index) {
        String v = index < cells.size() ? cells.get(index) : null;
        return v != null ? v.trim().replace(UTF8_BOM, "") : null;
    }

    private static String cellString(org.apache.poi.ss.usermodel.Cell cell) {
        if (cell == null) return null;
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue();
            case NUMERIC -> DateUtil.isCellDateFormatted(cell)
                    ? cell.getLocalDateTimeCellValue().format(DT_FMT)
                    : BigDecimal.valueOf(cell.getNumericCellValue()).toPlainString();
            default -> null;
        };
    }

    // ------------------------------------------------------------------
    // Scalar parsing helpers
    // ------------------------------------------------------------------

    /** Parse a datetime using the same raw-value basis as GPS logs (lesson #17).
     *  <p>
     *  The collection time in the CSV is a local (UTC+8) clock value, but GPS
     *  logs from blade are also stored at face value (no timezone conversion).
     *  To pair correctly, both sides must share the same basis, so we parse the
     *  CSV time as-is (UTC) — matching how blade reportTime is stored.
     */
    private Instant parseDateTime(String str) {
        if (str == null || str.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "empty datetime");
        }
        String value = str.trim();
        for (DateTimeFormatter fmt : DT_FORMATS) {
            try {
                return LocalDateTime.parse(value, fmt).toInstant(ZoneOffset.UTC);
            } catch (DateTimeParseException ignored) {
                // try the next format
            }
        }
        try {
            return Instant.parse(value);
        } catch (DateTimeParseException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Invalid datetime format: '" + str + "'");
        }
    }

    private static BigDecimal parseCoordinate(String raw, double min, double max) {
        if (raw == null || raw.isBlank()) return null;
        try {
            BigDecimal v = new BigDecimal(raw.trim());
            if (v.doubleValue() < min || v.doubleValue() > max) return null;
            return v;
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
