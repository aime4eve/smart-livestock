package com.smartlivestock.iot.interfaces.open;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.command.RegisterDeviceCommand;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.ApiKeyAuthService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Open API — Device Self-Registration (write), 1 endpoint.
 * Devices register themselves using a dedicated API Key with device:register scope.
 * The device enters INVENTORY status (tenant-level, not yet assigned to a farm).
 */
@RestController
@RequestMapping("/api/v1/open/devices")
@RequiredArgsConstructor
public class OpenDeviceRegisterController {

    private final DeviceApplicationService deviceApplicationService;
    private final ApiKeyAuthService apiKeyAuthService;

    /**
     * POST /api/v1/open/devices/register
     * Device self-registration.
     *
     * Request body: { "serialNo": "SN-2026-00001", "deviceType": "device_tracker", "firmwareVersion": "v2.1.3" }
     *
     * Uses device-specific API Key (scopes: ["device:register"]).
     * Device created in INVENTORY status at tenant level.
     *
     * Idempotency-Key: returns MISS until Phase 2 (Redis-backed).
     */
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<DeviceDto>> registerDevice(
            @RequestBody Map<String, Object> body,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            HttpServletRequest request) {
        String apiKey = apiKeyAuthService.requireApiKey(request);
        apiKeyAuthService.requireDeviceRegisterScope(apiKey);

        String serialNo = (String) body.get("serialNo");
        if (serialNo == null || serialNo.isBlank()) {
            // Fall back to deviceCode if serialNo not provided
            serialNo = (String) body.get("deviceCode");
        }
        if (serialNo == null || serialNo.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(ErrorCode.VALIDATION_ERROR, "serialNo 不能为空"));
        }

        String deviceTypeStr = (String) body.get("deviceType");
        DeviceType deviceType = resolveDeviceType(deviceTypeStr);

        // Tenant ID extracted from the API Key lookup.
        Long tenantId = resolveTenantId(apiKey);

        RegisterDeviceCommand command = new RegisterDeviceCommand(serialNo, deviceType, tenantId);
        DeviceDto device = deviceApplicationService.registerDevice(command);

        if (idempotencyKey != null) {
            return ResponseEntity.status(HttpStatus.CREATED)
                    .header("Idempotency-Key", idempotencyKey)
                    .header("X-Idempotency-Status", "MISS")  // Phase 1: always MISS
                    .body(ApiResponse.ok(device));
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(device));
    }

    /**
     * Resolve device type from API contract string.
     * API uses lowercase snake_case: "device_tracker", "ear_tag", "capsule"
     * Domain enum: TRACKER, EAR_TAG, CAPSULE
     */
    private DeviceType resolveDeviceType(String input) {
        if (input == null) return DeviceType.TRACKER;
        String normalized = input.toUpperCase().replace("DEVICE_", "");
        try {
            return DeviceType.valueOf(normalized);
        } catch (IllegalArgumentException e) {
            return DeviceType.TRACKER;
        }
    }

    private Long resolveTenantId(String apiKey) {
        return apiKeyAuthService.validateRawKey(apiKey).getTenantId();
    }

}
