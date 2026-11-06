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
    private Instant currentTempRecordedAt;
    private String currentTempSource;
    private Instant currentMotilityRecordedAt;
    private String currentMotilitySource;
    private Instant createdAt;
    private Instant updatedAt;
    private BigDecimal aiAnomalyScore;
    private String aiAnomalyType;
    private Instant aiAssessedAt;

    // Individual baseline learning (plan 2026-11-03): which baseline the
    // snapshot currently carries (DEFAULT fixed 38.50 or LEARNED), the sample
    // evidence behind it, the event-time window and band it was computed
    // from, and the algorithm version for audit.
    private String baselineSource = "DEFAULT";
    private Integer baselineSampleCount;
    private Integer baselineQualifiedDays;
    private Instant baselineWindowStart;
    private Instant baselineComputedAt;
    private BigDecimal baselineBandLow;
    private BigDecimal baselineBandHigh;
    private String baselineAlgorithmVersion;

    // Calving risk (NIX-381): last score written by the calving predictor.
    // NULL means the animal has never been assessed. Written only via the
    // targeted repository UPDATE, never through whole-entity saves.
    private Integer calvingRiskScore;

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
    public Instant getCurrentTempRecordedAt() { return currentTempRecordedAt; }
    public void setCurrentTempRecordedAt(Instant currentTempRecordedAt) { this.currentTempRecordedAt = currentTempRecordedAt; }
    public String getCurrentTempSource() { return currentTempSource; }
    public void setCurrentTempSource(String currentTempSource) { this.currentTempSource = currentTempSource; }
    public Instant getCurrentMotilityRecordedAt() { return currentMotilityRecordedAt; }
    public void setCurrentMotilityRecordedAt(Instant currentMotilityRecordedAt) { this.currentMotilityRecordedAt = currentMotilityRecordedAt; }
    public String getCurrentMotilitySource() { return currentMotilitySource; }
    public void setCurrentMotilitySource(String currentMotilitySource) { this.currentMotilitySource = currentMotilitySource; }

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

    public String getBaselineSource() { return baselineSource; }
    public void setBaselineSource(String baselineSource) { this.baselineSource = baselineSource; }
    public Integer getBaselineSampleCount() { return baselineSampleCount; }
    public void setBaselineSampleCount(Integer baselineSampleCount) { this.baselineSampleCount = baselineSampleCount; }
    public Integer getBaselineQualifiedDays() { return baselineQualifiedDays; }
    public void setBaselineQualifiedDays(Integer baselineQualifiedDays) { this.baselineQualifiedDays = baselineQualifiedDays; }
    public Instant getBaselineWindowStart() { return baselineWindowStart; }
    public void setBaselineWindowStart(Instant baselineWindowStart) { this.baselineWindowStart = baselineWindowStart; }
    public Instant getBaselineComputedAt() { return baselineComputedAt; }
    public void setBaselineComputedAt(Instant baselineComputedAt) { this.baselineComputedAt = baselineComputedAt; }
    public BigDecimal getBaselineBandLow() { return baselineBandLow; }
    public void setBaselineBandLow(BigDecimal baselineBandLow) { this.baselineBandLow = baselineBandLow; }
    public BigDecimal getBaselineBandHigh() { return baselineBandHigh; }
    public void setBaselineBandHigh(BigDecimal baselineBandHigh) { this.baselineBandHigh = baselineBandHigh; }
    public String getBaselineAlgorithmVersion() { return baselineAlgorithmVersion; }
    public void setBaselineAlgorithmVersion(String baselineAlgorithmVersion) { this.baselineAlgorithmVersion = baselineAlgorithmVersion; }

    public Integer getCalvingRiskScore() { return calvingRiskScore; }
    public void setCalvingRiskScore(Integer calvingRiskScore) { this.calvingRiskScore = calvingRiskScore; }
}
