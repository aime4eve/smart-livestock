package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.command.AcknowledgeAlertCommand;
import com.smartlivestock.ranch.application.command.ArchiveAlertCommand;
import com.smartlivestock.ranch.application.command.HandleAlertCommand;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}")
@RequiredArgsConstructor
public class AlertController {

    private final AlertApplicationService alertApplicationService;

    /**
     * GET /api/v1/farms/{farmId}/alerts
     * List alerts for a farm with optional filters.
     */
    @GetMapping("/alerts")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listAlerts(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String severity,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        List<AlertDto> alerts;
        if (status != null) {
            AlertStatus alertStatus = AlertStatus.valueOf(status.toUpperCase());
            alerts = alertApplicationService.listByFarmAndStatus(farmId, alertStatus);
        } else {
            alerts = alertApplicationService.listByFarm(farmId);
        }
        Map<String, Object> data = Map.of(
                "items", alerts,
                "page", page,
                "pageSize", pageSize,
                "total", alerts.size()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/farms/{farmId}/alerts/{alertId}
     * Get alert detail.
     */
    @GetMapping("/alerts/{alertId}")
    public ResponseEntity<ApiResponse<AlertDto>> getAlert(
            @PathVariable Long farmId,
            @PathVariable Long alertId) {
        AlertDto alert = alertApplicationService.getAlert(alertId);
        return ResponseEntity.ok(ApiResponse.ok(alert));
    }

    /**
     * POST /api/v1/farms/{farmId}/alerts/{alertId}/acknowledge
     * Acknowledge alert (pending -> acknowledged).
     */
    @PostMapping("/alerts/{alertId}/acknowledge")
    public ResponseEntity<ApiResponse<AlertDto>> acknowledgeAlert(
            @PathVariable Long farmId,
            @PathVariable Long alertId) {
        Long userId = getCurrentUserId();
        AcknowledgeAlertCommand command = new AcknowledgeAlertCommand(alertId, userId);
        AlertDto alert = alertApplicationService.acknowledge(command);
        return ResponseEntity.ok(ApiResponse.ok(alert));
    }

    /**
     * POST /api/v1/farms/{farmId}/alerts/{alertId}/handle
     * Handle alert (acknowledged -> handled). Requires OWNER or B2B_ADMIN.
     */
    @PostMapping("/alerts/{alertId}/handle")
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<AlertDto>> handleAlert(
            @PathVariable Long farmId,
            @PathVariable Long alertId) {
        Long userId = getCurrentUserId();
        HandleAlertCommand command = new HandleAlertCommand(alertId, userId);
        AlertDto alert = alertApplicationService.handle(command);
        return ResponseEntity.ok(ApiResponse.ok(alert));
    }

    /**
     * POST /api/v1/farms/{farmId}/alerts/{alertId}/archive
     * Archive alert (handled -> archived). Requires OWNER or B2B_ADMIN.
     */
    @PostMapping("/alerts/{alertId}/archive")
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<AlertDto>> archiveAlert(
            @PathVariable Long farmId,
            @PathVariable Long alertId) {
        Long userId = getCurrentUserId();
        ArchiveAlertCommand command = new ArchiveAlertCommand(alertId, userId);
        AlertDto alert = alertApplicationService.archive(command);
        return ResponseEntity.ok(ApiResponse.ok(alert));
    }

    /**
     * POST /api/v1/farms/{farmId}/alerts/batch-handle
     * Batch handle alerts. Requires OWNER or B2B_ADMIN.
     */
    @PostMapping("/alerts/batch-handle")
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> batchHandleAlerts(
            @PathVariable Long farmId,
            @RequestBody Map<String, List<String>> body) {
        Long userId = getCurrentUserId();
        List<String> alertIds = body.get("alertIds");
        if (alertIds == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "alertIds 不能为空");
        }
        int handledCount = 0;
        for (String alertIdStr : alertIds) {
            try {
                Long alertId = Long.valueOf(alertIdStr);
                HandleAlertCommand command = new HandleAlertCommand(alertId, userId);
                alertApplicationService.handle(command);
                handledCount++;
            } catch (ApiException e) {
                // Skip alerts that cannot be handled
            }
        }
        return ResponseEntity.ok(ApiResponse.ok(Map.of("handledCount", handledCount)));
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        return (Long) authentication.getPrincipal();
    }
}
