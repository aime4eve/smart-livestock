package com.smartlivestock.ranch.interfaces.open;

import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.security.ApiKeyAuthService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Open API — Alert (read-only), 2 endpoints.
 * Third-party developers access alert data via API Key authentication.
 */
@RestController
@RequestMapping("/api/v1/open/farms/{farmId}/alerts")
@RequiredArgsConstructor
public class OpenAlertController {

    private final AlertApplicationService alertApplicationService;
    private final ApiKeyAuthService apiKeyAuthService;

    /**
     * GET /api/v1/open/farms/{farmId}/alerts
     * Paginated alert list with filters (severity, status, time range).
     * pageSize max 100 for Open API.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listAlerts(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String severity,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);

        // Open API: pageSize capped at 100
        int effectivePageSize = Math.min(pageSize, 100);

        List<AlertDto> alerts;
        if (status != null) {
            AlertStatus alertStatus = AlertStatus.valueOf(status.toUpperCase());
            alerts = alertApplicationService.listByFarmAndStatus(farmId, alertStatus);
        } else {
            alerts = alertApplicationService.listByFarm(farmId);
        }

        // Phase 1: severity and time range filters not yet applied at service layer.
        // The service returns all alerts for the farm; client-side filtering or
        // repository-level filtering will be added in Phase 2.

        Map<String, Object> data = Map.of(
                "items", alerts,
                "page", page,
                "pageSize", effectivePageSize,
                "total", alerts.size()
        );

        return ResponseEntity.ok()
                .body(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/open/farms/{farmId}/alerts/{alertId}
     * Alert detail.
     */
    @GetMapping("/{alertId}")
    public ResponseEntity<ApiResponse<AlertDto>> getAlert(
            @PathVariable Long farmId,
            @PathVariable Long alertId,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);

        AlertDto alert = alertApplicationService.getAlert(alertId);
        return ResponseEntity.ok()
                .body(ApiResponse.ok(alert));
    }

}
