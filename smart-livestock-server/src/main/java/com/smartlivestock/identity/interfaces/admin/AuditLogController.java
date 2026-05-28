package com.smartlivestock.identity.interfaces.admin;

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

/**
 * Admin Audit Log — 1 endpoint.
 * Phase 1 stub: Returns placeholder data. Write side is handled by domain events.
 */
@RestController
@RequestMapping("/api/v1/admin/audit-logs")
@RequiredArgsConstructor
public class AuditLogController {

    /**
     * GET /api/v1/admin/audit-logs
     * Operation audit log with filters.
     * Phase 1 stub — returns empty list. Write side is handled by
     * Application Service domain events (AlertStatusChanged, DeviceActivated, etc.).
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listAuditLogs(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) Long tenantId,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {
        requirePlatformAdmin();

        // Phase 1 stub: no audit log storage yet
        List<Map<String, Object>> items = List.of();

        Map<String, Object> data = Map.of(
                "items", items,
                "page", page,
                "pageSize", pageSize,
                "total", 0
        );
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
}
