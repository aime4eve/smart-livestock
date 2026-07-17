package com.smartlivestock.iot.interfaces.admin;

import com.smartlivestock.iot.application.DynamicQualityReportService;
import com.smartlivestock.iot.application.DynamicTestRouteService;
import com.smartlivestock.iot.application.GpsQualityReportService;
import com.smartlivestock.iot.application.GpsQualitySessionService;
import com.smartlivestock.iot.application.GpsQualityTestService;
import com.smartlivestock.iot.application.RtkReferencePointService;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DynamicTestRoute;
import com.smartlivestock.iot.domain.model.DynamicTestRoutePoint;
import com.smartlivestock.iot.domain.model.GpsQualitySession;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.RtkReferencePoint;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.interfaces.admin.dto.ComparisonDto;
import com.smartlivestock.iot.interfaces.admin.dto.DeviceBriefDto;
import com.smartlivestock.iot.interfaces.admin.dto.DynamicQualityReportDto;
import com.smartlivestock.iot.interfaces.admin.dto.GpsQualitySessionDto;
import com.smartlivestock.iot.interfaces.admin.dto.GpsQualityTestDto;
import com.smartlivestock.iot.interfaces.admin.dto.QualityReportDto;
import com.smartlivestock.iot.interfaces.admin.dto.RtkPointDto;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Admin endpoints for GPS quality checks.
 * Session-Test model: Session = device + time window; Test = sub-range + truth reference.
 */
@RestController
@RequestMapping("/api/v1/admin/gps-quality")
@RequiredArgsConstructor
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class GpsQualityAdminController {

    private final RtkReferencePointService rtkPointService;
    private final GpsQualitySessionService sessionService;
    private final GpsQualityTestService testService;
    private final GpsQualityReportService reportService;
    private final DynamicTestRouteService routeService;
    private final DynamicQualityReportService dynamicReportService;
    private final DeviceRepository deviceRepository;

    // --- RTK reference points (unchanged) ---

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

    // --- Sessions ---

    @GetMapping("/sessions")
    public ResponseEntity<ApiResponse<Page<GpsQualitySessionDto>>> listSessions(
            @RequestParam(required = false) Long deviceId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<GpsQualitySession> sessions = sessionService.findFiltered(deviceId, status, pageable);
        Set<Long> deviceIds = sessions.getContent().stream()
                .map(GpsQualitySession::getDeviceId).collect(Collectors.toSet());
        Map<Long, String> codeMap = resolveDeviceCodes(deviceIds);
        Page<GpsQualitySessionDto> dtoPage = sessions.map(
                s -> GpsQualitySessionDto.from(s, codeMap.get(s.getDeviceId())));
        return ResponseEntity.ok(ApiResponse.ok(dtoPage));
    }

    @PostMapping("/sessions")
    public ResponseEntity<ApiResponse<GpsQualitySessionDto>> createSession(
            @RequestBody Map<String, Object> body) {
        GpsQualitySession saved = sessionService.create(
                ((Number) body.get("deviceId")).longValue(),
                Instant.parse((String) body.get("startedAt")),
                body.get("endedAt") != null ? Instant.parse((String) body.get("endedAt")) : null);
        String code = deviceRepository.findById(saved.getDeviceId())
                .map(Device::getDeviceCode).orElse(null);
        return ResponseEntity.ok(ApiResponse.ok(GpsQualitySessionDto.from(saved, code)));
    }

    @PatchMapping("/sessions/{id}/end")
    public ResponseEntity<ApiResponse<GpsQualitySessionDto>> endSession(@PathVariable Long id) {
        GpsQualitySession saved = sessionService.end(id);
        String code = deviceRepository.findById(saved.getDeviceId())
                .map(Device::getDeviceCode).orElse(null);
        return ResponseEntity.ok(ApiResponse.ok(GpsQualitySessionDto.from(saved, code)));
    }

    @DeleteMapping("/sessions/{id}")
    public ResponseEntity<ApiResponse<GpsQualitySessionDto>> cancelSession(@PathVariable Long id) {
        GpsQualitySession saved = sessionService.cancel(id);
        String code = saved.getDeviceId() != null
                ? deviceRepository.findById(saved.getDeviceId()).map(Device::getDeviceCode).orElse(null)
                : null;
        return ResponseEntity.ok(ApiResponse.ok(GpsQualitySessionDto.from(saved, code)));
    }

    // --- Tests (sub-resource of session) ---

    @GetMapping("/sessions/{sessionId}/tests")
    public ResponseEntity<ApiResponse<List<GpsQualityTestDto>>> listTests(
            @PathVariable Long sessionId) {
        List<GpsQualityTestDto> list = testService.findBySessionId(sessionId).stream()
                .map(GpsQualityTestDto::from).toList();
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @PostMapping("/sessions/{sessionId}/tests")
    public ResponseEntity<ApiResponse<GpsQualityTestDto>> createTest(
            @PathVariable Long sessionId,
            @RequestBody Map<String, Object> body) {
        TestType testType = TestType.valueOf((String) body.getOrDefault("testType", "STATIC"));
        Long rtkPointId = body.get("rtkPointId") != null
                ? ((Number) body.get("rtkPointId")).longValue() : null;
        Long routeId = body.get("routeId") != null
                ? ((Number) body.get("routeId")).longValue() : null;
        Instant testStartedAt = Instant.parse((String) body.get("testStartedAt"));
        Instant testEndedAt = body.get("testEndedAt") != null
                ? Instant.parse((String) body.get("testEndedAt")) : null;
        GpsQualityTest saved = testService.create(
                sessionId, testType, rtkPointId, routeId, testStartedAt, testEndedAt);
        return ResponseEntity.ok(ApiResponse.ok(GpsQualityTestDto.from(saved)));
    }

    @DeleteMapping("/tests/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteTest(@PathVariable Long id) {
        testService.deleteById(id);
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

    // --- Dynamic test routes (unchanged) ---

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

    // --- Legacy aliases (backward compat, one iteration) ---

    @GetMapping("/sessions/{id}/report")
    public ResponseEntity<ApiResponse<QualityReportDto>> legacyReport(
            @PathVariable Long id,
            @RequestParam(defaultValue = "false") boolean excludeSuspect) {
        return report(id, excludeSuspect);
    }

    @GetMapping("/sessions/{id}/trajectory")
    public ResponseEntity<ApiResponse<List<GpsQualityReportService.ScatterPoint>>> legacyTrajectory(
            @PathVariable Long id) {
        return trajectory(id);
    }

    @GetMapping("/sessions/{id}/dynamic-report")
    public ResponseEntity<ApiResponse<DynamicQualityReportDto>> legacyDynamicReport(
            @PathVariable Long id,
            @RequestParam(required = false) Double threshold) {
        return dynamicReport(id, threshold);
    }

    // --- Helpers ---

    private Map<Long, String> resolveDeviceCodes(Set<Long> deviceIds) {
        return deviceIds.stream()
                .collect(Collectors.toMap(
                        id -> id,
                        id -> deviceRepository.findById(id)
                                .map(Device::getDeviceCode).orElse("")));
    }
}
