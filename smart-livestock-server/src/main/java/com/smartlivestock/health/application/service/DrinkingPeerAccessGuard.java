package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * Premium gate for the drinking peer comparison (NIX-256 Task 5a).
 *
 * <p>Deliberately reuses the health context's existing subscription ACL —
 * {@link HealthSubscriptionPort#hasFeature} resolves the <b>request</b>
 * tenant from TenantContext (set by the JWT filter), reads its
 * subscription's effective tier, and consults the {@code feature_gates}
 * row — the exact mechanism that already gates {@code health_score} and
 * {@code estrus_detect} charts (V31 seed). A gate row for
 * {@code drinking_peer_comparison} is seeded by
 * {@code V20261005110000__seed_drinking_peer_comparison_gate.sql}:
 * basic/standard locked, premium/enterprise open, active trials resolve to
 * PREMIUM via {@code Subscription.effectiveTier()}.
 *
 * <p>Kept as an independent collaborator (spec: "Premium 校验类独立") so the
 * tier rule can evolve — e.g. a different feature key or a per-farm
 * override — without touching the aggregation service.
 */
@Service
@RequiredArgsConstructor
public class DrinkingPeerAccessGuard {

    /** feature_gates key for the drinking peer comparison. */
    static final String FEATURE_KEY = "drinking_peer_comparison";

    private final HealthSubscriptionPort healthSubscriptionPort;

    /**
     * Throw 403 error.drinking.premiumRequired unless the requesting
     * tenant's subscription unlocks the peer comparison.
     */
    public void requirePeerComparison() {
        if (!healthSubscriptionPort.hasFeature(FEATURE_KEY)) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.drinking.premiumRequired");
        }
    }
}
