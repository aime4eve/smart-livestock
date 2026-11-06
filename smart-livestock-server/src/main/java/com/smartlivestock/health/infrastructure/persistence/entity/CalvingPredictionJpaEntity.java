package com.smartlivestock.health.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * JPA mirror of the calving_predictions table (V20261106130000). Table shape
 * is a precise structural twin of estrus_scores (V20 + V20261104100000 audit
 * columns): farm-scoped score rows, no FK on livestock_id, CHECK-bounded
 * score, nullable feature channels, DESC time indexes.
 */
@Entity
@Table(name = "calving_predictions")
public class CalvingPredictionJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "livestock_id", nullable = false)
    private Long livestockId;

    @Column(name = "risk_score", nullable = false)
    private Integer riskScore;

    // Nullable feature channels: NULL means the channel was unavailable at
    // scoring time (sample guard tripped), not zero effect.
    @Column(name = "temp_drop_celsius", precision = 4, scale = 2)
    private BigDecimal tempDropCelsius;

    @Column(name = "activity_ratio", precision = 5, scale = 2)
    private BigDecimal activityRatio;

    @Column(name = "prior_enabled")
    private Boolean priorEnabled;

    // Estimated calving window (all nullable — only present when the
    // estimator had enough signal to produce one).
    @Column(name = "expected_window_start")
    private Instant expectedWindowStart;

    @Column(name = "expected_window_end")
    private Instant expectedWindowEnd;

    @Column(name = "expected_calving_at")
    private Instant expectedCalvingAt;

    @Column(name = "predicted_at", nullable = false)
    private Instant predictedAt;

    // Baseline audit trail columns (same shape as estrus_scores,
    // V20261104100000). baselineSource is nullable on purpose.
    @Column(name = "baseline_used", precision = 5, scale = 2)
    private BigDecimal baselineUsed;

    @Column(name = "baseline_source", length = 12)
    private String baselineSource;

    @Column(name = "baseline_computed_at")
    private Instant baselineComputedAt;

    @Column(name = "baseline_algorithm_version", length = 16)
    private String baselineAlgorithmVersion;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() { this.createdAt = Instant.now(); }

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
