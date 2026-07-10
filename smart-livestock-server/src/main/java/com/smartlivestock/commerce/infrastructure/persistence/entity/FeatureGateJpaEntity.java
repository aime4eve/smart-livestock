package com.smartlivestock.commerce.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "feature_gates")
public class FeatureGateJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tier", nullable = false, length = 20)
    private String tier;

    @Column(name = "feature_key", nullable = false, length = 50)
    private String featureKey;

    @Column(name = "gate_type", nullable = false, length = 10)
    private String gateType;

    @Column(name = "limit_value")
    private Integer limitValue;

    @Column(name = "retention_days")
    private Integer retentionDays;

    @Column(name = "is_enabled")
    private Boolean isEnabled;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = Instant.now();
    }

    // --- Getters and Setters ---

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getTier() { return tier; }
    public void setTier(String tier) { this.tier = tier; }

    public String getFeatureKey() { return featureKey; }
    public void setFeatureKey(String featureKey) { this.featureKey = featureKey; }

    public String getGateType() { return gateType; }
    public void setGateType(String gateType) { this.gateType = gateType; }

    public Integer getLimitValue() { return limitValue; }
    public void setLimitValue(Integer limitValue) { this.limitValue = limitValue; }

    public Integer getRetentionDays() { return retentionDays; }
    public void setRetentionDays(Integer retentionDays) { this.retentionDays = retentionDays; }

    public Boolean getIsEnabled() { return isEnabled; }
    public void setIsEnabled(Boolean isEnabled) { this.isEnabled = isEnabled; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
