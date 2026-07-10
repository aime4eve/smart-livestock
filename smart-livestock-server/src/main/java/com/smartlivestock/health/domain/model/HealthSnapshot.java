package com.smartlivestock.health.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

public class HealthSnapshot {

    private Long id;
    private Long livestockId;
    private Long farmId;
    private BigDecimal baselineTemp;
    private BigDecimal currentTemp;
    private TempStatus tempStatus;
    private BigDecimal motilityBaseline;
    private BigDecimal currentMotility;
    private MotilityStatus motilityStatus;
    private Integer estrusScore;
    private ActivityStatus activityStatus;
    private Instant lastAssessedAt;
    private Instant createdAt;
    private Instant updatedAt;
    private BigDecimal aiAnomalyScore;
    private String aiAnomalyType;
    private Instant aiAssessedAt;

    public HealthSnapshot() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }

    public BigDecimal getBaselineTemp() { return baselineTemp; }
    public void setBaselineTemp(BigDecimal baselineTemp) { this.baselineTemp = baselineTemp; }

    public BigDecimal getCurrentTemp() { return currentTemp; }
    public void setCurrentTemp(BigDecimal currentTemp) { this.currentTemp = currentTemp; }

    public TempStatus getTempStatus() { return tempStatus; }
    public void setTempStatus(TempStatus tempStatus) { this.tempStatus = tempStatus; }

    public BigDecimal getMotilityBaseline() { return motilityBaseline; }
    public void setMotilityBaseline(BigDecimal motilityBaseline) { this.motilityBaseline = motilityBaseline; }

    public BigDecimal getCurrentMotility() { return currentMotility; }
    public void setCurrentMotility(BigDecimal currentMotility) { this.currentMotility = currentMotility; }

    public MotilityStatus getMotilityStatus() { return motilityStatus; }
    public void setMotilityStatus(MotilityStatus motilityStatus) { this.motilityStatus = motilityStatus; }

    public Integer getEstrusScore() { return estrusScore; }
    public void setEstrusScore(Integer estrusScore) { this.estrusScore = estrusScore; }

    public ActivityStatus getActivityStatus() { return activityStatus; }
    public void setActivityStatus(ActivityStatus activityStatus) { this.activityStatus = activityStatus; }

    public Instant getLastAssessedAt() { return lastAssessedAt; }
    public void setLastAssessedAt(Instant lastAssessedAt) { this.lastAssessedAt = lastAssessedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public BigDecimal getAiAnomalyScore() { return aiAnomalyScore; }
    public void setAiAnomalyScore(BigDecimal aiAnomalyScore) { this.aiAnomalyScore = aiAnomalyScore; }
    public String getAiAnomalyType() { return aiAnomalyType; }
    public void setAiAnomalyType(String aiAnomalyType) { this.aiAnomalyType = aiAnomalyType; }
    public Instant getAiAssessedAt() { return aiAssessedAt; }
    public void setAiAssessedAt(Instant aiAssessedAt) { this.aiAssessedAt = aiAssessedAt; }
}
