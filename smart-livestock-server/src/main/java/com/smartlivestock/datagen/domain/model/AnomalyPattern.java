package com.smartlivestock.datagen.domain.model;

import java.time.Duration;

/**
 * Anomaly pattern with physiological parameters and temporal shape.
 * Replaces TelemetrySimulator boolean flags with structured anomaly definitions.
 */
public enum AnomalyPattern {
    LOW_GRADE_FEVER("low_grade_fever", 38.5, 39.5, Duration.ofHours(6), TemporalShape.GRADUAL_RISE),
    HIGH_FEVER("high_fever", 39.5, 41.0, Duration.ofHours(3), TemporalShape.ABRUPT_SPIKE),
    CHRONIC_MOTILITY_DROP("chronic_motility_drop", null, null, Duration.ofDays(2), TemporalShape.GRADUAL_DECLINE),
    ACUTE_MOTILITY_DROP("acute_motility_drop", null, null, Duration.ofHours(8), TemporalShape.ABRUPT_DROP),
    ESTRUS("estrus", null, null, Duration.ofHours(18), TemporalShape.ACTIVITY_SURGE),
    LAMENESS("lameness", null, null, Duration.ofDays(1), TemporalShape.ACTIVITY_DROP),
    NORMAL("normal", null, null, null, TemporalShape.BASELINE);

    private final String dbValue;
    private final Double tempMin;      // null for non-temperature anomalies
    private final Double tempMax;
    private final Duration duration;   // null for NORMAL
    private final TemporalShape temporalShape;

    AnomalyPattern(String dbValue, Double tempMin, Double tempMax,
                   Duration duration, TemporalShape temporalShape) {
        this.dbValue = dbValue;
        this.tempMin = tempMin;
        this.tempMax = tempMax;
        this.duration = duration;
        this.temporalShape = temporalShape;
    }

    public String getDbValue() { return dbValue; }
    public Double getTempMin() { return tempMin; }
    public Double getTempMax() { return tempMax; }
    public Duration getDuration() { return duration; }
    public TemporalShape getTemporalShape() { return temporalShape; }

    public static AnomalyPattern fromDbValue(String value) {
        for (AnomalyPattern p : values()) {
            if (p.dbValue.equalsIgnoreCase(value) || p.name().equalsIgnoreCase(value)) return p;
        }
        throw new IllegalArgumentException("Unknown AnomalyPattern: " + value);
    }
}
