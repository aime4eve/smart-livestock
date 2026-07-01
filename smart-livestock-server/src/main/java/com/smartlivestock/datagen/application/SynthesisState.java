package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import lombok.extern.slf4j.Slf4j;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ThreadLocalRandom;

@Slf4j
class SynthesisState {
    double tempBaselineOffset;
    long motilityBaseline;
    int batteryLevel;
    int batteryVoltage;
    double currentLat;
    double currentLng;
    ScenarioType activeType;
    Instant eventStart;
    Instant eventEnd;

    private SynthesisState() {}

    static SynthesisState create(Long livestockId, ActiveInstallationInfo inst) {
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        SynthesisState s = new SynthesisState();
        s.tempBaselineOffset = rng.nextDouble(-0.3, 0.3);
        s.motilityBaseline = (long) (rng.nextDouble(2.5, 3.5) * 100000);
        s.batteryLevel = rng.nextInt(70, 101);
        s.batteryVoltage = rng.nextInt(3200, 3601);

        // Initialize GPS position from livestock's last known location
        if (inst.latitude() != null && inst.longitude() != null) {
            s.currentLat = inst.latitude();
            s.currentLng = inst.longitude();
        } else {
            // Fallback: default farm center (长沙附近)
            log.warn("Livestock [{}] has no last position, defaulting to 28.229, 112.938", livestockId);
            s.currentLat = 28.229;
            s.currentLng = 112.938;
        }
        return s;
    }

    boolean isInEvent(Instant now) {
        return activeType != null && now.isAfter(eventStart) && now.isBefore(eventEnd);
    }

    double eventProgress(Instant now) {
        if (activeType == null) return 0;
        long total = Duration.between(eventStart, eventEnd).getSeconds();
        long elapsed = Duration.between(eventStart, now).getSeconds();
        return total > 0 ? Math.min(1.0, (double) elapsed / total) : 0;
    }
}
