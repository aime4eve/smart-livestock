package com.smartlivestock.commerce.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "revenue_periods")
public class RevenuePeriodJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "contract_id", nullable = false)
    private Long contractId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "period_start", nullable = false)
    private LocalDate periodStart;

    @Column(name = "period_end", nullable = false)
    private LocalDate periodEnd;

    @Column(name = "gross_amount", nullable = false)
    private Integer grossAmount;

    @Column(name = "platform_share", nullable = false)
    private Integer platformShare;

    @Column(name = "partner_share", nullable = false)
    private Integer partnerShare;

    @Column(name = "revenue_share_ratio", nullable = false, precision = 5, scale = 4)
    private BigDecimal revenueShareRatio;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "settled_at")
    private Instant settledAt;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = Instant.now();
    }

    // --- Getters and Setters ---

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

    public Integer getGrossAmount() { return grossAmount; }
    public void setGrossAmount(Integer grossAmount) { this.grossAmount = grossAmount; }

    public Integer getPlatformShare() { return platformShare; }
    public void setPlatformShare(Integer platformShare) { this.platformShare = platformShare; }

    public Integer getPartnerShare() { return partnerShare; }
    public void setPartnerShare(Integer partnerShare) { this.partnerShare = partnerShare; }

    public BigDecimal getRevenueShareRatio() { return revenueShareRatio; }
    public void setRevenueShareRatio(BigDecimal revenueShareRatio) { this.revenueShareRatio = revenueShareRatio; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Instant getSettledAt() { return settledAt; }
    public void setSettledAt(Instant settledAt) { this.settledAt = settledAt; }

    public Long getVersion() { return version; }
    public void setVersion(Long version) { this.version = version; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
