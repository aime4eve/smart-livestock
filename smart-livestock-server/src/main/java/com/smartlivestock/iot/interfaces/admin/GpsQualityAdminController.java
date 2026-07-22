package com.smartlivestock.iot.interfaces.admin;

import com.smartlivestock.iot.application.DynamicQualityReportService;
import com.smartlivestock.iot.application.DynamicTestRouteService;
import com.smartlivestock.iot.application.GpsQualityReportService;
import com.smartlivestock.iot.application.GpsQualityTestService;
import com.smartlivestock.iot.application.RtkReferencePointService;
import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.GpsQualityTestService.GpsQualityTestPage;
import com.smartlivestock.iot.application.GpsQualityBatchImportService;
import com.smartlivestock.iot.application.TrajectoryImportService;
import com.smartlivestock.iot.application.TrajectoryReportService;
import com.smartlivestock.iot.domain.model.DynamicTestRoute;
import com.smartlivestock.iot.domain.model.DynamicTestRoutePoint;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.RtkReferencePoint;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.interfaces.admin.dto.ComparisonDto;
import com.smartlivestock.iot.interfaces.admin.dto.DeviceBriefDto;
import com.smartlivestock.iot.interfaces.admin.dto.DynamicQualityReportDto;
import com.smartlivestock.iot.interfaces.admin.dto.GpsQualityTestDto;
import com.smartlivestock.iot.interfaces.admin.dto.BatchImportResultDto;
import com.smartlivestock.iot.interfaces.admin.dto.BatchParseResultDto;
import com.smartlivestock.iot.interfaces.admin.dto.DynamicComparisonDto;
import com.smartlivestock.iot.interfaces.admin.dto.QualityReportDto;
import com.smartlivestock.shared.tenant.TenantContext;
import com.smartlivestock.iot.interfaces.admin.dto.RtkPointDto;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryComparisonDto;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryImportResultDto;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryParseResultDto;
import com.smartlivestock.iot.interfaces.admin.dto.TrajectoryQualityReportDto;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.springframework.http.MediaType;
import lombok.RequiredArgsConstructor;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Admin endpoints for GPS quality checks.
 * Refactored NIX-21: Test-centric model (no sessions).
 */
