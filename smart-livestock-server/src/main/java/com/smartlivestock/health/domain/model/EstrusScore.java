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
}
