package com.smartlivestock.commerce.application.dto;

import com.smartlivestock.commerce.domain.model.SubscriptionTier;

import java.time.Instant;

/**
 * Response DTO for subscription read model. Pricing fields follow the
 * NIX-245 USD per-head-per-month model; all amounts are US cents.
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
    private int livestockCount;
    private String currency = "USD";
    private Integer livestockCap;
    private SubscriptionTier.PriceBand applicableBand;
    private Integer unitPriceUsdCents;
    private Integer monthlyFeeUsdCents;
    /** NIX-324 wall-clock health verdict (spec §2 matrix); never derive UI state from the raw status column. */
    private Health health;

    public record Health(
            String healthStatus,
            Integer level,
            boolean trialActive,
            String effectiveTier,
            Long daysToExpiry,
            boolean degraded,
            Instant terminatedAt,
            ExportWindow exportWindow) {}

    /** NIX-325 export entitlement; null unless a termination window is open. */
    public record ExportWindow(
            Instant terminatedAt,
            Instant windowEndsAt,
            Long daysLeft,
            Long latestJobId,
            String latestJobStatus,
            Instant latestJobDownloadedAt) {}

    public SubscriptionResponse() {
    }

    public Health getHealth() { return health; }
    public void setHealth(Health v) { this.health = v; }

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

    public int getLivestockCount() { return livestockCount; }
    public void setLivestockCount(int livestockCount) { this.livestockCount = livestockCount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public Integer getLivestockCap() { return livestockCap; }
    public void setLivestockCap(Integer livestockCap) { this.livestockCap = livestockCap; }

    public SubscriptionTier.PriceBand getApplicableBand() { return applicableBand; }
    public void setApplicableBand(SubscriptionTier.PriceBand applicableBand) { this.applicableBand = applicableBand; }

    public Integer getUnitPriceUsdCents() { return unitPriceUsdCents; }
    public void setUnitPriceUsdCents(Integer unitPriceUsdCents) { this.unitPriceUsdCents = unitPriceUsdCents; }

    public Integer getMonthlyFeeUsdCents() { return monthlyFeeUsdCents; }
    public void setMonthlyFeeUsdCents(Integer monthlyFeeUsdCents) { this.monthlyFeeUsdCents = monthlyFeeUsdCents; }
}
