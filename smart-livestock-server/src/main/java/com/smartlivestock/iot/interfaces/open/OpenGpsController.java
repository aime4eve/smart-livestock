package com.smartlivestock.iot.interfaces.open;

import com.smartlivestock.iot.application.GpsLogApplicationService;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.security.ApiKeyAuthService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * Open API — GPS Logs (read-only), 2 endpoints.
 * Third-party developers access GPS tracking data via API Key authentication.
 */
@RestController
@RequestMapping("/api/v1/open/farms/{farmId}")
@RequiredArgsConstructor
public class OpenGpsController {

    private final GpsLogApplicationService gpsLogApplicationService;
    private final ApiKeyAuthService apiKeyAuthService;

    /**
     * GET /api/v1/open/farms/{farmId}/gps-logs/latest
     * Batch latest GPS coordinates for all tracked livestock in the farm.
     * Requires cross-context query: livestock -> installation -> device -> gps_logs.
     * Phase 1: Returns empty list until cross-context query is wired.
     */
    @GetMapping("/gps-logs/latest")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLatestGps(
            @PathVariable Long farmId,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);

        // Phase 1 stub: requires cross-context query (livestock -> installation -> device -> gps_logs)
        Map<String, Object> data = Map.of(
                "items", List.of()
        );

        return ResponseEntity.ok()
                .headers(rateLimitHeaders())
                .body(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/open/farms/{farmId}/livestock/{livestockId}/gps-logs
     * Single livestock GPS history.
     * Query params: startTime, endTime, page, pageSize (max 100).
     * Phase 1: Returns empty list until cross-context query is wired.
     */
    @GetMapping("/livestock/{livestockId}/gps-logs")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLivestockGpsHistory(
            @PathVariable Long farmId,
            @PathVariable Long livestockId,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "100") int pageSize,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);

        // Open API: pageSize capped at 100
        int effectivePageSize = Math.min(pageSize, 100);

        // Phase 1 stub: requires cross-context query (livestock -> installation -> device -> gps_logs)
        Map<String, Object> data = Map.of(
                "items", List.of(),
                "page", page,
                "pageSize", effectivePageSize,
                "total", 0
        );

        return ResponseEntity.ok()
                .headers(rateLimitHeaders())
                .body(ApiResponse.ok(data));
    }

    /**
     * Phase 1: Static rate limit headers.
     * Phase 2: Dynamic per-key counting via Redis.
     */
    private HttpHeaders rateLimitHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-RateLimit-Limit", "60");
        headers.set("X-RateLimit-Remaining", "59");
        headers.set("X-RateLimit-Reset", String.valueOf(Instant.now().plusSeconds(60).getEpochSecond()));
        return headers;
    }
}
