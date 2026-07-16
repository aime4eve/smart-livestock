package com.smartlivestock.iot.interfaces.admin;

import com.smartlivestock.iot.application.DynamicQualityReportService;
import com.smartlivestock.iot.application.DynamicTestRouteService;
import com.smartlivestock.iot.application.GpsQualityReportService;
import com.smartlivestock.iot.application.RtkCalibrationSessionService;
import com.smartlivestock.iot.application.RtkReferencePointService;
import com.smartlivestock.iot.domain.model.DynamicTestRoute;
import com.smartlivestock.iot.domain.model.DynamicTestRoutePoint;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.RtkReferencePoint;
import com.smartlivestock.iot.interfaces.admin.dto.CalibrationSessionDto;
import com.smartlivestock.iot.interfaces.admin.dto.ComparisonDto;
import com.smartlivestock.iot.interfaces.admin.dto.DeviceBriefDto;
import com.smartlivestock.iot.interfaces.admin.dto.DynamicQualityReportDto;
import com.smartlivestock.iot.interfaces.admin.dto.QualityReportDto;
import com.smartlivestock.iot.interfaces.admin.dto.RtkPointDto;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Admin endpoints for GPS quality checks (NIX-15).
 * <p>
 * All operations are platform-admin only. RTK reference points, calibration
 * sessions, quality reports and multi-device comparison are cross-tenant.
 */
