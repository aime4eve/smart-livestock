package com.smartlivestock.health.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Calving risk evaluation history row (NIX-381). One row per evaluation that
 * was worth persisting (score >= 50 or an alert-threshold crossing); steady
 * state writes nothing. Field-for-field mirror of the calving_predictions
 * table (V20261106130000).
 */
public class CalvingPrediction {

    private Long id;
    private Long farmId;
    private Long livestockId;
    private Integer riskScore;
    private BigDecimal tempDropCelsius;
    private BigDecimal activityRatio;
    private Boolean priorEnabled;
    private Instant expectedWindowStart;
    private Instant expectedWindowEnd;
    private Instant expectedCalvingAt;
    private Instant predictedAt;

    // Baseline audit trail (same provenance semantics as estrus_scores):
    // which temperature baseline the scoring used and when/how it was
    // computed. baselineSource is nullable — NULL would mark a row written
    // before the audit stamp existed.
    private BigDecimal baselineUsed;
    private String baselineSource;
    private Instant baselineComputedAt;
    private String baselineAlgorithmVersion;

    private Instant createdAt;

    public CalvingPrediction() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }

    public Integer getRiskScore() { return riskScore; }
    public void setRiskScore(Integer riskScore) { this.riskScore = riskScore; }

    public BigDecimal getTempDropCelsius() { return tempDropCelsius; }
    public void setTempDropCelsius(BigDecimal tempDropCelsius) { this.tempDropCelsius = tempDropCelsius; }

    public BigDecimal getActivityRatio() { return activityRatio; }
    public void setActivityRatio(BigDecimal activityRatio) { this.activityRatio = activityRatio; }

    public Boolean getPriorEnabled() { return priorEnabled; }
    public void setPriorEnabled(Boolean priorEnabled) { this.priorEnabled = priorEnabled; }

    public Instant getExpectedWindowStart() { return expectedWindowStart; }
    public void setExpectedWindowStart(Instant expectedWindowStart) { this.expectedWindowStart = expectedWindowStart; }

    public Instant getExpectedWindowEnd() { return expectedWindowEnd; }
    public void setExpectedWindowEnd(Instant expectedWindowEnd) { this.expectedWindowEnd = expectedWindowEnd; }

    public Instant getExpectedCalvingAt() { return expectedCalvingAt; }
    public void setExpectedCalvingAt(Instant expectedCalvingAt) { this.expectedCalvingAt = expectedCalvingAt; }

    public Instant getPredictedAt() { return predictedAt; }
    public void setPredictedAt(Instant predictedAt) { this.predictedAt = predictedAt; }

    public BigDecimal getBaselineUsed() { return baselineUsed; }
    public void setBaselineUsed(BigDecimal baselineUsed) { this.baselineUsed = baselineUsed; }
    public String getBaselineSource() { return baselineSource; }
    public void setBaselineSource(String baselineSource) { this.baselineSource = baselineSource; }
    public Instant getBaselineComputedAt() { return baselineComputedAt; }
    public void setBaselineComputedAt(Instant baselineComputedAt) { this.baselineComputedAt = baselineComputedAt; }
    public String getBaselineAlgorithmVersion() { return baselineAlgorithmVersion; }
    public void setBaselineAlgorithmVersion(String baselineAlgorithmVersion) { this.baselineAlgorithmVersion = baselineAlgorithmVersion; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
