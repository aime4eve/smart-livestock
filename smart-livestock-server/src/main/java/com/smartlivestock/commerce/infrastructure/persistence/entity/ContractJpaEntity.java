package com.smartlivestock.commerce.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "contracts")
public class ContractJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "contract_number", nullable = false, length = 30)
    private String contractNumber;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "billing_model", nullable = false, length = 20)
    private String billingModel;

    @Column(name = "effective_tier", nullable = false, length = 20)
    private String effectiveTier;

    @Column(name = "revenue_share_ratio", precision = 5, scale = 4)
    private BigDecimal revenueShareRatio;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "signed_by")
    private Long signedBy;

    @Column(name = "signed_at")
    private Instant signedAt;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    // --- Getters and Setters ---

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getContractNumber() { return contractNumber; }
    public void setContractNumber(String contractNumber) { this.contractNumber = contractNumber; }

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

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

    public Long getVersion() { return version; }
    public void setVersion(Long version) { this.version = version; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
