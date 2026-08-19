package com.smartlivestock.datagen.infrastructure.persistence.entity;

import com.smartlivestock.datagen.domain.model.DatagenFarmRules;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "datagen_farm_controls")
public class DatagenFarmControlJpaEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "farm_id", nullable = false, unique = true)
    private Long farmId;

    @Column(name = "scenario_id", nullable = false)
    private Long scenarioId;

    @Column(name = "enabled", nullable = false)
    private boolean enabled;

    @Column(name = "tracker_interval_seconds", nullable = false)
    private int trackerIntervalSeconds = 300;

    @Column(name = "capsule_interval_seconds", nullable = false)
    private int capsuleIntervalSeconds = 900;

    @Column(name = "fence_excursion_probability", nullable = false,
            precision = 6, scale = 5)
    private BigDecimal fenceExcursionProbability = BigDecimal.valueOf(0.02);

    @Column(name = "fence_excursion_min_minutes", nullable = false)
    private int fenceExcursionMinMinutes = 10;

    @Column(name = "fence_excursion_max_minutes", nullable = false)
    private int fenceExcursionMaxMinutes = 30;

    @Column(name = "health_event_probability", nullable = false,
            precision = 6, scale = 5)
    private BigDecimal healthEventProbability = BigDecimal.valueOf(0.005);

    @Column(name = "fever_duration_min_minutes", nullable = false)
    private int feverDurationMinMinutes = 240;

    @Column(name = "fever_duration_max_minutes", nullable = false)
    private int feverDurationMaxMinutes = 480;

    @Column(name = "motility_duration_min_minutes", nullable = false)
    private int motilityDurationMinMinutes = 480;

    @Column(name = "motility_duration_max_minutes", nullable = false)
    private int motilityDurationMaxMinutes = 720;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }
    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }
    public Long getScenarioId() { return scenarioId; }
    public void setScenarioId(Long scenarioId) { this.scenarioId = scenarioId; }
    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }
    public DatagenFarmRules getRules() {
        return new DatagenFarmRules(
                trackerIntervalSeconds,
                capsuleIntervalSeconds,
                fenceExcursionProbability.doubleValue(),
                fenceExcursionMinMinutes,
                fenceExcursionMaxMinutes,
                healthEventProbability.doubleValue(),
                feverDurationMinMinutes,
                feverDurationMaxMinutes,
                motilityDurationMinMinutes,
                motilityDurationMaxMinutes);
    }
    public void setRules(DatagenFarmRules rules) {
        trackerIntervalSeconds = rules.trackerIntervalSeconds();
        capsuleIntervalSeconds = rules.capsuleIntervalSeconds();
        fenceExcursionProbability = BigDecimal.valueOf(rules.fenceExcursionProbability());
        fenceExcursionMinMinutes = rules.fenceExcursionMinMinutes();
        fenceExcursionMaxMinutes = rules.fenceExcursionMaxMinutes();
        healthEventProbability = BigDecimal.valueOf(rules.healthEventProbability());
        feverDurationMinMinutes = rules.feverDurationMinMinutes();
        feverDurationMaxMinutes = rules.feverDurationMaxMinutes();
        motilityDurationMinMinutes = rules.motilityDurationMinMinutes();
        motilityDurationMaxMinutes = rules.motilityDurationMaxMinutes();
    }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
