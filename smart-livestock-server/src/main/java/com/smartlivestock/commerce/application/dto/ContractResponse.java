package com.smartlivestock.commerce.application.dto;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Response DTO for contract read model.
 */
public class ContractResponse {

    private Long id;
    private Long tenantId;
    private String contractNumber;
    private String billingModel;
    private String effectiveTier;
    private BigDecimal revenueShareRatio;
    private String status;
    private Long signedBy;
    private Instant signedAt;
    private Instant startedAt;
    private Instant expiresAt;

    public ContractResponse() {
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

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

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Long getSignedBy() { return signedBy; }
    public void setSignedBy(Long signedBy) { this.signedBy = signedBy; }

    public Instant getSignedAt() { return signedAt; }
    public void setSignedAt(Instant signedAt) { this.signedAt = signedAt; }

    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
}
