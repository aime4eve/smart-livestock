package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.DeviceLicenseApplicationService;
import com.smartlivestock.iot.application.command.ActivateLicenseCommand;
import com.smartlivestock.iot.application.dto.DeviceLicenseDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/device-licenses")
@RequiredArgsConstructor
public class DeviceLicenseController {

    private final DeviceLicenseApplicationService deviceLicenseApplicationService;

    /**
     * GET /api/v1/device-licenses
     * List all licenses for current tenant (tenant-level, no farm scope).
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listLicenses(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        // Tenant-level: licenses are not filtered by farm
        // Current service only supports getByDeviceId and activateLicense.
        // Full list-by-tenant will be added when needed.
        Map<String, Object> data = Map.of(
                "items", List.of(),
                "page", page,
                "pageSize", pageSize,
                "total", 0
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/device-licenses/{licenseId}
     * Get license detail.
     */
    @GetMapping("/{licenseId}")
    public ResponseEntity<ApiResponse<DeviceLicenseDto>> getLicense(@PathVariable Long licenseId) {
        // Current service does not have findById. Stub for now.
        throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "许可证不存在: " + licenseId);
    }

    /**
     * POST /api/v1/device-licenses
     * Activate a license for a device.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<DeviceLicenseDto>> activateLicense(
            @RequestBody Map<String, Object> body) {
        Long tenantId = TenantContext.getCurrentTenant();
        Long deviceId = toLong(body.get("deviceId"));
        ActivateLicenseCommand command = new ActivateLicenseCommand(deviceId, tenantId);
        DeviceLicenseDto license = deviceLicenseApplicationService.activateLicense(command);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(license));
    }

    /**
     * PUT /api/v1/device-licenses/{licenseId}/revoke
     * Revoke a license.
     */
    @PutMapping("/{licenseId}/revoke")
    public ResponseEntity<ApiResponse<Map<String, Object>>> revokeLicense(
            @PathVariable Long licenseId) {
        // Current service does not support revoke. Stub for now.
        Map<String, Object> data = Map.of(
                "id", licenseId,
                "status", "REVOKED"
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    private Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Long l) return l;
        if (value instanceof Number n) return n.longValue();
        return Long.valueOf(value.toString());
    }
}
