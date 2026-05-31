package com.smartlivestock.health.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "health_snapshots")
public class HealthSnapshotJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "livestock_id", nullable = false, unique = true)
    private Long livestockId;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "baseline_temp", nullable = false, precision = 5, scale = 2)
    private BigDecimal baselineTemp;

    @Column(name = "current_temp", precision = 5, scale = 2)
    private BigDecimal currentTemp;

    @Column(name = "temp_status", nullable = false, length = 20)
    private String tempStatus;

    @Column(name = "motility_baseline", precision = 5, scale = 2)
    private BigDecimal motilityBaseline;

    @Column(name = "current_motility", precision = 5, scale = 2)
    private BigDecimal currentMotility;

    @Column(name = "motility_status", nullable = false, length = 20)
    private String motilityStatus;

    @Column(name = "estrus_score")
    private Integer estrusScore;

    @Column(name = "activity_status", nullable = false, length = 20)
    private String activityStatus;

    @Column(name = "last_assessed_at")
    private Instant lastAssessedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() { Instant now = Instant.now(); this.createdAt = now; this.updatedAt = now; }

    @PreUpdate
    protected void onUpdate() { this.updatedAt = Instant.now(); }

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
    public String getTempStatus() { return tempStatus; }
    public void setTempStatus(String tempStatus) { this.tempStatus = tempStatus; }
    public BigDecimal getMotilityBaseline() { return motilityBaseline; }
    public void setMotilityBaseline(BigDecimal motilityBaseline) { this.motilityBaseline = motilityBaseline; }
    public BigDecimal getCurrentMotility() { return currentMotility; }
    public void setCurrentMotility(BigDecimal currentMotility) { this.currentMotility = currentMotility; }
    public String getMotilityStatus() { return motilityStatus; }
    public void setMotilityStatus(String motilityStatus) { this.motilityStatus = motilityStatus; }
    public Integer getEstrusScore() { return estrusScore; }
    public void setEstrusScore(Integer estrusScore) { this.estrusScore = estrusScore; }
    public String getActivityStatus() { return activityStatus; }
    public void setActivityStatus(String activityStatus) { this.activityStatus = activityStatus; }
    public Instant getLastAssessedAt() { return lastAssessedAt; }
    public void setLastAssessedAt(Instant lastAssessedAt) { this.lastAssessedAt = lastAssessedAt; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
