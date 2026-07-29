package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.port.IdentityQueryPort;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.FarmInfo;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.iot.domain.service.DecodedTrackerFrame;
import com.smartlivestock.iot.domain.service.TrackerPayloadDecoder;
import com.smartlivestock.iot.interfaces.admin.dto.TelemetryImportResultDto;
import com.smartlivestock.iot.interfaces.admin.dto.TelemetryParseResultDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoField;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Manual telemetry file import (NIX-79): backfills device history exported
 * from the blade platform (xlsx, columns: 数据类型/帧计数器/数据(hex)/RSSI/SNR/创建时间).
 * <p>
 * Two passes mirror {@link TrajectoryImportService}: {@link #parse} previews
 * with zero persistence, {@link #importFile} re-runs the same pipeline and
 * ingests IMPORTABLE rows one by one through
 * {@link TelemetryIngestionService#ingest} with {@link TelemetrySource#MANUAL_IMPORT}.
 * Intentionally NOT class-level @Transactional: each row's ingest carries its
 * own transaction so a single bad row never rolls back the file.
 * <p>
 * Row time is parsed at face value on the UTC baseline (lesson #17) and NEVER
 * falls back to now() (lesson #10) — an unparseable time makes the row INVALID.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TelemetryImportService {

    private static final int MAX_ROWS = 5000;
    private static final Pattern DEV_EUI_PREFIX = Pattern.compile("^([0-9A-Fa-f]{16})");
    private static final String UPLINK = "上行";
    private static final String HEADER_FIRST_COLUMN = "数据类型";

    /** yyyy-MM-dd HH:mm:ss with optional fraction (blade exports microseconds). */
    private static final DateTimeFormatter DT_FMT = new DateTimeFormatterBuilder()
            .appendPattern("yyyy-MM-dd HH:mm:ss")
            .optionalStart()
            .appendFraction(ChronoField.NANO_OF_SECOND, 1, 6, true)
            .optionalEnd()
            .toFormatter();

    /** Numeric-cell datetime fallback format (seconds precision is enough there). */
    private static final DateTimeFormatter CELL_DT_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final DeviceRepository deviceRepository;
    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final InstallationRepository installationRepository;
    private final RanchQueryPort ranchQueryPort;
    private final IdentityQueryPort identityQueryPort;
    private final TelemetryIngestionService telemetryIngestionService;

    // ------------------------------------------------------------------
    // Row model
    // ------------------------------------------------------------------

    /** Raw cell text of one file row (rowNo = spreadsheet row number, header is row 1). */
    private record RawRow(int rowNo, String dataType, String frameCounter, String hex,
                          String rssi, String snr, String createTime) {}

    private enum RowStatus { IMPORTABLE, DUPLICATE, SKIPPED_DOWNLINK, SKIPPED_UNSUPPORTED, INVALID }

    /** A classified row; readings/hasGps are populated for decoded rows. */
    private record ClassifiedRow(int rowNo, String frameCounter, Instant recordTime,
                                 Map<String, Object> readings, boolean hasGps,
                                 RowStatus status, String errorKey) {}

    /** Device match outcome; errorKey/errorArgs set when device is null or unusable. */
    private record DeviceMatch(Device device, String errorKey, Object[] errorArgs) {
        boolean matched() { return device != null && errorKey == null; }
    }

    // ------------------------------------------------------------------
    // Parse preview (no persistence)
    // ------------------------------------------------------------------

    public TelemetryParseResultDto parse(MultipartFile file, Long tenantId) {
        String devEui = extractDevEui(file);
        DeviceMatch match = matchDevice(devEui, tenantId);
        List<RawRow> rawRows = readRows(file);
        List<ClassifiedRow> classified = classifyAll(rawRows, match.matched() ? match.device() : null);

        int decodable = 0, importable = 0, gpsPoints = 0, duplicate = 0, skipped = 0, invalid = 0;
        List<TelemetryParseResultDto.Row> preview = new ArrayList<>(classified.size());
        for (ClassifiedRow row : classified) {
            switch (row.status()) {
                case IMPORTABLE -> {
                    importable++;
                    decodable++;
                    if (row.hasGps()) gpsPoints++;
                }
                case DUPLICATE -> { duplicate++; decodable++; }
                case INVALID -> invalid++;
                default -> skipped++;
            }
            preview.add(toPreviewRow(row));
        }
        int uplink = (int) rawRows.stream().filter(r -> UPLINK.equals(r.dataType())).count();

        TelemetryParseResultDto.DeviceMatchDto deviceDto = toDeviceMatchDto(devEui, match);
        return new TelemetryParseResultDto(
                rawRows.size(), uplink, decodable, importable, gpsPoints,
                duplicate, skipped, invalid, deviceDto, preview);
    }

    // ------------------------------------------------------------------
    // Import (per-row ingest, failures counted not rolled back)
    // ------------------------------------------------------------------

    public TelemetryImportResultDto importFile(MultipartFile file, Long tenantId) {
        String devEui = extractDevEui(file);
        DeviceMatch match = matchDevice(devEui, tenantId);
        if (!match.matched()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, match.errorKey(), match.errorArgs());
        }
        Device device = match.device();

        List<RawRow> rawRows = readRows(file);
        List<ClassifiedRow> classified = classifyAll(rawRows, device);

        int duplicate = 0, skipped = 0, invalid = 0, failed = 0, telemetryCreated = 0, gpsCreated = 0;
        List<ClassifiedRow> importable = new ArrayList<>();
        for (ClassifiedRow row : classified) {
            switch (row.status()) {
                case IMPORTABLE -> importable.add(row);
                case DUPLICATE -> duplicate++;
                case INVALID -> invalid++;
                default -> skipped++;
            }
        }
        importable.sort(Comparator.comparing(ClassifiedRow::recordTime));

        for (ClassifiedRow row : importable) {
            try {
                telemetryIngestionService.ingest(device.getId(), row.readings(),
                        row.recordTime(), TelemetrySource.MANUAL_IMPORT);
                telemetryCreated++;
                if (row.hasGps()) gpsCreated++;
            } catch (Exception e) {
                failed++;
                log.warn("Telemetry import row {} failed (device {}): {}", row.rowNo(), device.getId(), e.getMessage());
            }
        }

        return new TelemetryImportResultDto(telemetryCreated, gpsCreated, duplicate,
                skipped, invalid, failed, devEui, device.getDeviceCode());
    }

    // ------------------------------------------------------------------
    // File name → DevEUI → device match
    // ------------------------------------------------------------------

    private String extractDevEui(MultipartFile file) {
        String name = file.getOriginalFilename() != null ? file.getOriginalFilename() : "";
        Matcher m = DEV_EUI_PREFIX.matcher(name);
        if (!m.find()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.telemetryImport.badFileName");
        }
        return m.group(1);
    }

    /**
     * D4: the device must already be registered (no auto-registration), ACTIVE
     * (ingest rejects other states) and a TRACKER (D3: only cattle/sheep
     * tracker frames are decodable).
     */
    private DeviceMatch matchDevice(String devEui, Long tenantId) {
        Device device = deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(devEui, tenantId).stream()
                .filter(d -> d.getDeletedAt() == null)
                .findFirst()
                .orElse(null);
        if (device == null) {
            return new DeviceMatch(null, "error.telemetryImport.deviceNotRegistered", new Object[]{devEui});
        }
        if (device.getStatus() != DeviceStatus.ACTIVE) {
            return new DeviceMatch(device, "error.telemetryImport.deviceNotActive", new Object[]{devEui});
        }
        if (device.getDeviceType() != DeviceType.TRACKER) {
            return new DeviceMatch(device, "error.telemetryImport.unsupportedDeviceType",
                    new Object[]{device.getDeviceType() != null ? device.getDeviceType().name() : "null"});
        }
        return new DeviceMatch(device, null, null);
    }

    private TelemetryParseResultDto.DeviceMatchDto toDeviceMatchDto(String devEui, DeviceMatch match) {
        Device device = match.device();
        String livestockName = null;
        String farmName = null;
        if (match.matched()) {
            Installation installation = installationRepository.findActiveByDeviceId(device.getId()).orElse(null);
            if (installation != null) {
                LivestockInfo livestock = ranchQueryPort.findLivestockById(installation.getLivestockId()).orElse(null);
                if (livestock != null) {
                    livestockName = livestock.livestockCode();
                    FarmInfo farm = identityQueryPort.findFarmById(livestock.farmId()).orElse(null);
                    farmName = farm != null ? farm.name() : null;
                }
            }
        }
        return new TelemetryParseResultDto.DeviceMatchDto(
                match.matched(), devEui,
                device != null ? device.getDeviceCode() : null,
                device != null && device.getDeviceType() != null ? device.getDeviceType().name() : null,
                livestockName, farmName,
                match.errorKey());
    }

    // ------------------------------------------------------------------
    // Row classification (spec §4.2 priority order)
    // ------------------------------------------------------------------

    private List<ClassifiedRow> classifyAll(List<RawRow> rawRows, Device device) {
        List<ClassifiedRow> rows = new ArrayList<>(rawRows.size());
        for (RawRow raw : rawRows) {
            rows.add(classifyOne(raw));
        }

        // Duplicate pre-check: one range query over the file's time span, then
        // in-memory compare (device_telemetry_logs has a unique
        // (device_id, report_time) constraint but JPA save has no ON CONFLICT).
        Set<Instant> existing = new HashSet<>();
        if (device != null) {
            Instant min = null;
            Instant max = null;
            for (ClassifiedRow r : rows) {
                if (r.status() == RowStatus.IMPORTABLE) {
                    if (min == null || r.recordTime().isBefore(min)) min = r.recordTime();
                    if (max == null || r.recordTime().isAfter(max)) max = r.recordTime();
                }
            }
            if (min != null) {
                existing.addAll(deviceTelemetryLogRepository
                        .findReportTimesByDeviceIdAndReportTimeBetween(device.getId(), min, max));
            }
        }

        Set<Instant> seenInFile = new HashSet<>();
        List<ClassifiedRow> result = new ArrayList<>(rows.size());
        for (ClassifiedRow r : rows) {
            if (r.status() == RowStatus.IMPORTABLE
                    && (!seenInFile.add(r.recordTime()) || existing.contains(r.recordTime()))) {
                result.add(new ClassifiedRow(r.rowNo(), r.frameCounter(), r.recordTime(),
                        r.readings(), r.hasGps(), RowStatus.DUPLICATE, null));
            } else {
                result.add(r);
            }
        }
        return result;
    }

    private ClassifiedRow classifyOne(RawRow raw) {
        if (!UPLINK.equals(trimToNull(raw.dataType()))) {
            return new ClassifiedRow(raw.rowNo(), raw.frameCounter(), null,
                    null, false, RowStatus.SKIPPED_DOWNLINK, null);
        }
        byte[] payload = parseHex(raw.hex());
        if (payload == null) {
            return new ClassifiedRow(raw.rowNo(), raw.frameCounter(), null,
                    null, false, RowStatus.INVALID, "error.telemetryImport.invalidHex");
        }
        Instant recordTime = parseTime(raw.createTime());
        if (recordTime == null) {
            return new ClassifiedRow(raw.rowNo(), raw.frameCounter(), null,
                    null, false, RowStatus.INVALID, "error.telemetryImport.invalidTime");
        }
        Optional<DecodedTrackerFrame> decoded = TrackerPayloadDecoder.decode(payload);
        if (decoded.isEmpty()) {
            return new ClassifiedRow(raw.rowNo(), raw.frameCounter(), recordTime,
                    null, false, RowStatus.SKIPPED_UNSUPPORTED, null);
        }

        Map<String, Object> readings = decoded.get().toReadings();
        Integer rssi = parseIntegerOrNull(raw.rssi());
        if (rssi != null) readings.put("rssi", rssi);
        BigDecimal snr = parseBigDecimalOrNull(raw.snr());
        if (snr != null) readings.put("snr", snr);
        // No gateway info inside the frame → gatewayId stays unset (spec §4.3)

        return new ClassifiedRow(raw.rowNo(), raw.frameCounter(), recordTime,
                readings, hasValidGps(readings), RowStatus.IMPORTABLE, null);
    }

    private TelemetryParseResultDto.Row toPreviewRow(ClassifiedRow row) {
        Map<String, Object> readings = row.readings();
        return new TelemetryParseResultDto.Row(
                row.rowNo(), row.frameCounter(), row.recordTime(),
                readings != null ? (Integer) readings.get("battery") : null,
                readings != null ? (BigDecimal) readings.get("latitude") : null,
                readings != null ? (BigDecimal) readings.get("longitude") : null,
                readings != null ? (Integer) readings.get("stepCount") : null,
                row.status().name(),
                row.errorKey());
    }

    // ------------------------------------------------------------------
    // File reading (xlsx via POI, sheet 0, fixed column order A..F)
    // ------------------------------------------------------------------

    private List<RawRow> readRows(MultipartFile file) {
        List<RawRow> rows = new ArrayList<>();
        try (Workbook wb = new XSSFWorkbook(file.getInputStream())) {
            Sheet sheet = wb.getSheetAt(0);
            int dataRow = 0;
            for (Row row : sheet) {
                String dataType = cellString(row.getCell(0));
                String frameCounter = cellString(row.getCell(1));
                String hex = cellString(row.getCell(2));
                String rssi = cellString(row.getCell(3));
                String snr = cellString(row.getCell(4));
                String createTime = cellString(row.getCell(5));

                boolean blank = java.util.stream.Stream.of(dataType, frameCounter, hex, rssi, snr, createTime)
                        .allMatch(c -> c == null || c.isBlank());
                if (blank) continue;
                // Header auto-detection on the first data row
                if (dataRow == 0 && HEADER_FIRST_COLUMN.equals(trimToNull(dataType))) {
                    dataRow++; // skip header, keep row numbering consistent
                    continue;
                }
                dataRow++;
                rows.add(new RawRow(dataRow, trimToNull(dataType), trimToNull(frameCounter),
                        trimToNull(hex), trimToNull(rssi), trimToNull(snr), trimToNull(createTime)));
                if (rows.size() > MAX_ROWS) {
                    throw new ApiException(ErrorCode.VALIDATION_ERROR,
                            "error.telemetryImport.tooManyRows", new Object[]{MAX_ROWS});
                }
            }
        } catch (IOException e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR, "Failed to read file: " + e.getMessage());
        }
        return rows;
    }

    private static String cellString(org.apache.poi.ss.usermodel.Cell cell) {
        if (cell == null) return null;
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue();
            case NUMERIC -> DateUtil.isCellDateFormatted(cell)
                    ? cell.getLocalDateTimeCellValue().format(CELL_DT_FMT)
                    : numericString(cell.getNumericCellValue());
            default -> null;
        };
    }

    /**
     * Numeric cell text with Excel display semantics: whole numbers render
     * without a ".0" suffix (blade exports frame counters and RSSI as numeric
     * cells; "119.0" would break both display and Integer parsing).
     */
    private static String numericString(double value) {
        if (value == Math.floor(value) && !Double.isInfinite(value) && Math.abs(value) < 1e15) {
            return BigDecimal.valueOf((long) value).toPlainString();
        }
        return BigDecimal.valueOf(value).toPlainString();
    }

    // ------------------------------------------------------------------
    // Scalar parsing helpers
    // ------------------------------------------------------------------

    private static String trimToNull(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    /** Hex payload: whitespace-tolerant ("68 6B 74 ..."), must be even-length hex. */
    private static byte[] parseHex(String hex) {
        String cleaned = trimToNull(hex);
        if (cleaned == null) return null;
        cleaned = cleaned.replaceAll("\\s+", "");
        if (cleaned.isEmpty() || cleaned.length() % 2 != 0) return null;
        try {
            byte[] out = new byte[cleaned.length() / 2];
            for (int i = 0; i < out.length; i++) {
                out[i] = (byte) Integer.parseInt(cleaned.substring(i * 2, i * 2 + 2), 16);
            }
            return out;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /**
     * Parse the blade export time at face value on the UTC baseline (lesson #17).
     * Supports {@code yyyy-MM-dd HH:mm:ss[.SSSSSS]}. Returns null when empty or
     * unparseable — never falls back to now() (lesson #10).
     */
    private static Instant parseTime(String value) {
        String trimmed = trimToNull(value);
        if (trimmed == null) return null;
        try {
            return LocalDateTime.parse(trimmed, DT_FMT).toInstant(ZoneOffset.UTC);
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    /** RSSI column: integer; "-"/blank/garbage → absent (spec §4.3: 空则缺省). */
    private static Integer parseIntegerOrNull(String value) {
        String trimmed = trimToNull(value);
        if (trimmed == null || "-".equals(trimmed)) return null;
        try {
            return Integer.parseInt(trimmed);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /** SNR column: decimal; "-"/blank/garbage → absent. */
    private static BigDecimal parseBigDecimalOrNull(String value) {
        String trimmed = trimToNull(value);
        if (trimmed == null || "-".equals(trimmed)) return null;
        try {
            return new BigDecimal(trimmed);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /** A non-(0,0) fix; (0,0) means no fix and is skipped downstream. */
    private static boolean hasValidGps(Map<String, Object> readings) {
        BigDecimal lat = (BigDecimal) readings.get("latitude");
        BigDecimal lng = (BigDecimal) readings.get("longitude");
        return lat != null && lng != null
                && !(lat.compareTo(BigDecimal.ZERO) == 0 && lng.compareTo(BigDecimal.ZERO) == 0);
    }
}
