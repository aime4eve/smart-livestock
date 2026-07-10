package com.smartlivestock.iot.interfaces.open;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.security.ApiKeyAuthService;
import com.smartlivestock.shared.tenant.TenantContext;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Open API — Device (read-only), 2 endpoints.
 * Third-party developers access device data via API Key authentication.
 */
@RestController
@RequestMapping("/api/v1/open/farms/{farmId}/devices")
@RequiredArgsConstructor
public class OpenDeviceController {

    private final DeviceApplicationService deviceApplicationService;
    private final ApiKeyAuthService apiKeyAuthService;

    /**
     * GET /api/v1/open/farms/{farmId}/devices
     * Device list.
     * pageSize max 100 for Open API.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listDevices(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);

        // Open API: pageSize capped at 100
        int effectivePageSize = Math.min(pageSize, 100);

        // Phase 1: Devices are listed by tenant. Farm-to-tenant mapping will be
        // added when cross-context device-farm association is implemented.
        Long tenantId = TenantContext.getCurrentTenant();
        List<DeviceDto> devices;
        if (tenantId != null) {
            devices = deviceApplicationService.listByTenant(tenantId);
        } else {
            // Open API requests don't go through JWT filter, so TenantContext may be null.
            // Phase 1: return empty list until farm-based device query is available.
            devices = List.of();
        }

        Map<String, Object> data = Map.of(
                "items", devices,
                "page", page,
                "pageSize", effectivePageSize,
                "total", devices.size()
        );

        return ResponseEntity.ok()
                .body(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/open/farms/{farmId}/devices/{deviceId}
     * Device detail.
     */
    @GetMapping("/{deviceId}")
    public ResponseEntity<ApiResponse<DeviceDto>> getDevice(
            @PathVariable Long farmId,
            @PathVariable Long deviceId,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.validateFarmAccess(apiKey, farmId);

        DeviceDto device = deviceApplicationService.getDevice(deviceId);
        return ResponseEntity.ok()
                .body(ApiResponse.ok(device));
    }

}
