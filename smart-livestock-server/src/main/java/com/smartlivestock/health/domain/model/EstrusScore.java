package com.smartlivestock.health.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

public class EstrusScore {

    private Long id;
    private Long farmId;
    private Long livestockId;
    private Integer score;
    private Integer stepIncreasePercent;
    private BigDecimal tempDelta;
    private BigDecimal distanceDelta;
    private String advice;
    private Instant scoredAt;
    private Instant createdAt;
    private String source;

    // Baseline audit trail (plan 2026-11-03): the effective baseline used at
    // scoring time and its provenance. baselineSource is nullable — NULL means
    // the row predates learning (legacy fixed 38.50 baseline semantics).
    private BigDecimal baselineUsed;
    private String baselineSource;
    private Instant baselineComputedAt;
    private String baselineAlgorithmVersion;

    // Scoring provenance (NIX-390): which formula produced the row. LEGACY =
    // short-window relative ratios; NORMALIZED-V2 = cross-event-window level
    // ratios. The NOT NULL DB column backfills existing rows to LEGACY.
    private String featureVersion;
    // Normalized distance level ratio (current mean / pooled baseline mean).
    // Null means distance did not participate or the row is LEGACY semantics.
    private BigDecimal distanceRatio;

    public EstrusScore() {}

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
