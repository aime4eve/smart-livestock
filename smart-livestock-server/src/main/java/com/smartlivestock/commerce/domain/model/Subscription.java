package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.commerce.domain.model.event.SubscriptionCancelledEvent;
import com.smartlivestock.commerce.domain.model.event.SubscriptionRenewalFailedEvent;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;
import com.smartlivestock.shared.domain.event.*;

import java.time.Instant;

/**
 * Subscription aggregate root managing tenant subscription lifecycle.
 * <p>
 * State machine: TRIAL -> ACTIVE -> SUSPENDED/RENEWAL_FAILED/CANCELLED/EXPIRED
 *                 TRIAL -> FREE (expireTrial)
 *                 TRIAL -> CANCELLED
 */
public class Subscription extends AggregateRoot {

    private Long tenantId;
    private SubscriptionTier tier;
    private String billingModel;
    private SubscriptionStatus status;
    private String billingCycle;
    private Instant startedAt;
    private Instant expiresAt;
    private Instant trialEndsAt;
    private Instant cancelledAt;

    /** No-arg constructor for JPA. */
    public Subscription() {
    }

    // ── Factory methods ──────────────────────────────────────────────

    /**
     * Start a trial subscription for a tenant.
     *
     * @param tenantId    the tenant identifier
     * @param billingModel billing model string (e.g. "direct", "revenue_share")
     * @param startedAt   trial start timestamp
     * @param trialEndsAt trial end timestamp
     * @return new Subscription in TRIAL status
     */
    public static Subscription startTrial(Long tenantId, String billingModel,
                                          Instant startedAt, Instant trialEndsAt) {
        Subscription sub = new Subscription();
        sub.tenantId = tenantId;
        sub.tier = SubscriptionTier.BASIC;
        sub.billingModel = billingModel;
        sub.status = SubscriptionStatus.TRIAL;
        sub.startedAt = startedAt;
        sub.trialEndsAt = trialEndsAt;
        sub.registerEvent(new SubscriptionCreatedEvent(tenantId, "BASIC"));
        return sub;
    }

    // ── State transitions ────────────────────────────────────────────

    /**
     * Activate the subscription (from TRIAL).
     */
    public void activate(SubscriptionTier newTier, String billingCycle, Instant expiresAt) {
        requireStatus(SubscriptionStatus.TRIAL, "activate");
        this.tier = newTier;
        this.billingCycle = billingCycle;
        this.expiresAt = expiresAt;
        this.status = SubscriptionStatus.ACTIVE;
        registerEvent(new SubscriptionCreatedEvent(tenantId, newTier.name()));
    }

    /**
     * Expire the trial, transitioning to FREE with BASIC tier.
     */
    public void expireTrial() {
        requireStatus(SubscriptionStatus.TRIAL, "expireTrial");
        SubscriptionTier oldTier = this.tier;
        this.status = SubscriptionStatus.FREE;
        this.tier = SubscriptionTier.BASIC;
        registerEvent(new SubscriptionTierChangedEvent(tenantId, oldTier.name(), "FREE"));
    }

    /**
     * Change tier. Allowed from ACTIVE, TRIAL, or FREE.
     * When coming from FREE, transitions to ACTIVE.
     */
    public void changeTier(SubscriptionTier newTier, String billingCycle, Instant expiresAt) {
        requireStatusFor("changeTier",
            SubscriptionStatus.ACTIVE, SubscriptionStatus.TRIAL, SubscriptionStatus.FREE);
        SubscriptionTier oldTier = this.tier;
        this.tier = newTier;
        this.billingCycle = billingCycle;
        this.expiresAt = expiresAt;
        if (this.status == SubscriptionStatus.FREE || this.status == SubscriptionStatus.TRIAL) {
            this.status = SubscriptionStatus.ACTIVE;
        }
        registerEvent(new SubscriptionTierChangedEvent(tenantId, oldTier.name(), newTier.name()));
    }

    /**
     * Suspend the subscription (from ACTIVE).
     */
    public void suspend() {
        requireStatus(SubscriptionStatus.ACTIVE, "suspend");
        this.status = SubscriptionStatus.SUSPENDED;
        registerEvent(new SubscriptionSuspendedEvent(tenantId));
    }

    /**
     * Reactivate a suspended subscription.
     */
    public void reactivate() {
        requireStatus(SubscriptionStatus.SUSPENDED, "reactivate");
        this.status = SubscriptionStatus.ACTIVE;
        registerEvent(new SubscriptionReactivatedEvent(tenantId));
    }

