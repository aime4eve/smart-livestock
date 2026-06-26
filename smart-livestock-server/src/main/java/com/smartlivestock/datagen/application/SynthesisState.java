package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.AnomalyPattern;
import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;

import java.time.Instant;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Per-livestock synthesis state. Tracks individual baseline offset and active anomaly period.
 * Replaces TelemetrySimulator.SimulationState with Scenario-driven anomaly tracking.
 *
 * GPS random-walk state (currentLat/currentLng) migrated from GPS consolidation design.
 *
 * Known limitation (design §8A): in-memory state is lost on restart.
 * Active anomalies are interrupted; orphan GroundTruthLabels may remain.
 */
class SynthesisState {

    // Individual baselines (replaces SimulationState random fields)
    double tempBaselineOffset;     // +/-0.3C individual offset
    long motilityBaseline;         // 250000-350000
    int batteryLevel;              // 0-100
    int batteryVoltage;            // 2800-3600 mV

    // GPS random-walk state (migrated from GPS consolidation design)
    double currentLat;
    double currentLng;

    // Active anomaly tracking (replaces boolean flags)
    AnomalyPattern activePattern;  // null = NORMAL
    Instant anomalyStart;
    Instant anomalyEnd;

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
}
