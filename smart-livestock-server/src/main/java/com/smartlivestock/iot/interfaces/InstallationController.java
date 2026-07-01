package com.smartlivestock.iot.interfaces;

import com.smartlivestock.iot.application.InstallationApplicationService;
import com.smartlivestock.iot.application.command.InstallDeviceCommand;
import com.smartlivestock.iot.application.dto.InstallationDto;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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
    private final RanchQueryPort ranchQueryPort;

    /**
     * GET /api/v1/farms/{farmId}/installations
     * List installations for a farm.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listInstallations(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        List<Long> livestockIds = ranchQueryPort.findAllByFarmId(farmId).stream()
                .map(LivestockInfo::id).toList();
        List<InstallationDto> all = installationApplicationService.findByLivestockIds(livestockIds);
        int total = all.size();
        int from = Math.min((page - 1) * pageSize, total);
        int to = Math.min(from + pageSize, total);
        List<InstallationDto> items = all.subList(from, to);

        Map<String, Object> data = Map.of(
                "items", items,
                "page", page,
                "pageSize", pageSize,
                "total", total
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/farms/{farmId}/installations
     * Install a device onto a livestock.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
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
    public ResponseEntity<ApiResponse<InstallationDto>> getInstallation(
            @PathVariable Long farmId,
            @PathVariable Long installationId) {
        InstallationDto installation = installationApplicationService.findById(installationId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "安装记录不存在: " + installationId));
        return ResponseEntity.ok(ApiResponse.ok(installation));
    }

    /**
     * PUT /api/v1/farms/{farmId}/installations/{installationId}/uninstall
     * Uninstall (remove) a device from a livestock.
     */
    @PutMapping("/{installationId}/uninstall")
    @PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<InstallationDto>> uninstallDevice(
            @PathVariable Long farmId,
            @PathVariable Long installationId) {
        InstallationDto result = installationApplicationService.removeById(installationId);
        return ResponseEntity.ok(ApiResponse.ok(result));
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
