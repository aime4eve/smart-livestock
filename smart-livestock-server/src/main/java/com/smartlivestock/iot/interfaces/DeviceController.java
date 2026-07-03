package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.command.RegisterDeviceCommand;
import com.smartlivestock.iot.application.command.UpdateDeviceCommand;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/devices")
@RequiredArgsConstructor
public class DeviceController {

    private final DeviceApplicationService deviceApplicationService;

    /**
     * GET /api/v1/farms/{farmId}/devices
     * List devices for a farm (currently by tenant, farm filtering TBD).
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listDevices(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String keyword) {
        Long tenantId = TenantContext.getCurrentTenant();
        var result = deviceApplicationService.listByTenant(tenantId, keyword, page, pageSize);
        Map<String, Object> data = Map.of(
                "items", result.items(),
                "page", result.page(),
                "pageSize", result.pageSize(),
                "total", result.total()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/farms/{farmId}/devices
     * Register a new device.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<DeviceDto>> registerDevice(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        Long tenantId = TenantContext.getCurrentTenant();
        String deviceTypeStr = (String) body.get("deviceType");
        // API contract uses lowercase snake_case like "device_tracker"
        // Domain enum uses uppercase like "TRACKER"
        DeviceType deviceType = resolveDeviceType(deviceTypeStr);
       RegisterDeviceCommand command = new RegisterDeviceCommand(
               (String) body.get("deviceCode"),
               deviceType,
                tenantId,
                (String) body.get("devEui")
       );
        DeviceDto device = deviceApplicationService.registerDevice(command);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(device));
    }

    /**
     * GET /api/v1/farms/{farmId}/devices/{deviceId}
     * Get device detail.
     */
    @GetMapping("/{deviceId}")
    public ResponseEntity<ApiResponse<DeviceDto>> getDevice(
            @PathVariable Long farmId,
            @PathVariable Long deviceId) {
        DeviceDto device = deviceApplicationService.getDevice(deviceId);
        return ResponseEntity.ok(ApiResponse.ok(device));
    }

    /**
     * PUT /api/v1/farms/{farmId}/devices/{deviceId}
     * Update device info.
     */
    @PutMapping("/{deviceId}")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<DeviceDto>> updateDevice(
            @PathVariable Long farmId,
            @PathVariable Long deviceId,
            @RequestBody Map<String, Object> body) {
       // Current service only supports register/get/list/activate/decommission.
       // Return current device for now. Full update will be added when needed.
        UpdateDeviceCommand command = new UpdateDeviceCommand(
                (String) body.get("deviceCode"),
                (String) body.get("devEui")
        );
        DeviceDto device = deviceApplicationService.updateDevice(deviceId, command);
       return ResponseEntity.ok(ApiResponse.ok(device));
    }

    /**
     * PUT /api/v1/farms/{farmId}/devices/{deviceId}/activate
     * Activate device (inventory -> active).
     */
    @PutMapping("/{deviceId}/activate")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<DeviceDto>> activateDevice(
            @PathVariable Long farmId,
            @PathVariable Long deviceId) {
        deviceApplicationService.activateDevice(deviceId);
        DeviceDto device = deviceApplicationService.getDevice(deviceId);
        return ResponseEntity.ok(ApiResponse.ok(device));
    }

    /**
     * PUT /api/v1/farms/{farmId}/devices/{deviceId}/decommission
     * Decommission device.
     */
    @PutMapping("/{deviceId}/decommission")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<DeviceDto>> decommissionDevice(
            @PathVariable Long farmId,
            @PathVariable Long deviceId) {
        deviceApplicationService.decommissionDevice(deviceId);
        DeviceDto device = deviceApplicationService.getDevice(deviceId);
        return ResponseEntity.ok(ApiResponse.ok(device));
    }

    private DeviceType resolveDeviceType(String input) {
        if (input == null) return DeviceType.TRACKER;
        // API sends "device_tracker" or "tracker" — normalize to enum name
        String normalized = input.toUpperCase().replace("DEVICE_", "");
        try {
            return DeviceType.valueOf(normalized);
        } catch (IllegalArgumentException e) {
            return DeviceType.TRACKER;
        }
    }
}
