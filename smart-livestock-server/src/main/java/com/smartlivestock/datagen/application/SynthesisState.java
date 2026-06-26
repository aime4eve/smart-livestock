package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.AnomalyPattern;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;

import java.time.Instant;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Per-livestock synthesis state. Tracks individual baseline offset,
 * active anomaly period, GPS random-walk position, and active fence scenario.
 *
 * Known limitation (design §8A): in-memory state is lost on restart.
 */
class SynthesisState {

    // Individual baselines
    double tempBaselineOffset;
    long motilityBaseline;
    int batteryLevel;
    int batteryVoltage;

    // GPS random-walk state
    double currentLat;
    double currentLng;

    // Active HEALTH anomaly tracking
    AnomalyPattern activePattern;
    Instant anomalyStart;
    Instant anomalyEnd;

    // Active FENCE scenario tracking
    ScenarioType activeFenceScenario;
    Instant fenceScenarioStart;
    Instant fenceScenarioEnd;

    private SynthesisState() {}

    static SynthesisState create(Long livestockId, ActiveInstallationInfo inst) {
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        SynthesisState s = new SynthesisState();
        s.tempBaselineOffset = rng.nextDouble(-0.3, 0.3);
        s.motilityBaseline = (long) (rng.nextDouble(2.5, 3.5) * 100000);
        s.batteryLevel = rng.nextInt(70, 101);
        s.batteryVoltage = rng.nextInt(3200, 3601);
        return s;
    }

    boolean isInAnomaly(Instant now) {
        return activePattern != null && now.isAfter(anomalyStart) && now.isBefore(anomalyEnd);
    }

    boolean isInFenceScenario(Instant now) {
        return activeFenceScenario != null && now.isBefore(fenceScenarioEnd);
    }
}
