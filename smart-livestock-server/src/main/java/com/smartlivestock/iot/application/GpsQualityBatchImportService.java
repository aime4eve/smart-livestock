package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DynamicTestRoute;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.RtkReferencePoint;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.repository.DynamicTestRouteRepository;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.domain.repository.RtkReferencePointRepository;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.interfaces.admin.dto.BatchImportResultDto;
import com.smartlivestock.iot.interfaces.admin.dto.BatchImportResultDto.RowResult;
import com.smartlivestock.iot.interfaces.admin.dto.BatchParseResultDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.DateTimeParseException;
import java.time.format.SignStyle;
import java.time.temporal.ChronoField;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Batch import GPS quality checks from Excel (.xlsx).
 * <p>
 * Excel columns: EUI, deviceCode(optional), checkType(静态/动态),
 * truthRef(static=pointLabel, dynamic=routeName), startedAt, endedAt(optional).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GpsQualityBatchImportService {

    private static final DateTimeFormatter DT_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * Accepted datetime text formats for the startedAt/endedAt columns:
     * dash or slash separated, 1-2 digit fields, seconds optional
     * (e.g. "2026-07-18 09:00:00", "2026-07-18 09:00", "2026/7/8 9:05").
     * Numeric date-formatted Excel cells are converted to text via
     * {@link #DT_FMT} before parsing, so they need no pattern here.
     */
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

    private final GpsQualityTestRepository testRepository;
    private final DeviceApplicationService deviceApplicationService;
    private final DeviceRepository deviceRepository;
    private final RtkReferencePointRepository rtkPointRepository;
    private final DynamicTestRouteRepository routeRepository;

    // --- In-memory caches for truth reference lookups ---
    private final Map<String, List<RtkReferencePoint>> rtkCache = new ConcurrentHashMap<>();
    private final Map<String, List<DynamicTestRoute>> routeCache = new ConcurrentHashMap<>();

    // Raw cell values of one Excel row (rowIndex = sheet row index, header = 0)
    private record RawRow(
        int rowIndex,
        String eui,
        String deviceCode,
        String checkTypeStr,
        String truthRef,
        String startedAtStr,
        String endedAtStr
    ) {}

    // Row parsing result
    private record ImportRow(
        int rowIndex,
        String eui,
        String deviceCode,
        TestType checkType,
        String truthRef,
        Instant startedAt,
        Instant endedAt
    ) {
        String batchDedupKey() { return eui + "@" + startedAt; }
    }

    /**
     * Import GPS quality checks from an uploaded Excel file.
     * <p>
     * Intentionally NOT @Transactional: each row's device creation and test save
     * run in their own transactions (findOrCreateByEui / testRepository.save are
     * independently @Transactional). A shared transaction would mark the Hibernate
     * Session rollback-only after the first row failure, breaking all subsequent
     * rows with "null id" errors.
     */
    public BatchImportResultDto importFromExcel(MultipartFile file, Long tenantId,
                                                @Nullable Set<Integer> excludeRows) {
        List<ImportRow> rows;
        try (Workbook wb = new XSSFWorkbook(file.getInputStream())) {
            List<RawRow> rawRows = readRawRows(wb.getSheetAt(0));
            rows = new ArrayList<>(rawRows.size());
            for (RawRow raw : rawRows) {
                if (excludeRows != null && excludeRows.contains(raw.rowIndex())) continue;
                rows.add(toImportRow(raw));
            }
        } catch (IOException e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR, "Failed to parse Excel: " + e.getMessage());
        }

        if (rows.isEmpty()) {
            BatchImportResultDto empty = new BatchImportResultDto();
            empty.setBatchId(null);
            empty.setTotalRows(0);
            empty.setTotalSuccess(0);
            empty.setTotalPending(0);
            empty.setTotalFailed(0);
            empty.setRows(List.of());
            return empty;
        }

        long batchId = System.currentTimeMillis();
        List<RowResult> results = new ArrayList<>(rows.size());
        Set<String> seenInBatch = new HashSet<>();

        // Preload truth reference caches
        List<RtkReferencePoint> allRtkPoints = rtkPointRepository.findAll();
        rtkCache.put("all", allRtkPoints);
        List<DynamicTestRoute> allRoutes = routeRepository.findAll();
        routeCache.put("all", allRoutes);

        for (ImportRow row : rows) {
            try {
                // Step 1: Batch-internal dedup
                String dedupKey = row.batchDedupKey();
                if (!seenInBatch.add(dedupKey)) {
                    results.add(new RowResult(row.rowIndex(), "SKIPPED",
                        row.eui(), row.deviceCode(), null, null,
                        "Duplicate within batch: " + dedupKey));
                    continue;
                }

                // Step 2: Resolve device (revive must run BEFORE historical dedup:
                // existsByEuiAndTimeRange INNER JOINs devices, and a still-soft-deleted
                // device is filtered out by the global restriction → dedup would miss)
                DeviceDto deviceDto = deviceApplicationService.findOrCreateByEui(row.eui(), row.deviceCode(), tenantId);

                // Step 3: Historical dedup
                if (testRepository.existsByEuiAndTimeRange(
                        row.eui(), row.startedAt(), row.checkType().name())) {
                    results.add(new RowResult(row.rowIndex(), "SKIPPED",
                        row.eui(), row.deviceCode(), null, null,
                        "Duplicate check: same EUI + time range + type already exists"));
                    continue;
                }

                // Step 4: Resolve truth reference
                Long rtkPointId = null;
                Long routeId = null;
                if (row.checkType() == TestType.STATIC) {
                    rtkPointId = resolveRtkPointId(row.truthRef(), row.rowIndex());
                } else {
                    routeId = resolveRouteId(row.truthRef(), row.rowIndex());
                }

                // Step 5: Create GpsQualityTest
                // Use the resolved device's code (not the raw EUI) as deviceCode
                // so all three import paths share one consistent identifier.
                GpsQualityTest test = new GpsQualityTest(deviceDto.deviceCode(), row.checkType(), rtkPointId, routeId, row.startedAt());
               test.setDeviceId(deviceDto.id());
                test.setEndedAt(row.endedAt());
                test.setBatchImportId(batchId);

                // Determine status: if device is ACTIVE with platformDeviceId → READY, else DEVICE_PENDING
                if (deviceDto.platformDeviceId() != null) {
                    test.setStatus("READY");
                } else {
                    test.setStatus("DEVICE_PENDING");
                    test.setErrorMessage("Device has no platform registration; awaiting manual registration");
                }

                GpsQualityTest saved = testRepository.save(test);

                results.add(new RowResult(row.rowIndex(), test.getStatus(),
                    row.eui(), row.deviceCode(), deviceDto.id(), saved.getId(), null));

            } catch (ApiException e) {
                results.add(new RowResult(row.rowIndex(), "FAILED",
                    row.eui(), row.deviceCode(), null, null, e.getMessage()));
            } catch (Exception e) {
                log.warn("Batch import row {} failed: {}", row.rowIndex(), e.getMessage());
                results.add(new RowResult(row.rowIndex(), "FAILED",
                    row.eui(), row.deviceCode(), null, null, e.getMessage()));
            }
        }

        // Aggregate counts
        int success = 0, pending = 0, failed = 0;
        for (RowResult r : results) {
            switch (r.status()) {
                case "READY" -> success++;
                case "DEVICE_PENDING" -> pending++;
                default -> failed++;
            }
        }

        BatchImportResultDto result = new BatchImportResultDto();
        result.setBatchId(batchId);
        result.setTotalRows(rows.size());
        result.setTotalSuccess(success);
        result.setTotalPending(pending);
        result.setTotalFailed(failed);
        result.setRows(results);
        return result;
    }

    /**
     * Generate an Excel template with headers and one example row.
     */
    public byte[] generateTemplate() {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("GPS质量检验导入");
            String[] headers = {"EUI", "设备编号(可选)", "检验类型(静态/动态)", "真值参考", "开始时间", "结束时间(可选)"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                headerRow.createCell(i).setCellValue(headers[i]);
            }
            // Example row
            Row example = sheet.createRow(1);
            example.createCell(0).setCellValue("A84041CEFE380733");
            example.createCell(1).setCellValue("GPS-001");
            example.createCell(2).setCellValue("静态");
            example.createCell(3).setCellValue("11号点");
            example.createCell(4).setCellValue("2026-07-01 10:00:00");
            example.createCell(5).setCellValue("2026-07-01 11:00:00");
            // Auto-size columns
            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            wb.write(bos);
            return bos.toByteArray();
        } catch (IOException e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR, "Failed to generate template: " + e.getMessage());
        }
    }

    /**
     * Retry device registration for all DEVICE_PENDING checks.
     * Non-destructive: only attempts re-registration; on success sets status=READY.
     */
    @Transactional
    public List<RowResult> retryRegistration(@Nullable List<Long> checkIds, Long tenantId) {
        List<GpsQualityTest> pendingTests;
        if (checkIds != null && !checkIds.isEmpty()) {
            pendingTests = checkIds.stream()
                .map(id -> {
                    try { return testRepository.findById(id).orElse(null); }
                    catch (Exception e) { return null; }
                })
                .filter(t -> t != null && "DEVICE_PENDING".equals(t.getStatus()))
                .toList();
        } else {
            pendingTests = testRepository.findByStatusAndTenantId("DEVICE_PENDING", tenantId).stream()
                    .filter(t -> t.getDeviceId() != null)
                    .toList();
        }

        List<RowResult> results = new ArrayList<>(pendingTests.size());
        for (GpsQualityTest test : pendingTests) {
            try {
                String eui = deviceRepository.findById(test.getDeviceId())
                        .map(Device::getDevEui).orElse(test.getDeviceCode());
                DeviceDto deviceDto = deviceApplicationService.registerWithPlatform(test.getDeviceId());
                if (deviceDto.platformDeviceId() != null) {
                    test.setStatus("READY");
                    test.setErrorMessage(null);
                    testRepository.save(test);
                    results.add(new RowResult(0, "READY", eui,
                        test.getDeviceCode(), test.getDeviceId(), test.getId(), "Registration succeeded"));
                } else {
                    results.add(new RowResult(0, "DEVICE_PENDING", eui,
                        test.getDeviceCode(), test.getDeviceId(), test.getId(),
                        "Platform registration still pending"));
                }
            } catch (Exception e) {
                String eui = deviceRepository.findById(test.getDeviceId())
                        .map(Device::getDevEui).orElse(test.getDeviceCode());
                results.add(new RowResult(0, "FAILED", eui,
                    test.getDeviceCode(), test.getDeviceId(), test.getId(),
                    "Retry failed: " + e.getMessage()));
            }
        }
        return results;
    }

    /**
     * Delete all tests belonging to a batch import.
     */
    @Transactional
    public int deleteBatch(Long batchId) {
        int count = 0;
        List<GpsQualityTest> tests = testRepository.findByBatchImportId(batchId);
        for (GpsQualityTest t : tests) {
            testRepository.deleteById(t.getId());
            count++;
        }
        return count;
    }

    /**
     * Parse-only precheck of an uploaded Excel file: resolves and validates every
     * row WITHOUT creating devices, registering on blade, or persisting anything.
     * <p>
     * Row preStatus: OK (device exists and is registered) / WARN (EUI valid but
     * device missing or not yet registered) / ERROR (row cannot be imported).
     */
    public BatchParseResultDto parseExcel(MultipartFile file, Long tenantId) {
        List<RawRow> rawRows;
        try (Workbook wb = new XSSFWorkbook(file.getInputStream())) {
            rawRows = readRawRows(wb.getSheetAt(0));
        } catch (IOException e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR, "Failed to parse Excel: " + e.getMessage());
        }

        // Preload truth reference caches
        rtkCache.put("all", rtkPointRepository.findAll());
        routeCache.put("all", routeRepository.findAll());

        List<BatchParseResultDto.ParseRow> rows = new ArrayList<>(rawRows.size());
        int ok = 0, warn = 0, error = 0;
        for (RawRow raw : rawRows) {
            BatchParseResultDto.ParseRow row = precheckRow(raw, tenantId);
            rows.add(row);
            switch (row.preStatus()) {
                case "OK" -> ok++;
                case "WARN" -> warn++;
                default -> error++;
            }
        }

        BatchParseResultDto result = new BatchParseResultDto();
        result.setTotalRows(rows.size());
        result.setOkCount(ok);
        result.setWarnCount(warn);
        result.setErrorCount(error);
        result.setRows(rows);
        return result;
    }

    // --- Private helpers ---

    private BatchParseResultDto.ParseRow precheckRow(RawRow raw, Long tenantId) {
        String eui = raw.eui().trim();
        String deviceCode = raw.deviceCode();
        String truthRef = raw.truthRef() != null ? raw.truthRef().trim() : null;

        if (eui.length() < 4) {
            return new BatchParseResultDto.ParseRow(raw.rowIndex(), eui, deviceCode, null,
                    truthRef, null, null, null, null,
                    "ERROR", "EUI must be at least 4 characters");
        }

        TestType checkType = parseCheckType(raw.checkTypeStr());
        if (checkType == null) {
            return new BatchParseResultDto.ParseRow(raw.rowIndex(), eui, deviceCode, null,
                    truthRef, null, null, null, null,
                    "ERROR", "Invalid checkType '" + raw.checkTypeStr()
                    + "' (expected 静态/动态 or STATIC/DYNAMIC)");
        }

        if (truthRef == null || truthRef.isBlank()) {
            return new BatchParseResultDto.ParseRow(raw.rowIndex(), eui, deviceCode, checkType.name(),
                    null, null, null, null, null,
                    "ERROR", "truthRef is required");
        }

        Instant startedAt;
        Instant endedAt;
        try {
            if (raw.startedAtStr() == null || raw.startedAtStr().isBlank()) {
                throw new ApiException(ErrorCode.VALIDATION_ERROR, "startedAt is required");
            }
            startedAt = parseDateTime(raw.startedAtStr());
            endedAt = (raw.endedAtStr() != null && !raw.endedAtStr().isBlank())
                    ? parseDateTime(raw.endedAtStr()) : null;
        } catch (ApiException e) {
            return new BatchParseResultDto.ParseRow(raw.rowIndex(), eui, deviceCode, checkType.name(),
                    truthRef, null, null, null, null,
                    "ERROR", e.getMessage());
        }

        Long rtkPointId = null;
        Long routeId = null;
        try {
            if (checkType == TestType.STATIC) {
                rtkPointId = resolveRtkPointId(truthRef, raw.rowIndex());
            } else {
                routeId = resolveRouteId(truthRef, raw.rowIndex());
            }
        } catch (ApiException e) {
            return new BatchParseResultDto.ParseRow(raw.rowIndex(), eui, deviceCode, checkType.name(),
                    truthRef, null, null, startedAt, endedAt,
                    "ERROR", e.getMessage());
        }

        // Device precheck: lookup only, never create or register.
        // Include soft-deleted rows so a deleted device gets an accurate WARN instead
        // of the misleading "Device not found" (best-effort; may differ from actual import).
        List<Device> devices = deviceRepository.findAllByDevEuiAndTenantIdIncludeDeleted(eui, tenantId);
        if (devices.isEmpty()) {
            return new BatchParseResultDto.ParseRow(raw.rowIndex(), eui, deviceCode, checkType.name(),
                    truthRef, rtkPointId, routeId, startedAt, endedAt,
                    "WARN", "Device not found; will be created and registered on import");
        }
        Device device = devices.get(0);
        if (deviceCode == null || deviceCode.isBlank()) {
            deviceCode = device.getDeviceCode();
        }
        if (device.getDeletedAt() != null) {
            return new BatchParseResultDto.ParseRow(raw.rowIndex(), eui, deviceCode, checkType.name(),
                    truthRef, rtkPointId, routeId, startedAt, endedAt,
                    "WARN", "Device was deleted; it will be restored on import");
        }
        if (device.getPlatformDeviceId() == null) {
            return new BatchParseResultDto.ParseRow(raw.rowIndex(), eui, deviceCode, checkType.name(),
                    truthRef, rtkPointId, routeId, startedAt, endedAt,
                    "WARN", "Device exists but is not registered on blade platform");
        }
        return new BatchParseResultDto.ParseRow(raw.rowIndex(), eui, deviceCode, checkType.name(),
                truthRef, rtkPointId, routeId, startedAt, endedAt,
                "OK", null);
    }

    private List<RawRow> readRawRows(Sheet sheet) {
        List<RawRow> rows = new ArrayList<>();
        for (int i = 1; i <= sheet.getLastRowNum(); i++) {
            Row r = sheet.getRow(i);
            if (r == null) continue;

            String eui = getCellString(r, 0);
            if (eui == null || eui.isBlank()) continue; // skip empty rows

            rows.add(new RawRow(i, eui, getCellString(r, 1), getCellString(r, 2),
                    getCellString(r, 3), getCellString(r, 4), getCellString(r, 5)));
        }
        return rows;
    }

    /**
     * Strictly convert a raw row into an import row, throwing on the first
     * invalid value (same validation as before the parse-only endpoint existed).
     */
    private ImportRow toImportRow(RawRow raw) {
        String eui = raw.eui().trim();
        if (eui.length() < 4) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                "Row " + (raw.rowIndex() + 1) + ": EUI must be at least 4 characters");
        }

        TestType checkType = parseCheckType(raw.checkTypeStr());
        if (checkType == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                "Row " + (raw.rowIndex() + 1) + ": Invalid checkType '" + raw.checkTypeStr()
                + "' (expected 静态/动态 or STATIC/DYNAMIC)");
        }

        if (raw.truthRef() == null || raw.truthRef().isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                "Row " + (raw.rowIndex() + 1) + ": truthRef is required");
        }

        if (raw.startedAtStr() == null || raw.startedAtStr().isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                "Row " + (raw.rowIndex() + 1) + ": startedAt is required");
        }

        Instant startedAt = parseDateTime(raw.startedAtStr());
        Instant endedAt = (raw.endedAtStr() != null && !raw.endedAtStr().isBlank())
            ? parseDateTime(raw.endedAtStr()) : null;

        return new ImportRow(raw.rowIndex(), eui, raw.deviceCode(), checkType,
                raw.truthRef().trim(), startedAt, endedAt);
    }

    private TestType parseCheckType(String checkTypeStr) {
        if ("静态".equals(checkTypeStr) || "STATIC".equalsIgnoreCase(checkTypeStr)) {
            return TestType.STATIC;
        }
        if ("动态".equals(checkTypeStr) || "DYNAMIC".equalsIgnoreCase(checkTypeStr)) {
            return TestType.DYNAMIC;
        }
        return null;
    }

    private String getCellString(Row r, int cellIdx) {
        var cell = r.getCell(cellIdx);
        if (cell == null) return null;
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue();
            // Date-formatted numeric cells become canonical datetime text;
            // plain numbers keep the old long-string behavior (e.g. EUI column).
            case NUMERIC -> DateUtil.isCellDateFormatted(cell)
                    ? cell.getLocalDateTimeCellValue().format(DT_FMT)
                    : String.valueOf((long) cell.getNumericCellValue());
            default -> null;
        };
    }

    private Instant parseDateTime(String str) {
        String value = str.trim();
        for (DateTimeFormatter fmt : DT_FORMATS) {
            try {
                // Naive text stays on the UTC+8 baseline, consistent with
                // previously imported data.
                return LocalDateTime.parse(value, fmt).toInstant(ZoneOffset.ofHours(8));
            } catch (DateTimeParseException ignored) {
                // try the next format
            }
        }
        try {
            return Instant.parse(value);
        } catch (DateTimeParseException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                "Invalid datetime format: '" + str + "'. Supported formats: "
                + "yyyy-MM-dd HH:mm:ss, yyyy-MM-dd HH:mm, yyyy/MM/dd HH:mm:ss, yyyy/MM/dd HH:mm, "
                + "or an Excel date-formatted cell");
        }
    }

    private Long resolveRtkPointId(String truthRef, int rowIndex) {
        List<RtkReferencePoint> allPoints = rtkCache.getOrDefault("all", rtkPointRepository.findAll());
        if (!rtkCache.containsKey("all")) rtkCache.put("all", allPoints);

        // Try exact match on pointLabel first, then locationName
        for (RtkReferencePoint p : allPoints) {
            if (truthRef.equals(p.getPointLabel())) return p.getId();
        }
        throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
            "Row " + (rowIndex + 1) + ": RTK point not found for truthRef '" + truthRef + "'");
    }

    private Long resolveRouteId(String truthRef, int rowIndex) {
        List<DynamicTestRoute> allRoutes = routeCache.getOrDefault("all", routeRepository.findAll());
        if (!routeCache.containsKey("all")) routeCache.put("all", allRoutes);

        for (DynamicTestRoute r : allRoutes) {
            if (truthRef.equals(r.getName())) return r.getId();
        }
        throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
            "Row " + (rowIndex + 1) + ": Route not found for truthRef '" + truthRef + "'");
    }
}
