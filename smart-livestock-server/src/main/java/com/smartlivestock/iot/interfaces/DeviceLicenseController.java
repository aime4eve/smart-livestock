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
        Long tenantId = TenantContext.getCurrentTenant();
        List<DeviceLicenseDto> all = deviceLicenseApplicationService.listByTenant(tenantId);
        int total = all.size();
        int from = Math.min((page - 1) * pageSize, total);
        int to = Math.min(from + pageSize, total);

        Map<String, Object> data = Map.of(
                "items", all.subList(from, to),
                "page", page,
                "pageSize", pageSize,
                "total", total
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/device-licenses/{licenseId}
     * Get license detail.
     */
    @GetMapping("/{licenseId}")
    public ResponseEntity<ApiResponse<DeviceLicenseDto>> getLicense(@PathVariable Long licenseId) {
        DeviceLicenseDto license = deviceLicenseApplicationService.findById(licenseId);
        return ResponseEntity.ok(ApiResponse.ok(license));
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
    public ResponseEntity<ApiResponse<DeviceLicenseDto>> revokeLicense(
            @PathVariable Long licenseId) {
        DeviceLicenseDto revoked = deviceLicenseApplicationService.revoke(licenseId);
        return ResponseEntity.ok(ApiResponse.ok(revoked));
    }

    private Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Long l) return l;
        if (value instanceof Number n) return n.longValue();
        return Long.valueOf(value.toString());
    }
}
