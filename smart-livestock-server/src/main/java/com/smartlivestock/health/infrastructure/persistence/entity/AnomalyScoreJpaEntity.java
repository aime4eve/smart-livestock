package com.smartlivestock.health.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.time.Instant;

import java.math.BigDecimal;

@Entity
@Table(name = "anomaly_scores")
public class AnomalyScoreJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "livestock_id", nullable = false)
    private Long livestockId;

    @Column(name = "window_start", nullable = false)
    private Instant windowStart;

    @Column(name = "window_end", nullable = false)
    private Instant windowEnd;

    @Column(name = "anomaly_score", nullable = false, precision = 4, scale = 3)
    private BigDecimal anomalyScore;

    @Column(name = "anomaly_type", nullable = false, length = 32)
    private String anomalyType;

    @Column(name = "contributions", columnDefinition = "jsonb")
    private String contributions;

    @Column(name = "capability_used", nullable = false, length = 32)
    private String capabilityUsed;

    @Column(name = "n_eff")
    private Integer nEff;

    @Column(name = "model_meta", columnDefinition = "jsonb")
    private String modelMeta;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() { this.createdAt = Instant.now(); }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }
    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }
    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }
    public Instant getWindowStart() { return windowStart; }
    public void setWindowStart(Instant windowStart) { this.windowStart = windowStart; }
    public Instant getWindowEnd() { return windowEnd; }
    public void setWindowEnd(Instant windowEnd) { this.windowEnd = windowEnd; }
    public BigDecimal getAnomalyScore() { return anomalyScore; }
    public void setAnomalyScore(BigDecimal anomalyScore) { this.anomalyScore = anomalyScore; }
    public String getAnomalyType() { return anomalyType; }
    public void setAnomalyType(String anomalyType) { this.anomalyType = anomalyType; }
    public String getContributions() { return contributions; }
    public void setContributions(String contributions) { this.contributions = contributions; }
    public String getCapabilityUsed() { return capabilityUsed; }
    public void setCapabilityUsed(String capabilityUsed) { this.capabilityUsed = capabilityUsed; }
    public Integer getNEff() { return nEff; }
    public void setNEff(Integer nEff) { this.nEff = nEff; }
    public String getModelMeta() { return modelMeta; }
    public void setModelMeta(String modelMeta) { this.modelMeta = modelMeta; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
