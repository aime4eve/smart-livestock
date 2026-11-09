package com.smartlivestock.health.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "estrus_scores")
public class EstrusScoreJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "livestock_id", nullable = false)
    private Long livestockId;

    @Column(name = "score", nullable = false)
    private Integer score;

    @Column(name = "step_increase_percent")
    private Integer stepIncreasePercent;

    @Column(name = "temp_delta", precision = 8, scale = 2)
    private BigDecimal tempDelta;

    @Column(name = "distance_delta", precision = 10, scale = 2)
    private BigDecimal distanceDelta;

    @Column(name = "advice", columnDefinition = "TEXT")
    private String advice;

    @Column(name = "scored_at", nullable = false)
    private Instant scoredAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "source", nullable = false, length = 20)
    private String source = "UNKNOWN";

    // Baseline audit trail columns (V20261104100000). baselineSource is
    // nullable — NULL marks rows scored before learning (legacy semantics).
    @Column(name = "baseline_used", precision = 5, scale = 2)
    private BigDecimal baselineUsed;

    @Column(name = "baseline_source", length = 12)
    private String baselineSource;

    @Column(name = "baseline_computed_at")
    private Instant baselineComputedAt;

    @Column(name = "baseline_algorithm_version", length = 16)
    private String baselineAlgorithmVersion;

    // Scoring provenance (V20261109100000): LEGACY or NORMALIZED-V2.
    @Column(name = "feature_version", nullable = false, length = 16)
    private String featureVersion;

    // Normalized distance level ratio; null when distance did not participate
    // or the row is LEGACY semantics.
    @Column(name = "distance_ratio", precision = 6, scale = 3)
    private BigDecimal distanceRatio;

    @PrePersist
    protected void onCreate() { this.createdAt = Instant.now(); }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }
    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }
    public Integer getScore() { return score; }
    public void setScore(Integer score) { this.score = score; }
    public Integer getStepIncreasePercent() { return stepIncreasePercent; }
    public void setStepIncreasePercent(Integer stepIncreasePercent) { this.stepIncreasePercent = stepIncreasePercent; }
    public BigDecimal getTempDelta() { return tempDelta; }
    public void setTempDelta(BigDecimal tempDelta) { this.tempDelta = tempDelta; }
    public BigDecimal getDistanceDelta() { return distanceDelta; }
    public void setDistanceDelta(BigDecimal distanceDelta) { this.distanceDelta = distanceDelta; }
    public String getAdvice() { return advice; }
    public void setAdvice(String advice) { this.advice = advice; }
    public Instant getScoredAt() { return scoredAt; }
    public void setScoredAt(Instant scoredAt) { this.scoredAt = scoredAt; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }

    public BigDecimal getBaselineUsed() { return baselineUsed; }
    public void setBaselineUsed(BigDecimal baselineUsed) { this.baselineUsed = baselineUsed; }
    public String getBaselineSource() { return baselineSource; }
    public void setBaselineSource(String baselineSource) { this.baselineSource = baselineSource; }
    public Instant getBaselineComputedAt() { return baselineComputedAt; }
    public void setBaselineComputedAt(Instant baselineComputedAt) { this.baselineComputedAt = baselineComputedAt; }
    public String getBaselineAlgorithmVersion() { return baselineAlgorithmVersion; }
    public void setBaselineAlgorithmVersion(String baselineAlgorithmVersion) { this.baselineAlgorithmVersion = baselineAlgorithmVersion; }

    public String getFeatureVersion() { return featureVersion; }
    public void setFeatureVersion(String featureVersion) { this.featureVersion = featureVersion; }

    public BigDecimal getDistanceRatio() { return distanceRatio; }
    public void setDistanceRatio(BigDecimal distanceRatio) { this.distanceRatio = distanceRatio; }
}