    /**
     * Mark renewal as failed (from ACTIVE).
     */
    public void markRenewalFailed() {
        requireStatus(SubscriptionStatus.ACTIVE, "markRenewalFailed");
        this.status = SubscriptionStatus.RENEWAL_FAILED;
        registerEvent(new SubscriptionRenewalFailedEvent(tenantId));
    }

    /**
     * Recover from renewal failure back to ACTIVE.
     */
    public void recoverFromRenewalFailure() {
        requireStatus(SubscriptionStatus.RENEWAL_FAILED, "recoverFromRenewalFailure");
        this.status = SubscriptionStatus.ACTIVE;
        registerEvent(new SubscriptionReactivatedEvent(tenantId));
    }

    /**
     * Downgrade to FREE after renewal failure.
     */
    public void downgradeAfterRenewalFailure() {
        requireStatus(SubscriptionStatus.RENEWAL_FAILED, "downgradeAfterRenewalFailure");
        SubscriptionTier oldTier = this.tier;
        this.tier = SubscriptionTier.BASIC;
        this.status = SubscriptionStatus.FREE;
        registerEvent(new SubscriptionTierChangedEvent(tenantId, oldTier.name(), "FREE"));
    }

    /**
     * Cancel the subscription. Allowed from ACTIVE or TRIAL.
     *
     * @param cancelledAt the timestamp when cancellation occurs
     */
    public void cancel(Instant cancelledAt) {
        requireStatusFor("cancel",
            SubscriptionStatus.ACTIVE, SubscriptionStatus.TRIAL);
        this.status = SubscriptionStatus.CANCELLED;
        this.cancelledAt = cancelledAt;
        registerEvent(new SubscriptionCancelledEvent(tenantId));
    }

    /**
     * Mark the subscription as expired. Allowed from ACTIVE.
     */
    public void markExpired() {
        requireStatus(SubscriptionStatus.ACTIVE, "markExpired");
        this.status = SubscriptionStatus.EXPIRED;
        registerEvent(new SubscriptionExpiredEvent(tenantId));
    }

    // ── Business query methods ───────────────────────────────────────

    /**
     * Returns PREMIUM during active trial, otherwise the actual tier.
     */
    public SubscriptionTier effectiveTier() {
        if (isTrialActive()) {
            return SubscriptionTier.PREMIUM;
        }
        return this.tier;
    }

    /**
     * Whether the subscription is in an active trial period.
     */
    public boolean isTrialActive() {
        return status == SubscriptionStatus.TRIAL
            && trialEndsAt != null
            && trialEndsAt.isAfter(Instant.now());
    }

    /**
     * Whether the subscription is considered active (for feature gating).
     */
    public boolean isActiveOrTrial() {
        return status == SubscriptionStatus.ACTIVE
            || status == SubscriptionStatus.TRIAL
            || status == SubscriptionStatus.FREE;
    }

    // ── Guards ───────────────────────────────────────────────────────

    private void requireStatus(SubscriptionStatus expected, String action) {
        if (this.status != expected) {
            throw new DomainException(ErrorCode.STATE_CONFLICT,
                "Cannot " + action + ": expected " + expected + " but was " + this.status);
        }
    }

    private void requireStatusFor(String action, SubscriptionStatus... allowed) {
        for (SubscriptionStatus s : allowed) {
            if (this.status == s) return;
        }
        throw new DomainException(ErrorCode.STATE_CONFLICT,
            "Cannot " + action + ": current status is " + this.status);
    }

    // ── Getters and Setters ──────────────────────────────────────────

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public SubscriptionTier getTier() { return tier; }
    public void setTier(SubscriptionTier tier) { this.tier = tier; }

    public String getBillingModel() { return billingModel; }
    public void setBillingModel(String billingModel) { this.billingModel = billingModel; }

    public SubscriptionStatus getStatus() { return status; }
    public void setStatus(SubscriptionStatus status) { this.status = status; }

    public String getBillingCycle() { return billingCycle; }
    public void setBillingCycle(String billingCycle) { this.billingCycle = billingCycle; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public Instant getTrialEndsAt() { return trialEndsAt; }
    public void setTrialEndsAt(Instant trialEndsAt) { this.trialEndsAt = trialEndsAt; }

    public Instant getCancelledAt() { return cancelledAt; }
    public void setCancelledAt(Instant cancelledAt) { this.cancelledAt = cancelledAt; }
}
