package com.smartlivestock.datagen.domain.model;

/**
 * Temporal shape of an anomaly curve over its duration.
 * intensityFactor(progress) returns 0.0-1.0 strength at given progress (0=start, 1=end).
 */
public enum TemporalShape {
    BASELINE,
    GRADUAL_RISE,
    ABRUPT_SPIKE,
    GRADUAL_DECLINE,
    ABRUPT_DROP,
    ACTIVITY_SURGE,
    ACTIVITY_DROP;

    /**
     * Calculate anomaly intensity at given progress through the anomaly period.
     * @param progress 0.0 = anomaly just started, 1.0 = anomaly ended
     * @return 0.0 = baseline, 1.0 = full-strength anomaly
     */
    public double intensityFactor(double progress) {
        progress = Math.max(0.0, Math.min(1.0, progress));
        return switch (this) {
            case BASELINE -> 0.0;
            case GRADUAL_RISE, GRADUAL_DECLINE -> {
                // Three-phase: rise(0-0.3) -> plateau(0.3-0.7) -> fall(0.7-1.0)
                if (progress < 0.3) yield progress / 0.3;
                else if (progress < 0.7) yield 1.0;
                else yield 1.0 - (progress - 0.7) / 0.3;
            }
            case ABRUPT_SPIKE, ABRUPT_DROP -> {
                // Fast ramp -> plateau -> fast recovery
                if (progress < 0.1) yield progress / 0.1;
                else if (progress < 0.85) yield 1.0;
                else yield 1.0 - (progress - 0.85) / 0.15;
            }
            case ACTIVITY_SURGE, ACTIVITY_DROP -> {
                // Sustained high intensity, recovery near end
                if (progress < 0.8) yield 1.0;
                else yield 1.0 - (progress - 0.8) / 0.2;
            }
        };
    }
}
