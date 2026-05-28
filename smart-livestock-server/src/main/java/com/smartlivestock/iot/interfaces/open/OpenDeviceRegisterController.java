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
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
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
     * Phase 1: Idempotency-Key support is stub (Phase 2 with Redis).
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
                    .headers(rateLimitHeaders(100))
                    .body(ApiResponse.error(ErrorCode.VALIDATION_ERROR, "serialNo 不能为空"));
        }

        String deviceTypeStr = (String) body.get("deviceType");
        DeviceType deviceType = resolveDeviceType(deviceTypeStr);

        // Phase 1: Tenant ID from request context or stub.
        // Phase 2 will extract tenantId from the API Key lookup.
        Long tenantId = resolveTenantId(apiKey);

        RegisterDeviceCommand command = new RegisterDeviceCommand(serialNo, deviceType, tenantId);
        DeviceDto device = deviceApplicationService.registerDevice(command);

        HttpHeaders headers = rateLimitHeaders(100);
        if (idempotencyKey != null) {
            headers.set("Idempotency-Key", idempotencyKey);
            headers.set("X-Idempotency-Status", "MISS");  // Phase 1: always MISS
        }

        return ResponseEntity.status(HttpStatus.CREATED)
                .headers(headers)
                .body(ApiResponse.ok(device));
    }

    /**
     * Resolve device type from API contract string.
     * API uses lowercase snake_case: "device_tracker", "ear_tag", "capsule", "accelerometer"
     * Domain enum: TRACKER, EAR_TAG, CAPSULE, ACCELEROMETER
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

    /**
     * Phase 1: Extract tenant ID from API Key.
     * Phase 2 will look up api_keys table to resolve tenantId from key_hash.
     */
    private Long resolveTenantId(String apiKey) {
        // Phase 1 stub: return a default tenant ID.
        // In production, this will look up the api_keys table.
        // For now, return 1L (demo tenant) to allow basic functionality.
        if (apiKey != null && apiKey.startsWith("sl_test_")) {
            return 1L;  // Demo tenant
        }
        return 1L;  // Default
    }

    /**
     * Rate limit headers for device registration endpoint.
     * Device registration has higher limit: 100/min.
     */
    private HttpHeaders rateLimitHeaders(int limit) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("X-RateLimit-Limit", String.valueOf(limit));
        headers.set("X-RateLimit-Remaining", String.valueOf(limit - 1));
        headers.set("X-RateLimit-Reset", String.valueOf(Instant.now().plusSeconds(60).getEpochSecond()));
        return headers;
    }
}
