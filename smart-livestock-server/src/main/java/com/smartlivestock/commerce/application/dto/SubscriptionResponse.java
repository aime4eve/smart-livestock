package com.smartlivestock.commerce.application.dto;

import java.time.Instant;

/**
 * Response DTO for subscription read model.
 */
public class SubscriptionResponse {

    private Long id;
    private Long tenantId;
    private String tier;
    private String billingModel;
    private String status;
    private String billingCycle;
    private Instant startedAt;
    private Instant expiresAt;
    private Instant trialEndsAt;
    private Instant cancelledAt;
    private String effectiveTier;

    public SubscriptionResponse() {
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public String getTier() { return tier; }
    public void setTier(String tier) { this.tier = tier; }

    public String getBillingModel() { return billingModel; }
    public void setBillingModel(String billingModel) { this.billingModel = billingModel; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

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

    public String getEffectiveTier() { return effectiveTier; }
    public void setEffectiveTier(String effectiveTier) { this.effectiveTier = effectiveTier; }
}