@RestController
@RequestMapping("/api/v1/admin/gps-quality")
@RequiredArgsConstructor
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class GpsQualityAdminController {

    private final RtkReferencePointService rtkPointService;
    private final RtkCalibrationSessionService sessionService;
    private final GpsQualityReportService reportService;
    private final DynamicTestRouteService routeService;
    private final DynamicQualityReportService dynamicReportService;

    // ------------------------------------------------------------------
    // RTK reference points (1-4)
    // ------------------------------------------------------------------

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
                id,
                body.getLocationName(), body.getPointLabel(),
                body.getLatitude(), body.getLongitude(),
                body.getDmsLat(), body.getDmsLng());
        return ResponseEntity.ok(ApiResponse.ok(RtkPointDto.from(saved)));
    }

    @DeleteMapping("/rtk-points/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteRtkPoint(@PathVariable Long id) {
        rtkPointService.delete(id);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    // ------------------------------------------------------------------
    // Devices (5)
    // ------------------------------------------------------------------

    @GetMapping("/devices")
    public ResponseEntity<ApiResponse<List<DeviceBriefDto>>> listTrackers() {
        List<DeviceBriefDto> list = sessionService.listTrackers().stream()
                .map(d -> new DeviceBriefDto(d.getId(), d.getDeviceCode())).toList();
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    // ------------------------------------------------------------------
    // Calibration sessions (6-9)
    // ------------------------------------------------------------------

   @GetMapping("/sessions")
   public ResponseEntity<ApiResponse<Page<CalibrationSessionDto>>> listSessions(
           @RequestParam(required = false) Long rtkPointId,
           @RequestParam(required = false) Long deviceId,
           @RequestParam(required = false) String status,
            @RequestParam(required = false) String testType,
           @RequestParam(defaultValue = "0") int page,
           @RequestParam(defaultValue = "20") int size) {
       Pageable pageable = PageRequest.of(page, size);
        Page<GpsQualityTest> sessions =
                sessionService.findFiltered(rtkPointId, deviceId, status, testType, pageable);

        Set<Long> deviceIds = sessions.getContent().stream()
                .map(GpsQualityTest::getDeviceId).collect(Collectors.toSet());
        Map<Long, String> codeMap = sessionService.deviceCodeMap(List.copyOf(deviceIds));

        Page<CalibrationSessionDto> dtoPage = sessions.map(
                s -> CalibrationSessionDto.from(s, codeMap.get(s.getDeviceId())));
        return ResponseEntity.ok(ApiResponse.ok(dtoPage));
    }

    @PostMapping("/sessions")
    public ResponseEntity<ApiResponse<CalibrationSessionDto>> createSession(
            @RequestBody CalibrationSessionDto body) {
        GpsQualityTest saved = sessionService.create(
                body.getRtkPointId(), body.getDeviceId(),
                body.getStartedAt(), body.getEndedAt());
        String code = sessionService.resolveDeviceCode(saved.getDeviceId());
        return ResponseEntity.ok(ApiResponse.ok(CalibrationSessionDto.from(saved, code)));
    }

    @PatchMapping("/sessions/{id}/end")
    public ResponseEntity<ApiResponse<CalibrationSessionDto>> endSession(@PathVariable Long id) {
        GpsQualityTest saved = sessionService.end(id);
        String code = sessionService.resolveDeviceCode(saved.getDeviceId());
        return ResponseEntity.ok(ApiResponse.ok(CalibrationSessionDto.from(saved, code)));
    }

    @DeleteMapping("/sessions/{id}")
    public ResponseEntity<ApiResponse<CalibrationSessionDto>> cancelSession(@PathVariable Long id) {
        GpsQualityTest saved = sessionService.cancel(id);
        String code = sessionService.resolveDeviceCode(saved.getDeviceId());
        return ResponseEntity.ok(ApiResponse.ok(CalibrationSessionDto.from(saved, code)));
    }

    // ------------------------------------------------------------------
    // Reports / trajectory / comparison (10-12)
    // ------------------------------------------------------------------

    @GetMapping("/sessions/{id}/report")
    public ResponseEntity<ApiResponse<QualityReportDto>> report(
            @PathVariable Long id,
            @RequestParam(defaultValue = "false") boolean excludeSuspect) {
        GpsQualityReportService.ReportResult result = reportService.generate(id, excludeSuspect);
        return ResponseEntity.ok(ApiResponse.ok(QualityReportDto.from(result)));
    }

    @GetMapping("/sessions/{id}/trajectory")
    public ResponseEntity<ApiResponse<List<GpsQualityReportService.ScatterPoint>>> trajectory(
            @PathVariable Long id) {
        GpsQualityReportService.ReportResult result = reportService.generate(id, false);
        return ResponseEntity.ok(ApiResponse.ok(result.scatter()));
    }

    @GetMapping("/comparison")
    public ResponseEntity<ApiResponse<ComparisonDto>> comparison(
            @RequestParam Long rtkPointId) {
        GpsQualityReportService.ComparisonResult result =
                reportService.generateComparison(rtkPointId);
        return ResponseEntity.ok(ApiResponse.ok(ComparisonDto.from(result)));
    }

    // ------------------------------------------------------------------
    // Dynamic test routes (NIX-20)
    // ------------------------------------------------------------------

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

    // ------------------------------------------------------------------
    // Dynamic test sessions (NIX-20)
    // ------------------------------------------------------------------

    @PostMapping("/sessions/dynamic")
    public ResponseEntity<ApiResponse<CalibrationSessionDto>> createDynamicSession(
            @RequestBody CalibrationSessionDto body) {
        GpsQualityTest saved = sessionService.createDynamic(
                body.getRouteId(), body.getDeviceId(),
                body.getStartedAt(), body.getEndedAt());
        String code = sessionService.resolveDeviceCode(saved.getDeviceId());
        return ResponseEntity.ok(ApiResponse.ok(CalibrationSessionDto.from(saved, code)));
    }

    // ------------------------------------------------------------------
    // Dynamic report (NIX-20)
    // ------------------------------------------------------------------

    @GetMapping("/sessions/{id}/dynamic-report")
    public ResponseEntity<ApiResponse<DynamicQualityReportDto>> dynamicReport(
            @PathVariable Long id,
            @RequestParam(required = false) Double threshold) {
        DynamicQualityReportDto dto = dynamicReportService.generate(id, threshold);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }
}
