package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.GpsLogApplicationService;
import com.smartlivestock.iot.application.InstallationApplicationService;
import com.smartlivestock.iot.application.dto.GpsLogDto;
import com.smartlivestock.iot.application.dto.InstallationDto;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/farms/{farmId}")
@RequiredArgsConstructor
public class GpsLogController {

    private final GpsLogApplicationService gpsLogApplicationService;
    private final InstallationApplicationService installationApplicationService;

    /**
     * GET /api/v1/farms/{farmId}/gps-logs/latest
     * Get latest GPS coordinates for all tracked livestock in a farm.
     */
    @GetMapping("/gps-logs/latest")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLatestGps(
            @PathVariable Long farmId) {
        // Get all livestock in the farm, find active installations, get GPS logs
        // Stub for now — requires cross-context query (livestock -> installation -> gps_logs)
        Map<String, Object> data = Map.of(
                "items", List.of()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/farms/{farmId}/livestock/{livestockId}/gps-logs
     * Get GPS history for a specific livestock.
     * Path: livestock -> installation -> device -> gps_logs
     */
    @GetMapping("/livestock/{livestockId}/gps-logs")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLivestockGpsHistory(
            @PathVariable Long farmId,
            @PathVariable Long livestockId,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "100") int pageSize) {
        // Find active installation for this livestock
        // The installation service needs a method to find by livestockId.
        // For now, return empty until InstallationApplicationService is extended.
        Map<String, Object> data = Map.of(
                "items", List.of(),
                "page", page,
                "pageSize", pageSize,
                "total", 0
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }
}
