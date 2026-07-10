package com.smartlivestock.health.domain.model;

import com.smartlivestock.shared.domain.Entity;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

/**
 * AI anomaly detection result for a livestock within a detection window.
 * Persisted to anomaly_scores table (Phase A design section 6.1).
 */
public class AnomalyScore extends Entity {

    private Long id;
    private Long tenantId;
    private Long farmId;
    private Long livestockId;
    private Instant windowStart;
    private Instant windowEnd;
    private BigDecimal anomalyScore;    // 0.000 - 1.000
    private String anomalyType;         // normal / circadian_disruption / abrupt_change / multivariate
    private Map<String, Object> contributions;
    private String capabilityUsed;      // health_l1 / none
    private Integer nEff;
    private Map<String, Object> modelMeta;
    private Instant createdAt;

    public AnomalyScore() {}

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

    public Map<String, Object> getContributions() { return contributions; }
    public void setContributions(Map<String, Object> contributions) { this.contributions = contributions; }

    public String getCapabilityUsed() { return capabilityUsed; }
    public void setCapabilityUsed(String capabilityUsed) { this.capabilityUsed = capabilityUsed; }

    public Integer getNEff() { return nEff; }
    public void setNEff(Integer nEff) { this.nEff = nEff; }

    public Map<String, Object> getModelMeta() { return modelMeta; }
    public void setModelMeta(Map<String, Object> modelMeta) { this.modelMeta = modelMeta; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
