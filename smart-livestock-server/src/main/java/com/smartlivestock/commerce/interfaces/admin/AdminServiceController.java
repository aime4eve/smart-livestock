package com.smartlivestock.commerce.interfaces.admin;

import com.smartlivestock.commerce.domain.model.SubscriptionService;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.SubscriptionServiceRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.DomainEventPublisher;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Admin subscription-service management — 5 endpoints.
 * All operations require platform_admin role.
 */
@RestController
@RequestMapping("/api/v1/admin/subscription-services")
@RequiredArgsConstructor
public class AdminServiceController {

    private final SubscriptionServiceRepository subscriptionServiceRepository;
    private final DomainEventPublisher domainEventPublisher;

    /**
     * GET /api/v1/admin/subscription-services
     * List all subscription services.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listServices(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        requirePlatformAdmin();

        // Domain repository does not expose listAll; returns empty for now.
        // Will be addressed with a proper listing method in Phase 2.
        Map<String, Object> data = Map.of(
                "items", List.of(),
                "page", page,
                "pageSize", pageSize,
                "total", 0
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * POST /api/v1/admin/subscription-services
     * Provision a new licensed service.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> provisionService(
            @RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        Long tenantId = requireLong(body, "tenantId");
        String serviceName = requireString(body, "serviceName");
        String serviceKey = requireString(body, "serviceKey");
        String tierStr = (String) body.get("tier");
        SubscriptionTier tier = tierStr != null ? parseTier(tierStr) : SubscriptionTier.BASIC;
        Integer deviceQuota = body.containsKey("deviceQuota")
                ? ((Number) body.get("deviceQuota")).intValue()
                : null;

        SubscriptionService svc = SubscriptionService.provision(
                tenantId, serviceName, serviceKey, tier, deviceQuota);
        SubscriptionService saved = subscriptionServiceRepository.save(svc);
        domainEventPublisher.publishDomainEvents(saved);

        Map<String, Object> data = toServiceMap(saved);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/admin/subscription-services/{id}
     * Get service detail.
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getService(@PathVariable Long id) {
        requirePlatformAdmin();

        SubscriptionService svc = subscriptionServiceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Subscription service not found: " + id));
        return ResponseEntity.ok(ApiResponse.ok(toServiceMap(svc)));
    }

    /**
     * PUT /api/v1/admin/subscription-services/{id}/status
     * Change service status (activate / revoke).
     */
    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String targetStatus = body.get("targetStatus");
        if (targetStatus == null || targetStatus.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "targetStatus 不能为空");
        }

        SubscriptionService svc = subscriptionServiceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Subscription service not found: " + id));

        switch (targetStatus.toUpperCase()) {
            case "ACTIVE" -> svc.activate(Instant.now().plusSeconds(365L * 86400));
            case "EXPIRED" -> svc.revoke();
            default -> throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "不支持的目标状态: " + targetStatus);
        }

        SubscriptionService saved = subscriptionServiceRepository.save(svc);
        domainEventPublisher.publishDomainEvents(saved);
        return ResponseEntity.ok(ApiResponse.ok(toServiceMap(saved)));
    }

    /**
     * PUT /api/v1/admin/subscription-services/{id}/quota
     * Adjust device quota.
     */
    @PutMapping("/{id}/quota")
    public ResponseEntity<ApiResponse<Map<String, Object>>> adjustQuota(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        int newQuota = requireInt(body, "deviceQuota");

        SubscriptionService svc = subscriptionServiceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Subscription service not found: " + id));
        svc.adjustQuota(newQuota);
        SubscriptionService saved = subscriptionServiceRepository.save(svc);
        domainEventPublisher.publishDomainEvents(saved);

        return ResponseEntity.ok(ApiResponse.ok(toServiceMap(saved)));
    }

    // ── Helpers ────────────────────────────────────────────────────

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

    private Map<String, Object> toServiceMap(SubscriptionService svc) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", svc.getId());
        m.put("tenantId", svc.getTenantId());
        m.put("serviceName", svc.getServiceName());
        m.put("serviceKeyPrefix", svc.getServiceKeyPrefix());
        m.put("effectiveTier", svc.getEffectiveTier());
        m.put("deviceQuota", svc.getDeviceQuota());
        m.put("status", svc.getStatus() != null ? svc.getStatus().name() : null);
        m.put("lastHeartbeatAt", svc.getLastHeartbeatAt());
        m.put("startedAt", svc.getStartedAt());
        m.put("expiresAt", svc.getExpiresAt());
        return m;
    }

    private String requireString(Map<String, Object> body, String field) {
        Object value = body.get(field);
        if (value == null || value.toString().isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, field + " 不能为空");
        }
        return value.toString();
    }

    private Long requireLong(Map<String, Object> body, String field) {
        Object value = body.get(field);
        if (value == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, field + " 不能为空");
        }
        return ((Number) value).longValue();
    }

    private int requireInt(Map<String, Object> body, String field) {
        Object value = body.get(field);
        if (value == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, field + " 不能为空");
        }
        return ((Number) value).intValue();
    }

    private SubscriptionTier parseTier(String tierStr) {
        try {
            return SubscriptionTier.valueOf(tierStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "无效的订阅等级: " + tierStr);
        }
    }
}