@RestController
@RequestMapping("/api/v1/admin/gps-quality")
@RequiredArgsConstructor
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class GpsQualityAdminController {

    private final RtkReferencePointService rtkPointService;
    private final GpsQualityTestService testService;
    private final GpsQualityReportService reportService;
    private final DynamicTestRouteService routeService;
    private final DynamicQualityReportService dynamicReportService;
    private final DeviceRepository deviceRepository;
    private final GpsQualityBatchImportService batchImportService;
    private final DeviceApplicationService deviceApplicationService;
    private final TrajectoryImportService trajectoryImportService;
    private final TrajectoryReportService trajectoryReportService;

    // platform_admin has no tenant; GPS quality checks fall back to the demo tenant.
    // TODO: for production, add explicit tenant selection in the request body.
    private static final long FALLBACK_TENANT_ID = 1L;

    private Long resolveTenantId() {
        Long tenantId = TenantContext.getCurrentTenant();
        return tenantId != null ? tenantId : FALLBACK_TENANT_ID;
    }

    /**
     * Parse an ISO-8601 timestamp sent by clients. Accepts both offset-aware
     * ("2026-07-16T16:00:00Z") and naive local ("2026-07-16T16:00:00.000") forms;
     * naive values are taken at face value on the UTC baseline (lesson #17:
     * never guess the counterpart's timezone, keep one consistent baseline).
     */
    private static Instant parseInstant(String value) {
        try {
            return Instant.parse(value);
        } catch (DateTimeParseException ex) {
            return LocalDateTime.parse(value).toInstant(ZoneOffset.UTC);
        }
    }

    // --- RTK reference points ---

    @GetMapping("/rtk-points")
    public ResponseEntity<ApiResponse<List<RtkPointDto>>> listRtkPoints(
            @RequestParam(required = false) String locationName) {
        List<RtkPointDto> list = rtkPointService.findAll(locationName).stream()
                .map(RtkPointDto::from).toList();
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @PostMapping("/rtk-points")
    public ResponseEntity<ApiResponse<RtkPointDto>> createRtkPoint(@RequestBody RtkPointDto body) {
        RtkReferencePoint saved = rtkPointService.create(
                body.getLocationName(), body.getPointLabel(),
                body.getLatitude(), body.getLongitude(),
                body.getDmsLat(), body.getDmsLng());
        return ResponseEntity.ok(ApiResponse.ok(RtkPointDto.from(saved)));
    }

    @PutMapping("/rtk-points/{id}")
    public ResponseEntity<ApiResponse<RtkPointDto>> updateRtkPoint(
            @PathVariable Long id, @RequestBody RtkPointDto body) {
        RtkReferencePoint saved = rtkPointService.update(
                id, body.getLocationName(), body.getPointLabel(),
                body.getLatitude(), body.getLongitude(),
                body.getDmsLat(), body.getDmsLng());
        return ResponseEntity.ok(ApiResponse.ok(RtkPointDto.from(saved)));
    }

    @DeleteMapping("/rtk-points/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteRtkPoint(@PathVariable Long id) {
        rtkPointService.delete(id);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    // --- Devices ---

    @GetMapping("/devices")
    public ResponseEntity<ApiResponse<List<DeviceBriefDto>>> listTrackers() {
        List<DeviceBriefDto> list = deviceRepository.findAllTrackers().stream()
                .map(d -> new DeviceBriefDto(d.getId(), d.getDeviceCode())).toList();
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    // --- Tests (top-level resource, no session indirection) ---

    @GetMapping("/tests")
    public ResponseEntity<ApiResponse<List<GpsQualityTestDto>>> listTests(
            @RequestParam(required = false) Long deviceId) {
        List<GpsQualityTest> tests = deviceId != null
                ? testService.findByDeviceId(deviceId)
                : List.of();
        return ResponseEntity.ok(ApiResponse.ok(
                tests.stream().map(GpsQualityTestDto::from).toList()));
    }

    @PostMapping("/tests")
    public ResponseEntity<ApiResponse<GpsQualityTestDto>> createTest(
            @RequestBody Map<String, Object> body) {
        Long tenantId = resolveTenantId();
        String eui = (String) body.get("eui");
        String deviceCode = (String) body.get("deviceCode");
        Long deviceId = body.get("deviceId") != null
                ? ((Number) body.get("deviceId")).longValue() : null;

        // EUI resolution (primary path for manual creation)
        if (eui != null && !eui.isBlank()) {
            var deviceDto = deviceApplicationService.findOrCreateByEui(eui, deviceCode, tenantId);
            deviceCode = (deviceCode != null && !deviceCode.isBlank())
                    ? deviceCode : deviceDto.deviceCode();
            deviceId = deviceDto.id();
        }

        TestType testType = TestType.valueOf((String) body.getOrDefault("testType", "STATIC"));
        Long rtkPointId = body.get("rtkPointId") != null
                ? ((Number) body.get("rtkPointId")).longValue() : null;
        Long routeId = body.get("routeId") != null
                ? ((Number) body.get("routeId")).longValue() : null;
        Instant startedAt = parseInstant((String) body.get("startedAt"));
        Instant endedAt = body.get("endedAt") != null
                ? parseInstant((String) body.get("endedAt")) : null;
        GpsQualityTest saved = testService.create(
                deviceCode, deviceId, testType, rtkPointId, routeId, startedAt, endedAt);
        return ResponseEntity.ok(ApiResponse.ok(GpsQualityTestDto.from(saved)));
    }

    @DeleteMapping("/tests/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteTest(@PathVariable Long id) {
        testService.deleteById(id);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    // --- Checks (primary resource: flat, paginated) ---

    @GetMapping("/checks")
    public ResponseEntity<ApiResponse<GpsQualityTestPage>> listChecks(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String eui,
            @RequestParam(required = false) Long deviceId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        GpsQualityTestPage result = testService.findChecks(status, eui, deviceId, page, size);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @PostMapping("/checks")
    public ResponseEntity<ApiResponse<GpsQualityTestDto>> createCheck(
            @RequestBody Map<String, Object> body) {
        Long tenantId = resolveTenantId();
        String eui = (String) body.get("eui");
        if (eui == null || eui.isBlank()) {
            throw new ApiException(
                    ErrorCode.VALIDATION_ERROR, "eui is required");
        }
        String deviceCode = (String) body.get("deviceCode");
        var deviceDto = deviceApplicationService.findOrCreateByEui(eui, deviceCode, tenantId);
        if (deviceCode == null || deviceCode.isBlank()) {
            deviceCode = deviceDto.deviceCode();
        }
        TestType testType = TestType.valueOf((String) body.getOrDefault("testType", "STATIC"));
        Long rtkPointId = body.get("rtkPointId") != null
                ? ((Number) body.get("rtkPointId")).longValue() : null;
        Long routeId = body.get("routeId") != null
                ? ((Number) body.get("routeId")).longValue() : null;
        Instant startedAt = parseInstant((String) body.get("startedAt"));
        Instant endedAt = body.get("endedAt") != null
                ? parseInstant((String) body.get("endedAt")) : null;
        GpsQualityTest saved = testService.create(
                deviceCode, deviceDto.id(), testType, rtkPointId, routeId, startedAt, endedAt);
        return ResponseEntity.ok(ApiResponse.ok(GpsQualityTestDto.from(saved)));
    }

    @DeleteMapping("/checks/by-device/{deviceId}")
    public ResponseEntity<ApiResponse<Map<String, Integer>>> deleteChecksByDevice(
            @PathVariable Long deviceId) {
        int deleted = testService.deleteByDeviceId(deviceId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("deleted", deleted)));
    }

    // --- Batch import ---

    /**
     * Parse-only precheck of a batch import file: validates every row and
     * reports per-row preStatus (OK/WARN/ERROR) without persisting anything.
     */
    @PostMapping(value = "/batch/parse", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<BatchParseResultDto>> batchParse(
            @RequestParam("file") MultipartFile file) {
        Long tenantId = resolveTenantId();
        BatchParseResultDto result = batchImportService.parseExcel(file, tenantId);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @PostMapping(value = "/batch/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<BatchImportResultDto>> batchImport(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "excludeRows", required = false) String excludeRows) {
        Long tenantId = resolveTenantId();
        Set<Integer> excluded = null;
        if (excludeRows != null && !excludeRows.isBlank()) {
            excluded = new HashSet<>();
            for (String token : excludeRows.split(",")) {
                String t = token.trim();
                if (t.isEmpty()) continue;
                try {
                    excluded.add(Integer.parseInt(t));
                } catch (NumberFormatException e) {
                    throw new ApiException(
                            ErrorCode.VALIDATION_ERROR, "Invalid excludeRows value: '" + t + "'");
                }
            }
        }
        BatchImportResultDto result = batchImportService.importFromExcel(file, tenantId, excluded);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @GetMapping("/batch/template")
    public ResponseEntity<byte[]> batchTemplate() {
        byte[] data = batchImportService.generateTemplate();
        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=gps-quality-import-template.xlsx")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(data);
    }

    @PostMapping("/batch/retry-registration")
    public ResponseEntity<ApiResponse<List<BatchImportResultDto.RowResult>>> batchRetryRegistration(
            @RequestBody(required = false) Map<String, Object> body) {
        Long tenantId = resolveTenantId();
        List<Long> checkIds = null;
        if (body != null && body.get("checkIds") != null) {
            checkIds = ((List<?>) body.get("checkIds")).stream()
                    .map(id -> ((Number) id).longValue())
                    .toList();
        }
        var results = batchImportService.retryRegistration(checkIds, tenantId);
        return ResponseEntity.ok(ApiResponse.ok(results));
    }

    @PostMapping("/batch/retry-row")
    public ResponseEntity<ApiResponse<BatchImportResultDto.RowResult>> batchRetryRow(
            @RequestBody Map<String, Object> body) {
        Long tenantId = resolveTenantId();
        String eui = (String) body.get("eui");
        TestType testType = TestType.valueOf((String) body.getOrDefault("testType", "STATIC"));
        Instant startedAt = parseInstant((String) body.get("startedAt"));
        Instant endedAt = body.get("endedAt") != null
                ? parseInstant((String) body.get("endedAt")) : null;

        String deviceCode = (String) body.get("deviceCode");
        var deviceDto = deviceApplicationService.findOrCreateByEui(eui, deviceCode, tenantId);

        Long rtkPointId = body.get("rtkPointId") != null
                ? ((Number) body.get("rtkPointId")).longValue() : null;
        Long routeId = body.get("routeId") != null
                ? ((Number) body.get("routeId")).longValue() : null;

        GpsQualityTest saved = testService.create(
                deviceDto.deviceCode(), deviceDto.id(), testType, rtkPointId, routeId, startedAt, endedAt);
        return ResponseEntity.ok(ApiResponse.ok(
               new BatchImportResultDto.RowResult(0, "READY", eui, null,
                        deviceDto.id(), saved.getId(), null)));
    }

    @DeleteMapping("/batch/{batchId}")
    public ResponseEntity<ApiResponse<Void>> batchDelete(@PathVariable Long batchId) {
        batchImportService.deleteBatch(batchId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }


    // --- Reports ---

    @GetMapping("/tests/{id}/report")
    public ResponseEntity<ApiResponse<QualityReportDto>> report(
            @PathVariable Long id,
            @RequestParam(defaultValue = "false") boolean excludeSuspect) {
        GpsQualityReportService.ReportResult result = reportService.generate(id, excludeSuspect);
        return ResponseEntity.ok(ApiResponse.ok(QualityReportDto.from(result)));
    }

    @GetMapping("/tests/{id}/dynamic-report")
    public ResponseEntity<ApiResponse<DynamicQualityReportDto>> dynamicReport(
            @PathVariable Long id,
            @RequestParam(required = false) Double threshold) {
        DynamicQualityReportDto dto = dynamicReportService.generate(id, threshold);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    // --- RTK trajectory import (NIX-22) ---

    /** Max pairing tolerance: 1 hour. */
    private static final int MAX_TOLERANCE_SEC = 3600;

    private static int validateTolerance(int toleranceSec) {
        if (toleranceSec < 1 || toleranceSec > MAX_TOLERANCE_SEC) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "toleranceSec must be within 1.." + MAX_TOLERANCE_SEC + ": " + toleranceSec);
        }
        return toleranceSec;
    }

    @GetMapping("/trajectory/template")
    public ResponseEntity<byte[]> trajectoryTemplate() {
        byte[] data = trajectoryImportService.generateTemplate();
        return ResponseEntity.ok()
                .header("Content-Disposition", "attachment; filename=trajectory-import-template.csv")
                .contentType(MediaType.parseMediaType("text/csv;charset=UTF-8"))
                .body(data);
    }

    /**
     * Parse + pairing preview of a trajectory file. Nothing is persisted.
     */
    @PostMapping(value = "/trajectory/parse", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<TrajectoryParseResultDto>> trajectoryParse(
            @RequestParam("file") MultipartFile file,
            @RequestParam(defaultValue = "60") int toleranceSec) {
        Long tenantId = resolveTenantId();
        TrajectoryParseResultDto result =
                trajectoryImportService.parse(file, validateTolerance(toleranceSec), tenantId);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    /**
     * Import a trajectory file: one TRAJECTORY test per device + pairing snapshot.
     */
    @PostMapping(value = "/trajectory/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<TrajectoryImportResultDto>> trajectoryImport(
            @RequestParam("file") MultipartFile file,
            @RequestParam(defaultValue = "60") int toleranceSec) {
        Long tenantId = resolveTenantId();
        TrajectoryImportResultDto result =
                trajectoryImportService.importFile(file, validateTolerance(toleranceSec), tenantId);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    /**
     * Manual device registration for trajectory import: register (or find) a
     * device by EUI with optional user-specified deviceCode. Returns device
     * id/code and platform binding status.
     */
    @PostMapping("/trajectory/register-device")
    public ResponseEntity<ApiResponse<DeviceBriefDto>> trajectoryRegisterDevice(
            @RequestBody Map<String, Object> body) {
        Long tenantId = resolveTenantId();
        String eui = (String) body.get("eui");
        if (eui == null || eui.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "eui is required");
        }
        String deviceCode = (String) body.get("deviceCode");
        var deviceDto = deviceApplicationService.findOrCreateByEui(eui, deviceCode, tenantId);
        boolean platformBound = deviceDto.platformDeviceId() != null;
        return ResponseEntity.ok(ApiResponse.ok(new DeviceBriefDto(
                deviceDto.id(), deviceDto.deviceCode(), platformBound)));
    }

    @GetMapping("/tests/{id}/trajectory-report")
    public ResponseEntity<ApiResponse<TrajectoryQualityReportDto>> trajectoryReport(
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(trajectoryReportService.generate(id)));
    }

    /**
     * Trajectory comparison: latest READY TRAJECTORY test per device.
     */
    @GetMapping("/comparison/trajectory")
    public ResponseEntity<ApiResponse<TrajectoryComparisonDto>> trajectoryComparison() {
        return ResponseEntity.ok(ApiResponse.ok(trajectoryReportService.generateComparison()));
    }

    @GetMapping("/tests/{id}/trajectory")
    public ResponseEntity<ApiResponse<List<GpsQualityReportService.ScatterPoint>>> trajectory(
            @PathVariable Long id) {
        GpsQualityReportService.ReportResult result = reportService.generate(id, false);
        return ResponseEntity.ok(ApiResponse.ok(result.scatter()));
    }

    // --- Comparison ---

    @GetMapping("/comparison")
    public ResponseEntity<ApiResponse<ComparisonDto>> comparison(
            @RequestParam(required = false) Long rtkPointId) {
        if (rtkPointId == null) {
            return ResponseEntity.ok(ApiResponse.ok(null));
        }
        GpsQualityReportService.ComparisonResult result =
                reportService.generateComparison(rtkPointId);
        return ResponseEntity.ok(ApiResponse.ok(ComparisonDto.from(result)));
    }

    /**
     * Dynamic comparison: latest READY dynamic test per device on one route.
     */
    @GetMapping("/comparison/dynamic")
    public ResponseEntity<ApiResponse<DynamicComparisonDto>> dynamicComparison(
            @RequestParam Long routeId) {
        return ResponseEntity.ok(ApiResponse.ok(dynamicReportService.generateRouteComparison(routeId)));
    }

    // --- Dynamic test routes ---

    @GetMapping("/dynamic-routes")
    public ResponseEntity<ApiResponse<List<DynamicTestRoute>>> listRoutes() {
        return ResponseEntity.ok(ApiResponse.ok(routeService.findAll()));
    }

    @PostMapping("/dynamic-routes")
    public ResponseEntity<ApiResponse<DynamicTestRoute>> createRoute(@RequestBody Map<String, Object> body) {
        DynamicTestRoute saved = routeService.create(
                (String) body.get("name"), (String) body.get("description"));
        return ResponseEntity.ok(ApiResponse.ok(saved));
    }

    @PutMapping("/dynamic-routes/{id}")
    public ResponseEntity<ApiResponse<DynamicTestRoute>> updateRoute(
            @PathVariable Long id, @RequestBody Map<String, Object> body) {
        DynamicTestRoute saved = routeService.update(id,
                (String) body.get("name"), (String) body.get("description"));
        return ResponseEntity.ok(ApiResponse.ok(saved));
    }

    @DeleteMapping("/dynamic-routes/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteRoute(@PathVariable Long id) {
        routeService.delete(id);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @GetMapping("/dynamic-routes/{id}/points")
    public ResponseEntity<ApiResponse<List<DynamicTestRoutePoint>>> routePoints(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(routeService.findPoints(id)));
    }

    @PutMapping("/dynamic-routes/{id}/points")
    public ResponseEntity<ApiResponse<Void>> replaceRoutePoints(
            @PathVariable Long id, @RequestBody List<Map<String, Object>> points) {
        var inputs = points.stream()
                .map(p -> new DynamicTestRouteService.RoutePointInput(
                        ((Number) p.get("rtkPointId")).longValue(),
                        ((Number) p.get("sequenceNo")).intValue()))
                .toList();
        routeService.replacePoints(id, inputs);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
