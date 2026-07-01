package com.smartlivestock.datagen.domain.model;

/**
 * Multi-dimensional modulation spec for health anomaly scenarios.
 * Each ratio is relative to baseline (1.0 = baseline, 0.5 = halved, 1.8 = +80%).
 * tempDelta is absolute (degrees Celsius).
 */
public record DimensionModulation(
        double tempDelta,
        double motilityRatio,
        double activityRatio,
        double stepRatio
) {}
