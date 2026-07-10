package com.smartlivestock.datagen.domain.model;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class TemporalShapeTest {

    @Test
    void baseline_always_zero() {
        assertEquals(0.0, TemporalShape.BASELINE.intensityFactor(0.0), 0.001);
        assertEquals(0.0, TemporalShape.BASELINE.intensityFactor(0.5), 0.001);
        assertEquals(0.0, TemporalShape.BASELINE.intensityFactor(1.0), 0.001);
    }

    @Test
    void gradual_rise_plateau_at_midpoint() {
        assertEquals(1.0, TemporalShape.GRADUAL_RISE.intensityFactor(0.5), 0.01);
    }

    @Test
    void gradual_rise_starts_low_ends_low() {
        assertEquals(0.0, TemporalShape.GRADUAL_RISE.intensityFactor(0.0), 0.01);
        assertEquals(0.0, TemporalShape.GRADUAL_RISE.intensityFactor(1.0), 0.01);
    }

    @Test
    void abrupt_spike_ramp_up_then_plateau() {
        // At progress=0.05, intensity = 0.05/0.1 = 0.5 (ramp-up phase)
        assertEquals(0.5, TemporalShape.ABRUPT_SPIKE.intensityFactor(0.05), 0.01);
        // Past ramp-up threshold, full intensity
        assertEquals(1.0, TemporalShape.ABRUPT_SPIKE.intensityFactor(0.15), 0.01);
        assertEquals(1.0, TemporalShape.ABRUPT_SPIKE.intensityFactor(0.5), 0.01);
    }

    @Test
    void activity_surge_stays_high_until_tail() {
        assertEquals(1.0, TemporalShape.ACTIVITY_SURGE.intensityFactor(0.5), 0.01);
        assertEquals(0.0, TemporalShape.ACTIVITY_SURGE.intensityFactor(1.0), 0.01);
    }

    @Test
    void gradual_and_abrupt_shapes_start_near_zero() {
        // ACTIVITY shapes start at full strength; GRADUAL/ABRUPT ramp from zero
        for (TemporalShape shape : TemporalShape.values()) {
            if (shape == TemporalShape.BASELINE
                    || shape == TemporalShape.ACTIVITY_SURGE
                    || shape == TemporalShape.ACTIVITY_DROP) continue;
            assertEquals(0.0, shape.intensityFactor(0.0), 0.01,
                shape + " should start near zero");
        }
    }

    @Test
    void activity_shapes_start_at_full_strength() {
        assertEquals(1.0, TemporalShape.ACTIVITY_SURGE.intensityFactor(0.0), 0.01);
        assertEquals(1.0, TemporalShape.ACTIVITY_DROP.intensityFactor(0.0), 0.01);
    }

    @Test
    void all_non_baseline_shapes_end_near_zero() {
        for (TemporalShape shape : TemporalShape.values()) {
            if (shape == TemporalShape.BASELINE) continue;
            assertEquals(0.0, shape.intensityFactor(1.0), 0.01,
                shape + " should end near zero");
        }
    }
}
