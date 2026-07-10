package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.commerce.domain.model.event.RevenuePartnerConfirmedEvent;
import com.smartlivestock.commerce.domain.model.event.RevenuePeriodCreatedEvent;
import com.smartlivestock.commerce.domain.model.event.RevenuePlatformConfirmedEvent;
import com.smartlivestock.commerce.domain.model.event.RevenueSettledEvent;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * RevenuePeriod aggregate root managing settlement periods for partner contracts.
 * <p>
 * State machine: PENDING -> confirmByPlatform() -> PLATFORM_CONFIRMED
 *   -> confirmByPartner() -> PARTNER_CONFIRMED
 *   -> settle() -> SETTLED
 */
public class RevenuePeriod extends AggregateRoot {

    private Long contractId;
    private Long tenantId;
    private LocalDate periodStart;
    private LocalDate periodEnd;
    private int grossAmount;
    private int platformShare;
    private int partnerShare;
    private BigDecimal revenueShareRatio;
    private RevenueSettlementStatus status;
    private Instant settledAt;

    /** No-arg constructor for JPA. */
    public RevenuePeriod() {
    }

    // ── Factory methods ──────────────────────────────────────────────

    /**
     * Create a new revenue period in PENDING status.
     *
     * @param contractId        the parent contract identifier
     * @param tenantId          the tenant identifier
     * @param periodStart       period start date
     * @param periodEnd         period end date
     * @param grossAmount       gross revenue in cents
     * @param platformShare     platform's share in cents
     * @param partnerShare      partner's share in cents
     * @param revenueShareRatio snapshot of contract's revenue share ratio
     * @return new RevenuePeriod in PENDING status
     */
    public static RevenuePeriod create(Long contractId, Long tenantId,
                                       LocalDate periodStart, LocalDate periodEnd,
                                       int grossAmount, int platformShare, int partnerShare,
                                       BigDecimal revenueShareRatio) {
        if (revenueShareRatio != null
            && revenueShareRatio.compareTo(BigDecimal.ZERO) < 0) {
            throw new DomainException(ErrorCode.INVALID_REVENUE_SHARE_RATIO,
                "Revenue share ratio must be >= 0");
        }
        if (revenueShareRatio != null
            && revenueShareRatio.compareTo(BigDecimal.ONE) >= 0) {
            throw new DomainException(ErrorCode.INVALID_REVENUE_SHARE_RATIO,
                "Revenue share ratio must be < 1");
        }
        if (periodEnd != null && periodStart != null && periodEnd.isBefore(periodStart)) {
            throw new DomainException(ErrorCode.VALIDATION_ERROR,
                "Period end must be on or after period start");
        }
        if (platformShare + partnerShare != grossAmount) {
            throw new DomainException(ErrorCode.VALIDATION_ERROR,
                "Platform share + partner share must equal gross amount");
        }

        RevenuePeriod period = new RevenuePeriod();
        period.contractId = contractId;
        period.tenantId = tenantId;
        period.periodStart = periodStart;
        period.periodEnd = periodEnd;
        period.grossAmount = grossAmount;
        period.platformShare = platformShare;
        period.partnerShare = partnerShare;
        period.revenueShareRatio = revenueShareRatio;
        period.status = RevenueSettlementStatus.PENDING;
        period.registerEvent(new RevenuePeriodCreatedEvent(contractId, tenantId));
        return period;
    }

    // ── State transitions ────────────────────────────────────────────

    /**
     * Confirm by platform (from PENDING).
     */
    public void confirmByPlatform() {
        requireStatus(RevenueSettlementStatus.PENDING, "confirmByPlatform");
        this.status = RevenueSettlementStatus.PLATFORM_CONFIRMED;
        registerEvent(new RevenuePlatformConfirmedEvent(contractId, tenantId));
    }

    /**
     * Confirm by partner (from PLATFORM_CONFIRMED).
     */
    public void confirmByPartner() {
        requireStatus(RevenueSettlementStatus.PLATFORM_CONFIRMED, "confirmByPartner");
        this.status = RevenueSettlementStatus.PARTNER_CONFIRMED;
        registerEvent(new RevenuePartnerConfirmedEvent(contractId, tenantId));
    }

    /**
     * Settle the period (from PARTNER_CONFIRMED).
     */
    public void settle(Instant settledAt) {
        requireStatus(RevenueSettlementStatus.PARTNER_CONFIRMED, "settle");
        this.status = RevenueSettlementStatus.SETTLED;
        this.settledAt = settledAt;
        registerEvent(new RevenueSettledEvent(contractId, tenantId));
    }

    /**
     * Recalculate amounts for an existing period, resetting to PENDING.
     * Allowed from any non-SETTLED status.
     */
    public void recalculate(int grossAmount, int platformShare, int partnerShare,
                            BigDecimal revenueShareRatio) {
        if (this.status == RevenueSettlementStatus.SETTLED) {
            throw new DomainException(ErrorCode.STATE_CONFLICT,
                "Cannot recalculate a settled period");
        }
        if (platformShare + partnerShare != grossAmount) {
            throw new DomainException(ErrorCode.VALIDATION_ERROR,
                "Platform share + partner share must equal gross amount");
        }
        this.grossAmount = grossAmount;
        this.platformShare = platformShare;
        this.partnerShare = partnerShare;
        this.revenueShareRatio = revenueShareRatio;
        this.status = RevenueSettlementStatus.PENDING;
        this.settledAt = null;
        registerEvent(new RevenuePeriodCreatedEvent(contractId, tenantId));
    }

    // ── Guards ───────────────────────────────────────────────────────

    private void requireStatus(RevenueSettlementStatus expected, String action) {
        if (this.status != expected) {
            throw new DomainException(ErrorCode.STATE_CONFLICT,
                "Cannot " + action + ": expected " + expected + " but was " + this.status);
        }
    }

    // ── Getters and Setters ──────────────────────────────────────────

    public Long getContractId() { return contractId; }
    public void setContractId(Long contractId) { this.contractId = contractId; }

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public LocalDate getPeriodStart() { return periodStart; }
    public void setPeriodStart(LocalDate periodStart) { this.periodStart = periodStart; }

    public LocalDate getPeriodEnd() { return periodEnd; }
    public void setPeriodEnd(LocalDate periodEnd) { this.periodEnd = periodEnd; }

    public int getGrossAmount() { return grossAmount; }
    public void setGrossAmount(int grossAmount) { this.grossAmount = grossAmount; }

    public int getPlatformShare() { return platformShare; }
    public void setPlatformShare(int platformShare) { this.platformShare = platformShare; }

    public int getPartnerShare() { return partnerShare; }
    public void setPartnerShare(int partnerShare) { this.partnerShare = partnerShare; }

    public BigDecimal getRevenueShareRatio() { return revenueShareRatio; }
    public void setRevenueShareRatio(BigDecimal revenueShareRatio) { this.revenueShareRatio = revenueShareRatio; }

    public RevenueSettlementStatus getStatus() { return status; }
    public void setStatus(RevenueSettlementStatus status) { this.status = status; }

    public Instant getSettledAt() { return settledAt; }
    public void setSettledAt(Instant settledAt) { this.settledAt = settledAt; }
}
