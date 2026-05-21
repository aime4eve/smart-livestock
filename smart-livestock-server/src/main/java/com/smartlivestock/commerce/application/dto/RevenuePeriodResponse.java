package com.smartlivestock.commerce.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Response DTO for revenue period read model.
 */
public class RevenuePeriodResponse {

    private Long id;
    private Long contractId;
    private Long tenantId;
    private LocalDate periodStart;
    private LocalDate periodEnd;
    private int grossAmount;
    private int platformShare;
    private int partnerShare;
    private BigDecimal revenueShareRatio;
    private String status;
    private Instant settledAt;

    public RevenuePeriodResponse() {
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

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

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Instant getSettledAt() { return settledAt; }
    public void setSettledAt(Instant settledAt) { this.settledAt = settledAt; }
}
