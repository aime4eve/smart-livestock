package com.smartlivestock.licensing.application.port;

import java.time.Instant;
import java.util.Optional;

/**
 * Port owned by the licensing context (design §10, NIX-184) and implemented
 * by the commerce context via {@code CommerceLicenseAdapter}.
 * <p>
 * Lets licensing drive subscription lifecycle transitions (trial grants,
 * activation, downgrade, suspension) without depending on commerce domain
 * types directly.
 */
public interface LicenseSubscriptionPort {

    /**
     * Read-only snapshot of the tenant's current subscription, used by
     * licensing services to decide which transition to apply.
     */
    Optional<LicenseSubscriptionSnapshot> findSubscription(Long tenantId);

    /**
     * Create a TRIAL subscription when none exists, otherwise extend the
     * existing TRIAL end timestamp (never shortens it).
     *
     * @param tenantId     target tenant
     * @param trialEndsAt  desired trial end timestamp
     */
    void applyTrialLicense(Long tenantId, Instant trialEndsAt);

    /**
     * Move the subscription to ACTIVE with the given tier. Allowed from
     * TRIAL, FREE, or ACTIVE; any other state throws a state conflict.
     * Reserved for paid-license activation (task T4).
     *
     * @param tenantId  target tenant
     * @param tier      tier name (BASIC/PREMIUM/ENTERPRISE; STANDARD allowed)
     * @param expiresAt new subscription expiry timestamp
     */
    void applyActiveLicense(Long tenantId, String tier, Instant expiresAt);

    /**
     * Downgrade the subscription to FREE/BASIC (license expiry path).
     * Allowed from TRIAL or RENEWAL_FAILED; FREE is an idempotent no-op;
     * any other state throws a state conflict.
     */
    void downgradeForLicense(Long tenantId);

    /**
     * Suspend the subscription (license suspension path).
     * Allowed from ACTIVE; SUSPENDED is an idempotent no-op; any other
     * state throws a state conflict.
     *
     * @param tenantId target tenant
     * @param reason   human-readable suspension reason (audit/troubleshooting)
     */
    void suspendForLicense(Long tenantId, String reason);

    /**
     * Decoupled view of the commerce subscription state. {@code status} is
     * the {@code SubscriptionStatus} enum name; {@code trialActive} mirrors
     * {@code Subscription.isTrialActive()}.
     */
    record LicenseSubscriptionSnapshot(String status, Instant trialEndsAt, boolean trialActive) {
    }
}
