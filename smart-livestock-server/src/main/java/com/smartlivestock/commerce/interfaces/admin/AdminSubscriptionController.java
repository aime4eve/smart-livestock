package com.smartlivestock.commerce.interfaces.admin;

import com.smartlivestock.commerce.application.dto.SubscriptionResponse;
import com.smartlivestock.commerce.application.assembler.SubscriptionAssembler;
import com.smartlivestock.commerce.application.query.SubscriptionQueryService;
import com.smartlivestock.commerce.application.service.SubscriptionApplicationService;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.infrastructure.persistence.SpringDataSubscriptionRepository;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.SubscriptionMapper;
import com.smartlivestock.licensing.application.LicenseModeGuard;
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
 * <p>
 * NIX-184 T5 (design §11): the manual status change endpoint is disabled in
 * ONPREM mode where the subscription lifecycle is license-driven; HOSTED
 * behavior is unchanged.
 */
@RestController
@RequestMapping("/api/v1/admin/subscriptions")
@RequiredArgsConstructor
public class AdminSubscriptionController {

    private final SubscriptionApplicationService subscriptionApplicationService;
    private final SubscriptionQueryService subscriptionQueryService;
    private final SpringDataSubscriptionRepository springDataSubscriptionRepository;
    private final LicenseModeGuard licenseModeGuard;
    private final com.smartlivestock.identity.application.TenantZoneResolver tenantZoneResolver;

    /**
     * GET /api/v1/admin/subscriptions
     * List all subscriptions with optional status/tier filters and pagination.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> listSubscriptions(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) Long tenantId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String tier) {
        requirePlatformAdmin();

        List<Map<String, Object>> all = springDataSubscriptionRepository.findAll().stream()
                .map(SubscriptionMapper::toDomain)
                .map(SubscriptionAssembler::toResponse)
                .filter(sub -> tenantId == null || tenantId.equals(sub.getTenantId()))
                .filter(sub -> status == null || status.equalsIgnoreCase(sub.getStatus()))
                .filter(sub -> tier == null || tier.equalsIgnoreCase(sub.getTier()))
                .map(sub -> {
                    Map<String, Object> m = new java.util.LinkedHashMap<>();
                    m.put("id", sub.getId());
                    m.put("tenantId", sub.getTenantId());
                    m.put("tenantName", tenantZoneResolver.nameOf(sub.getTenantId()));
                    m.put("tier", sub.getTier());
                    m.put("status", sub.getStatus());
                    m.put("effectiveTier", sub.getEffectiveTier());
                    m.put("trialEndsAt", sub.getTrialEndsAt());
                    m.put("expiresAt", sub.getExpiresAt());
                    m.put("utcOffsetMinutes", tenantZoneResolver.utcOffsetMinutes(sub.getTenantId()));
                    return m;
                })
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
        // NIX-184 T5: ONPREM subscriptions are license-driven (design §11).
        licenseModeGuard.requireSelfServiceAllowed();

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
            // NIX-334: RENEWAL_FAILED cannot reactivate() (SUSPENDED/CANCELLED
            // only); an admin-confirmed offline repayment recovers it with a
            // fresh billing period instead.
            case "ACTIVE" -> {
                if (subscription.getStatus() == SubscriptionStatus.RENEWAL_FAILED) {
                    subscriptionApplicationService.recoverRenewalFailure(tenantId);
                } else {
                    subscriptionApplicationService.reactivate(tenantId);
                }
            }
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
