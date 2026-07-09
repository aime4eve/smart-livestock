package com.smartlivestock.datagen.domain.model;

import java.time.Duration;

/**
 * Unified scenario type enum. Replaces the former split ScenarioType + AnomalyPattern.
 *
 * Each type carries a complete behavioral spec:
 * - category: determines which generation branch executes (baseline/health/fence)
 * - defaultIntervalSeconds: inherent sampling frequency
 * - defaultDuration: event duration (null = continuous)
 * - temporalShape: time-curve shape for health anomalies (null = N/A)
 * - modulation: 4-dimension modulation spec (null = N/A)
 */
public enum ScenarioType {
    // Baseline
    NORMAL("normal", Category.BASELINE, 300, null, null, null),

    // Health anomalies
    LOW_GRADE_FEVER("low_grade_fever", Category.HEALTH, 30, Duration.ofHours(6),
            TemporalShape.GRADUAL_RISE,
            new DimensionModulation(1.0, 0.8, 0.6, 0.7)),
    HIGH_FEVER("high_fever", Category.HEALTH, 30, Duration.ofHours(3),
            TemporalShape.ABRUPT_SPIKE,
            new DimensionModulation(2.5, 0.7, 0.4, 0.5)),
    CHRONIC_MOTILITY_DROP("chronic_motility_drop", Category.HEALTH, 30, Duration.ofDays(2),
            TemporalShape.GRADUAL_DECLINE,
            new DimensionModulation(0.5, 0.4, 0.8, 0.85)),
    ACUTE_MOTILITY_DROP("acute_motility_drop", Category.HEALTH, 30, Duration.ofHours(8),
            TemporalShape.ABRUPT_DROP,
            new DimensionModulation(0.0, 0.2, 0.7, 0.8)),
    ESTRUS("estrus", Category.HEALTH, 30, Duration.ofHours(18),
            TemporalShape.ACTIVITY_SURGE,
            new DimensionModulation(0.3, 1.0, 1.8, 2.5)),
    LAMENESS("lameness", Category.HEALTH, 30, Duration.ofDays(1),
            TemporalShape.ACTIVITY_DROP,
            new DimensionModulation(0.0, 0.9, 0.3, 0.3)),

   // Fence scenarios
   FENCE_BREACH("fence_breach", Category.FENCE, 10, Duration.ofMinutes(30), null, null),
    FENCE_APPROACH("fence_approach", Category.FENCE, 10, Duration.ofMinutes(30), null, null),

    // Device failure scenarios (Phase 3)
    DEVICE_LOW_BATTERY("device_low_battery", Category.DEVICE, 300, Duration.ofHours(6), null, null),
    DEVICE_SIGNAL_DEGRADATION("device_signal_degradation", Category.DEVICE, 300, Duration.ofHours(3), null, null),
    DEVICE_ANTI_DISASSEMBLY("device_anti_disassembly", Category.DEVICE, 300, Duration.ofMinutes(5), null, null);

    public enum Category { BASELINE, HEALTH, FENCE, DEVICE }

    private final String dbValue;
    private final Category category;
    private final int defaultIntervalSeconds;
    private final Duration defaultDuration;
    private final TemporalShape temporalShape;
    private final DimensionModulation modulation;

    ScenarioType(String dbValue, Category category, int defaultIntervalSeconds,
                 Duration defaultDuration, TemporalShape temporalShape,
                 DimensionModulation modulation) {
        this.dbValue = dbValue;
        this.category = category;
        this.defaultIntervalSeconds = defaultIntervalSeconds;
        this.defaultDuration = defaultDuration;
        this.temporalShape = temporalShape;
        this.modulation = modulation;
    }

    public String getDbValue() { return dbValue; }
    public Category getCategory() { return category; }
    public int getDefaultIntervalSeconds() { return defaultIntervalSeconds; }
    public Duration getDefaultDuration() { return defaultDuration; }
    public TemporalShape getTemporalShape() { return temporalShape; }
    public DimensionModulation getModulation() { return modulation; }

    public static ScenarioType fromDbValue(String value) {
        for (ScenarioType t : values()) {
            if (t.dbValue.equalsIgnoreCase(value) || t.name().equalsIgnoreCase(value)) return t;
        }
        throw new IllegalArgumentException("Unknown ScenarioType: " + value);
    }
}
