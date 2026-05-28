package com.smartlivestock.commerce.interfaces.admin;

import com.smartlivestock.commerce.application.dto.SubscriptionResponse;
import com.smartlivestock.commerce.application.assembler.SubscriptionAssembler;
import com.smartlivestock.commerce.application.query.SubscriptionQueryService;
import com.smartlivestock.commerce.application.service.SubscriptionApplicationService;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.infrastructure.persistence.SpringDataSubscriptionRepository;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.SubscriptionMapper;
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
 * Admin subscription management — 3 endpoints.
 * All operations require platform_admin role.
 */
@RestController
@RequestMapping("/api/v1/admin/subscriptions")
@RequiredArgsConstructor
public class AdminSubscriptionController {

    private final SubscriptionApplicationService subscriptionApplicationService;
    private final SubscriptionQueryService subscriptionQueryService;
    private final SpringDataSubscriptionRepository springDataSubscriptionRepository;

    /**
     * GET /api/v1/admin/subscriptions
     * List all subscriptions with optional status/tier filters and pagination.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listSubscriptions(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String tier) {
        requirePlatformAdmin();

        List<SubscriptionResponse> all = springDataSubscriptionRepository.findAll().stream()
                .map(SubscriptionMapper::toDomain)
                .map(SubscriptionAssembler::toResponse)
                .filter(sub -> status == null || status.equalsIgnoreCase(sub.getStatus()))
                .filter(sub -> tier == null || tier.equalsIgnoreCase(sub.getTier()))
                .toList();

        Map<String, Object> data = Map.of(
                "items", all,
                "page", page,
                "pageSize", pageSize,
                "total", all.size()
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    /**
     * GET /api/v1/admin/subscriptions/{id}
     * Get subscription detail.
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SubscriptionResponse>> getSubscription(@PathVariable Long id) {
        requirePlatformAdmin();

        Subscription subscription = springDataSubscriptionRepository.findById(id)
                .map(SubscriptionMapper::toDomain)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Subscription not found: " + id));
        return ResponseEntity.ok(ApiResponse.ok(SubscriptionAssembler.toResponse(subscription)));
    }

    /**
     * PUT /api/v1/admin/subscriptions/{id}/status
     * Change subscription status (suspend / reactivate / cancel).
     */
    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<SubscriptionResponse>> updateStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        requirePlatformAdmin();

        String targetStatus = body.get("targetStatus");
        if (targetStatus == null || targetStatus.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "targetStatus 不能为空");
        }

        // Resolve tenantId from subscription
        Subscription subscription = springDataSubscriptionRepository.findById(id)
                .map(SubscriptionMapper::toDomain)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Subscription not found: " + id));
        Long tenantId = subscription.getTenantId();

        switch (targetStatus.toUpperCase()) {
            case "SUSPENDED" -> subscriptionApplicationService.suspend(tenantId);
            case "ACTIVE" -> subscriptionApplicationService.reactivate(tenantId);
            case "CANCELLED" -> subscriptionApplicationService.cancel(tenantId);
            default -> throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "不支持的目标状态: " + targetStatus);
        }

        SubscriptionResponse updated = subscriptionQueryService.findByTenantId(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                        "Subscription not found after status change"));
        return ResponseEntity.ok(ApiResponse.ok(updated));
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
}
