package com.smartlivestock.iot.interfaces.open;

import com.smartlivestock.identity.domain.model.ApiKey;
import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.ApiKeyAuthFilter;
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
    private final DeviceRepository deviceRepository;

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
        requireDeviceInTenant(deviceId, request);

        DeviceDto device = deviceApplicationService.getDevice(deviceId);
        return ResponseEntity.ok()
                .body(ApiResponse.ok(device));
    }

    /**
     * Devices carry no farm id, only a tenant; the requesting key's tenant
     * must own it (same rule as the NIX-323 telemetry endpoint, NIX-333).
     */
    private void requireDeviceInTenant(Long deviceId, HttpServletRequest request) {
        Device device = deviceRepository.findById(deviceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "设备不存在: " + deviceId));
        Object attr = request.getAttribute(ApiKeyAuthFilter.ATTR_API_KEY);
        if (!(attr instanceof ApiKey key)) {
            throw new ApiException(ErrorCode.AUTH_API_KEY_INVALID, "API Key 上下文缺失");
        }
        if (device.getTenantId() == null || !device.getTenantId().equals(key.getTenantId())) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "无权访问该设备");
        }
    }

}
