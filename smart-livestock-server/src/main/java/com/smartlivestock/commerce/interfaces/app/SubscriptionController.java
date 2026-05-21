package com.smartlivestock.commerce.interfaces.app;

import com.smartlivestock.commerce.application.dto.SubscriptionResponse;
import com.smartlivestock.commerce.application.query.SubscriptionQueryService;
import com.smartlivestock.commerce.application.service.SubscriptionApplicationService;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * App-facing subscription endpoints — 6 endpoints.
 * All endpoints operate on the authenticated tenant.
 */
@RestController
@RequestMapping("/api/v1/subscription")
@RequiredArgsConstructor
public class SubscriptionController {

    private final SubscriptionApplicationService subscriptionApplicationService;
    private final SubscriptionQueryService subscriptionQueryService;

    /**
     * GET /api/v1/subscription
     * Get current tenant's subscription.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<SubscriptionResponse>> getSubscription() {
        Long tenantId = requireTenantId();
        SubscriptionResponse sub = subscriptionQueryService.findByTenantId(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                        "Subscription not found for tenant: " + tenantId));
        return ResponseEntity.ok(ApiResponse.ok(sub));
    }

    /**
     * GET /api/v1/subscription/plans
     * Return hardcoded tier pricing from SubscriptionTier enum.
     */
    @GetMapping("/plans")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getPlans() {
        List<Map<String, Object>> plans = List.of(SubscriptionTier.values()).stream()
                .map(tier -> {
                    Map<String, Object> plan = new LinkedHashMap<>();
                    plan.put("tier", tier.name());
                    plan.put("monthlyPriceCents", tier.getMonthlyPriceCents());
                    plan.put("includedLivestock", tier.getIncludedLivestock());
                    plan.put("overagePriceCents", tier.getOveragePriceCents());
                    return plan;
                })
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(plans));
    }

    /**
     * POST /api/v1/subscription/checkout
     * Checkout / upgrade subscription.
     */
    @PostMapping("/checkout")
    public ResponseEntity<ApiResponse<SubscriptionResponse>> checkout(
            @RequestBody Map<String, String> body) {
        Long tenantId = requireTenantId();
        String tierStr = requireField(body, "tier");
        String billingCycle = requireField(body, "billingCycle");

        SubscriptionTier tier = parseTier(tierStr);
        subscriptionApplicationService.upgrade(tenantId, tier, billingCycle);

        SubscriptionResponse sub = subscriptionQueryService.findByTenantId(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                        "Subscription not found after checkout"));
        return ResponseEntity.ok(ApiResponse.ok(sub));
    }

    /**
     * PUT /api/v1/subscription/tier
     * Upgrade subscription tier.
     */
    @PutMapping("/tier")
    public ResponseEntity<ApiResponse<SubscriptionResponse>> upgradeTier(
            @RequestBody Map<String, String> body) {
        Long tenantId = requireTenantId();
        String tierStr = requireField(body, "tier");
        String billingCycle = body.get("billingCycle");

        SubscriptionTier tier = parseTier(tierStr);
        subscriptionApplicationService.upgrade(tenantId, tier, billingCycle);

        SubscriptionResponse sub = subscriptionQueryService.findByTenantId(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                        "Subscription not found after upgrade"));
        return ResponseEntity.ok(ApiResponse.ok(sub));
    }

    /**
     * POST /api/v1/subscription/cancel
     * Cancel subscription.
     */
    @PostMapping("/cancel")
    public ResponseEntity<ApiResponse<SubscriptionResponse>> cancel() {
        Long tenantId = requireTenantId();
        subscriptionApplicationService.cancel(tenantId);

        SubscriptionResponse sub = subscriptionQueryService.findByTenantId(tenantId)
                .orElseThrow(() -> new ApiException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                        "Subscription not found after cancel"));
        return ResponseEntity.ok(ApiResponse.ok(sub));
    }

    /**
     * GET /api/v1/subscription/usage
     * Return subscription usage summary with retention days and tier quota.
     */
    @GetMapping("/usage")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getUsage(
            @RequestParam(required = false) String featureKey) {
        Long tenantId = requireTenantId();

        Map<String, Object> usage = new LinkedHashMap<>();
        subscriptionQueryService.findByTenantId(tenantId).ifPresentOrElse(
                sub -> {
                    usage.put("subscriptionId", sub.getId());
                    usage.put("tier", sub.getTier());
                    usage.put("status", sub.getStatus());
                    usage.put("effectiveTier", sub.getEffectiveTier());

                    // Tier quota info
                    SubscriptionTier tier = parseTier(sub.getEffectiveTier() != null
                            ? sub.getEffectiveTier() : sub.getTier());
                    usage.put("includedLivestock", tier.getIncludedLivestock());
                    usage.put("overagePriceCents", tier.getOveragePriceCents());
                },
                () -> {
                    usage.put("tier", "BASIC");
                    usage.put("status", "FREE");
                }
        );

        // Optional retention days lookup
        if (featureKey != null && !featureKey.isBlank()) {
            subscriptionQueryService.getRetentionDays(tenantId, featureKey)
                    .ifPresent(days -> usage.put("retentionDays", days));
        }

        return ResponseEntity.ok(ApiResponse.ok(usage));
    }

    // ── Helpers ────────────────────────────────────────────────────

    private Long requireTenantId() {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证或缺少租户信息");
        }
        return tenantId;
    }

    private String requireField(Map<String, String> body, String field) {
        String value = body.get(field);
        if (value == null || value.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, field + " 不能为空");
        }
        return value;
    }

    private SubscriptionTier parseTier(String tierStr) {
        try {
            return SubscriptionTier.valueOf(tierStr.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "无效的订阅等级: " + tierStr);
        }
    }
}
