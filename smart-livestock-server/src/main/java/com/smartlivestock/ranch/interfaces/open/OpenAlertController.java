package com.smartlivestock.ranch.interfaces.open;

import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
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
     * Paginated alert list with filters (severity, status), id descending.
     * pageSize max 100 for Open API; total is the real filtered count.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listAlerts(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String severity,
            @RequestParam(required = false) String status,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);

        // Open API: pageSize capped at 100
        int effectivePage = Math.max(page, 1);
        int effectivePageSize = Math.min(Math.max(pageSize, 1), 100);

        // userId null: open API has no per-user read concept
        AlertRepository.AlertPage<AlertDto> result = alertApplicationService.listByFarmPaged(
                farmId, null, status, severity, List.of(), null, false, effectivePage, effectivePageSize);

        Map<String, Object> data = Map.of(
                "items", result.items(),
                "page", effectivePage,
                "pageSize", effectivePageSize,
                "total", result.total()
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
