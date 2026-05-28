package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.InstallationApplicationService;
import com.smartlivestock.iot.application.command.InstallDeviceCommand;
import com.smartlivestock.iot.application.dto.InstallationDto;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/installations")
@RequiredArgsConstructor
public class InstallationController {

    private final InstallationApplicationService installationApplicationService;

    /**
     * GET /api/v1/farms/{farmId}/installations
     * List installations for a farm.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listInstallations(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        // Current service does not have listByFarm. Stub for now.
        Map<String, Object> data = Map.of(
                "items", List.of(),
                "page", page,
                "pageSize", pageSize,
                "total", 0
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/farms/{farmId}/installations
     * Install a device onto a livestock.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<InstallationDto>> installDevice(
            @PathVariable Long farmId,
            @RequestBody Map<String, Object> body) {
        Long operatorId = getCurrentUserId();
        Long deviceId = toLong(body.get("deviceId"));
        Long livestockId = toLong(body.get("livestockId"));
        InstallDeviceCommand command = new InstallDeviceCommand(deviceId, livestockId, operatorId);
        InstallationDto installation = installationApplicationService.install(command);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(installation));
    }

    /**
     * GET /api/v1/farms/{farmId}/installations/{installationId}
     * Get installation detail.
     */
    @GetMapping("/{installationId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getInstallation(
            @PathVariable Long farmId,
            @PathVariable Long installationId) {
        // Current service only has getActiveInstallation(deviceId).
        // Return stub for now.
        throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "安装记录不存在: " + installationId);
    }

    /**
     * PUT /api/v1/farms/{farmId}/installations/{installationId}/uninstall
     * Uninstall (remove) a device from a livestock.
     */
    @PutMapping("/{installationId}/uninstall")
    public ResponseEntity<ApiResponse<Map<String, Object>>> uninstallDevice(
            @PathVariable Long farmId,
            @PathVariable Long installationId) {
        // Current service uses remove(deviceId), not remove(installationId).
        // This is a gap that needs to be addressed. For now, stub response.
        Long operatorId = getCurrentUserId();
        Map<String, Object> data = Map.of(
                "id", installationId,
                "message", "uninstall endpoint — service layer needs removeById support"
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        return (Long) authentication.getPrincipal();
    }

    private Long toLong(Object value) {
        if (value == null) return null;
        if (value instanceof Long l) return l;
        if (value instanceof Number n) return n.longValue();
        return Long.valueOf(value.toString());
    }
}
