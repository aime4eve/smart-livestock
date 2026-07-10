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
}
