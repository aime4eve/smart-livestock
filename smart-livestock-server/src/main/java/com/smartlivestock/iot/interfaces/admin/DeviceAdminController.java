package com.smartlivestock.iot.interfaces.admin;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.application.dto.DeviceTransferLookupDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Platform-admin device ownership handover (ruling 2026-10-19).
 * The provisioning wizard's cross-tenant EUI guard tells customers to
 * "contact the platform admin for a handover" — these endpoints are that
 * handover: look up where an EUI lives, then move it to the target tenant
 * with guardrails and an audit trail (no direct DB edits).
 */
@RestController
@RequestMapping("/api/v1/admin/devices")
@RequiredArgsConstructor
public class DeviceAdminController {

    private final DeviceApplicationService deviceApplicationService;

    /**
     * GET /api/v1/admin/devices/lookup?eui=...
     * Where does the EUI live today (tenant + transfer blockers).
     */
    @GetMapping("/lookup")
    public ResponseEntity<ApiResponse<DeviceTransferLookupDto>> lookup(@RequestParam String eui) {
        requirePlatformAdmin();
        return ResponseEntity.ok(ApiResponse.ok(deviceApplicationService.lookupForTransfer(eui)));
    }

    /**
     * POST /api/v1/admin/devices/transfer
     * body: {"devEui": "...", "targetTenantId": 2}
     */
    @PostMapping("/transfer")
    public ResponseEntity<ApiResponse<Map<String, Object>>> transfer(@RequestBody Map<String, Object> body) {
        requirePlatformAdmin();
        Object euiObj = body.get("devEui");
        Object tenantIdObj = body.get("targetTenantId");
        if (euiObj == null || euiObj.toString().isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.deviceTransferEuiRequired");
        }
        if (tenantIdObj == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.deviceTransferTenantRequired");
        }
        Long targetTenantId;
        try {
            targetTenantId = Long.valueOf(tenantIdObj.toString());
        } catch (NumberFormatException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.deviceTransferTenantRequired");
        }

        DeviceDto device = deviceApplicationService.transferToTenant(
                euiObj.toString().trim(), targetTenantId, currentUserId());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", device.id());
        data.put("devEui", device.devEui());
        data.put("deviceCode", device.deviceCode());
        data.put("deviceType", device.deviceType());
        data.put("status", device.status());
        data.put("tenantId", device.tenantId() != null ? String.valueOf(device.tenantId()) : "");
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    private void requirePlatformAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_PLATFORM_ADMIN"));
        if (!isAdmin) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "需要 platform_admin 角色");
        }
    }

    private Long currentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof Long userId) {
            return userId;
        }
        return null;
    }
}
