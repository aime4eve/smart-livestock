package com.smartlivestock.identity.interfaces.admin;

import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
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
 * Admin Audit Log — query endpoint.
 * Write side is handled by AuditLogEventListener which listens to all DomainEvents.
 */
@RestController
@RequestMapping("/api/v1/admin/audit-logs")
@RequiredArgsConstructor
public class AuditLogController {

    private final AuditLogRepository auditLogRepository;

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

        List<AuditLog> items = auditLogRepository.findAll(page, pageSize, tenantId, userId, action, startTime, endTime);
        long total = auditLogRepository.count(tenantId, userId, action, startTime, endTime);

        List<Map<String, Object>> rows = items.stream().map(a -> Map.<String, Object>of(
                "id", a.getId(),
                "eventId", a.getEventId(),
                "eventType", a.getEventType(),
                "tenantId", (Object) (a.getTenantId() != null ? a.getTenantId() : ""),
                "userId", (Object) (a.getUserId() != null ? a.getUserId() : ""),
                "action", a.getAction(),
                "details", a.getDetails() != null ? a.getDetails() : Map.of(),
                "occurredAt", a.getOccurredAt().toString(),
                "createdAt", a.getCreatedAt() != null ? a.getCreatedAt().toString() : ""
        )).toList();

        Map<String, Object> data = Map.of(
                "items", rows,
                "page", page,
                "pageSize", pageSize,
                "total", total
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
