package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.commerce.domain.model.event.ContractCreatedEvent;
import com.smartlivestock.commerce.domain.model.event.ContractExpiredEvent;
import com.smartlivestock.commerce.domain.model.event.ContractReactivatedEvent;
import com.smartlivestock.commerce.domain.model.event.ContractSuspendedEvent;
import com.smartlivestock.commerce.domain.model.event.ContractTerminatedEvent;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;
import com.smartlivestock.shared.domain.event.ContractSignedEvent;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Contract aggregate root managing B2B partner contracts.
 * <p>
 * State machine: DRAFT -> sign() -> ACTIVE
 *   ACTIVE -> suspend() -> SUSPENDED -> reactivate() -> ACTIVE
 *   ACTIVE -> terminate() -> TERMINATED
 *   ACTIVE -> markExpired() -> EXPIRED
 */
public class Contract extends AggregateRoot {

    private Long tenantId;
    private String contractNumber;
    private String billingModel;
    private String effectiveTier;
    private BigDecimal revenueShareRatio;
    private ContractStatus status;
    private Long signedBy;
    private Instant signedAt;
    private Instant startedAt;
    private Instant expiresAt;

    /** Nested result record for revenue share calculation. */
    public record RevenueShareResult(int platformShare, int partnerShare) {}

    /** No-arg constructor for JPA. */
    public Contract() {
    }

    // ── Factory methods ──────────────────────────────────────────────

    /**
     * Create a new contract in DRAFT status.
     *
     * @param tenantId          the tenant identifier
     * @param contractNumber    unique contract number
     * @param billingModel      billing model (e.g. "revenue_share", "direct")
     * @param effectiveTier     effective subscription tier
     * @param revenueShareRatio partner's share ratio (required for "revenue_share" model)
     * @param startedAt         contract start timestamp
     * @return new Contract in DRAFT status
     */
    public static Contract create(Long tenantId, String contractNumber, String billingModel,
                                  String effectiveTier, BigDecimal revenueShareRatio,
                                  Instant startedAt) {
        if ("revenue_share".equals(billingModel)) {
            validateRevenueShareRatio(revenueShareRatio);
        }

        Contract contract = new Contract();
        contract.tenantId = tenantId;
        contract.contractNumber = contractNumber;
        contract.billingModel = billingModel;
        contract.effectiveTier = effectiveTier;
        contract.revenueShareRatio = revenueShareRatio;
        contract.startedAt = startedAt;
        contract.status = ContractStatus.DRAFT;
        contract.registerEvent(new ContractCreatedEvent(tenantId, contractNumber));
        return contract;
    }

    private static void validateRevenueShareRatio(BigDecimal ratio) {
        if (ratio == null || ratio.compareTo(BigDecimal.ZERO) <= 0 || ratio.compareTo(BigDecimal.ONE) >= 0) {
            throw new DomainException(ErrorCode.INVALID_REVENUE_SHARE_RATIO,
                "Revenue share ratio must be > 0 and < 1");
        }
    }

    // ── State transitions ────────────────────────────────────────────

    /**
     * Sign the contract, transitioning from DRAFT to ACTIVE.
     */
    public void sign(Long userId, Instant signedAt) {
        requireStatus(ContractStatus.DRAFT, "sign");
        this.signedBy = userId;
        this.signedAt = signedAt;
        this.status = ContractStatus.ACTIVE;
        registerEvent(new ContractSignedEvent(tenantId, contractNumber));
    }

    /**
     * Suspend the contract (from ACTIVE).
     */
    public void suspend() {
        requireStatus(ContractStatus.ACTIVE, "suspend");
        this.status = ContractStatus.SUSPENDED;
        registerEvent(new ContractSuspendedEvent(tenantId, contractNumber));
    }

    /**
     * Reactivate a suspended contract.
     */
    public void reactivate() {
        requireStatus(ContractStatus.SUSPENDED, "reactivate");
        this.status = ContractStatus.ACTIVE;
        registerEvent(new ContractReactivatedEvent(tenantId, contractNumber));
    }

    /**
     * Terminate the contract (from ACTIVE).
     */
    public void terminate() {
        requireStatus(ContractStatus.ACTIVE, "terminate");
        this.status = ContractStatus.TERMINATED;
        registerEvent(new ContractTerminatedEvent(tenantId, contractNumber));
    }

    /**
     * Mark the contract as expired (from ACTIVE).
     */
    public void markExpired() {
        requireStatus(ContractStatus.ACTIVE, "markExpired");
        this.status = ContractStatus.EXPIRED;
        registerEvent(new ContractExpiredEvent(tenantId, contractNumber));
    }

    // ── Business query methods ───────────────────────────────────────

    /**
     * Calculate revenue share for a given gross amount (in cents).
     * <p>
     * Partner share uses BigDecimal.intValue() which truncates toward zero;
     * platform absorbs any fractional-cent rounding via {@code gross - partner}.
     *
     * @param grossAmountCents non-negative gross revenue in cents
     * @return RevenueShareResult with platform and partner shares
     */
    public RevenueShareResult calculateRevenueShare(int grossAmountCents) {
        if (grossAmountCents < 0) {
            throw new DomainException(ErrorCode.VALIDATION_ERROR,
                "Gross amount must be non-negative");
        }
        int partnerShare = revenueShareRatio
            .multiply(BigDecimal.valueOf(grossAmountCents)).intValue();
        return new RevenueShareResult(grossAmountCents - partnerShare, partnerShare);
    }

    // ── Guards ───────────────────────────────────────────────────────

    private void requireStatus(ContractStatus expected, String action) {
        if (this.status != expected) {
            throw new DomainException(ErrorCode.STATE_CONFLICT,
                "Cannot " + action + ": expected " + expected + " but was " + this.status);
        }
    }

    // ── Getters and Setters ──────────────────────────────────────────

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public String getContractNumber() { return contractNumber; }
    public void setContractNumber(String contractNumber) { this.contractNumber = contractNumber; }

    public String getBillingModel() { return billingModel; }
    public void setBillingModel(String billingModel) { this.billingModel = billingModel; }

    public String getEffectiveTier() { return effectiveTier; }
    public void setEffectiveTier(String effectiveTier) { this.effectiveTier = effectiveTier; }

    public BigDecimal getRevenueShareRatio() { return revenueShareRatio; }
    public void setRevenueShareRatio(BigDecimal revenueShareRatio) { this.revenueShareRatio = revenueShareRatio; }

    public ContractStatus getStatus() { return status; }
    public void setStatus(ContractStatus status) { this.status = status; }

    public Long getSignedBy() { return signedBy; }
    public void setSignedBy(Long signedBy) { this.signedBy = signedBy; }

    public Instant getSignedAt() { return signedAt; }
    public void setSignedAt(Instant signedAt) { this.signedAt = signedAt; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
}
