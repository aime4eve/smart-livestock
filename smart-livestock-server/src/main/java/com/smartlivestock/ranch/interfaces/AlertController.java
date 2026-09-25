package com.smartlivestock.ranch.interfaces;

import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.command.AcknowledgeAlertCommand;
import com.smartlivestock.ranch.application.command.ArchiveAlertCommand;
import com.smartlivestock.ranch.application.command.HandleAlertCommand;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.application.dto.AlertSummaryDto.AlertSummaryResponse;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
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

    @GetMapping("/alerts")
    public ResponseEntity<ApiResponse<Map<String, Object>>> listAlerts(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String severity,
            @RequestParam(required = false) String types,
            @RequestParam(required = false) Long fenceId,
            @RequestParam(defaultValue = "false") boolean unreadOnly) {
        Long userId = getCurrentUserId();
        int safePage = Math.max(page, 1);
        int safePageSize = Math.min(Math.max(pageSize, 1), 200);
        List<String> typeList = (types == null || types.isBlank())
                ? List.of()
                : List.of(types.split(","));
        AlertRepository.AlertPage<AlertDto> result = alertApplicationService.listByFarmPaged(
                farmId, userId, status, severity, typeList, fenceId, unreadOnly, safePage, safePageSize);
        Map<String, Object> data = Map.of(
                "items", result.items(),
                "page", safePage,
                "pageSize", safePageSize,
                "total", result.total()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * Farm-global alert counters for the summary strip and ranch badges.
     * Kept separate from the list so summary numbers never depend on
     * list filters or pagination windows. Optional {@code types} (comma
     * separated) scopes the counters to a category view.
     */
    @GetMapping("/alerts/summary")
    public ResponseEntity<ApiResponse<AlertSummaryResponse>> summary(
            @PathVariable Long farmId,
            @RequestParam(required = false) String types) {
        Long userId = getCurrentUserId();
        List<String> typeList = (types == null || types.isBlank())
                ? List.of()
                : List.of(types.split(","));
        return ResponseEntity.ok(ApiResponse.ok(
                alertApplicationService.getAlertSummary(farmId, userId, typeList)));
    }

    @GetMapping("/alerts/{alertId}")
    public ResponseEntity<ApiResponse<AlertDto>> getAlert(
            @PathVariable Long farmId,
            @PathVariable Long alertId) {
        Long userId = getCurrentUserId();
        AlertDto alert = alertApplicationService.getAlertWithReadStatus(alertId, userId);
        return ResponseEntity.ok(ApiResponse.ok(alert));
    }

    // ── Notification-center endpoints ──

    @PostMapping("/alerts/{alertId}/read")
    public ResponseEntity<ApiResponse<AlertDto>> markRead(
            @PathVariable Long farmId,
            @PathVariable Long alertId) {
        Long userId = getCurrentUserId();
        AlertDto alert = alertApplicationService.markRead(alertId, userId);
        return ResponseEntity.ok(ApiResponse.ok(alert));
    }

    @PostMapping("/alerts/{alertId}/dismiss")
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN', 'WORKER')")
    public ResponseEntity<ApiResponse<AlertDto>> dismissAlert(
            @PathVariable Long farmId,
            @PathVariable Long alertId) {
        Long userId = getCurrentUserId();
        AlertDto alert = alertApplicationService.dismiss(alertId, userId);
        return ResponseEntity.ok(ApiResponse.ok(alert));
    }

    @PostMapping("/alerts/batch-read")
    public ResponseEntity<ApiResponse<Map<String, Object>>> batchRead(
            @PathVariable Long farmId,
            @RequestBody Map<String, List<String>> body) {
        Long userId = getCurrentUserId();
        List<String> alertIdStrs = body.get("alertIds");
        if (alertIdStrs == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "alertIds 不能为空");
        }
        List<Long> alertIds = alertIdStrs.stream().map(Long::valueOf).toList();
        int count = alertApplicationService.batchRead(alertIds, userId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("count", count)));
    }

    // ── Legacy compatibility endpoints ──

    @PostMapping("/alerts/{alertId}/acknowledge")
    @Deprecated
    public ResponseEntity<ApiResponse<AlertDto>> acknowledgeAlert(
            @PathVariable Long farmId,
            @PathVariable Long alertId) {
        return markRead(farmId, alertId);
    }

    @PostMapping("/alerts/{alertId}/handle")
    @Deprecated
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN', 'WORKER')")
    public ResponseEntity<ApiResponse<AlertDto>> handleAlert(
            @PathVariable Long farmId,
            @PathVariable Long alertId) {
        return dismissAlert(farmId, alertId);
    }

    @PostMapping("/alerts/{alertId}/archive")
    @Deprecated
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyRole('OWNER', 'B2B_ADMIN')")
    public ResponseEntity<ApiResponse<AlertDto>> archiveAlert(
            @PathVariable Long farmId,
            @PathVariable Long alertId) {
        Long userId = getCurrentUserId();
        ArchiveAlertCommand command = new ArchiveAlertCommand(alertId, userId);
        AlertDto alert = alertApplicationService.archive(command);
        return ResponseEntity.ok(ApiResponse.ok(alert));
    }

    @PostMapping("/alerts/batch-handle")
    @Deprecated
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
