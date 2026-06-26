package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.*;
import com.smartlivestock.datagen.domain.port.DeviceQueryPort;
import com.smartlivestock.datagen.domain.port.TelemetryIngestionPort;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import com.smartlivestock.datagen.domain.repository.SynthesisScenarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Core synthesis engine. For each RUNNING scenario, generates synthetic telemetry readings
 * for all active installations and feeds them into IoT's standard ingestion pipeline via ACL.
 *
 * Anomaly injection replaces TelemetrySimulator random boolean flags with Scenario-driven
 * temporal curves (gradual rise, abrupt spike, activity surge, etc.) controlled by TemporalShape.
 *
 * Design §8A: generate() does NOT have @Transactional. Each livestock's ingest() has its own
 * transaction boundary. GroundTruthLabel writes go through GroundTruthLabelService with
 * REQUIRES_NEW propagation.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SynthesisService {

    private final TelemetryIngestionPort ingestionPort;
    private final DeviceQueryPort deviceQueryPort;
    private final SynthesisScenarioRepository scenarioRepository;
    private final GroundTruthLabelService labelService;

    private final ConcurrentHashMap<Long, SynthesisState> states = new ConcurrentHashMap<>();

    /**
     * Generate synthetic data for a scenario. Called by SynthesisRunner on schedule.
     * NOT @Transactional (design §8A / P1 #8).
     */
    public void generate(SynthesisScenario scenario) {
        List<ActiveInstallationInfo> installations = deviceQueryPort.findActiveInstallations();
        if (installations.isEmpty()) return;

        Instant now = Instant.now();
        if (!scenario.isActiveAt(now)) return;

        // Determine which livestock get the anomaly (only when scenario pattern != NORMAL)
        Set<Long> anomalyTargets = selectAnomalyTargetsIfNeeded(installations, scenario, now);

        for (ActiveInstallationInfo inst : installations) {
            SynthesisState state = states.computeIfAbsent(
                    inst.livestockId(), id -> SynthesisState.create(id, inst));
            updateAnomalyState(state, inst.livestockId(), scenario, anomalyTargets, now);

            double intensity = calculateIntensity(state, now);

            Map<String, Object> readings = switch (inst.deviceType()) {
                case TRACKER -> generateTrackerReadings(state, scenario.getPattern(), intensity, now);
                case CAPSULE -> generateCapsuleReadings(state, scenario.getPattern(), intensity, now);
                default -> Map.of();
            };

            try {
                ingestionPort.ingest(inst.deviceId(), readings, now);
            } catch (Exception e) {
                log.warn("Failed to ingest synthetic data for device [{}]: {}", inst.deviceId(), e.getMessage());
            }
        }
    }

    /**
     * Select which livestock receive anomaly injection.
     * Called only when scenario pattern != NORMAL and no active SYNTHETIC labels exist yet.
     */
    private Set<Long> selectAnomalyTargetsIfNeeded(
            List<ActiveInstallationInfo> installations,
            SynthesisScenario scenario, Instant now) {
        if (scenario.getPattern() == AnomalyPattern.NORMAL) return Set.of();

        // Check if any state already has active anomaly for this scenario
        boolean hasActive = states.values().stream()
                .anyMatch(s -> s.activePattern == scenario.getPattern()
                        && s.anomalyEnd != null && now.isBefore(s.anomalyEnd));
        if (hasActive) {
            // Return the set of livestock already in anomaly
            Set<Long> active = new HashSet<>();
            for (var entry : states.entrySet()) {
                SynthesisState s = entry.getValue();
                if (s.activePattern == scenario.getPattern()
                        && s.anomalyEnd != null && now.isBefore(s.anomalyEnd)) {
                    active.add(entry.getKey());
                }
            }
            return active;
        }

        // No active anomaly — select new targets by penetration rate
        List<Long> allLivestock = installations.stream()
                .map(ActiveInstallationInfo::livestockId).distinct().toList();
        int targetCount = Math.max(1, (int) Math.round(allLivestock.size() * scenario.getPenetrationRate()));
        Collections.shuffle(allLivestock);
        return new HashSet<>(allLivestock.subList(0, Math.min(targetCount, allLivestock.size())));
    }

    /**
     * Start or expire anomaly state for a livestock. Writes GroundTruthLabel on start.
     */
    private void updateAnomalyState(SynthesisState state, Long livestockId,
            SynthesisScenario scenario, Set<Long> anomalyTargets, Instant now) {
        // Check expiry first
        if (state.activePattern != null && state.anomalyEnd != null && !now.isBefore(state.anomalyEnd)) {
            state.activePattern = null;
            state.anomalyStart = null;
            state.anomalyEnd = null;
        }

        if (anomalyTargets.contains(livestockId) && state.activePattern == null) {
            // Start new anomaly
            AnomalyPattern pattern = scenario.getPattern();
            Duration duration = pattern.getDuration();
            state.activePattern = pattern;
            state.anomalyStart = now;
            state.anomalyEnd = now.plus(duration);

            // Write ground-truth label (independent transaction via labelService)
            GroundTruthLabel label = new GroundTruthLabel();
            label.setLivestockId(livestockId);
            label.setPattern(pattern);
            label.setPeriodStart(now);
            label.setPeriodEnd(now.plus(duration));
            label.setSource(LabelSource.SYNTHETIC);
            label.setSeverity(0.8);
            label.setLabeledAt(now);
            labelService.saveLabel(label);
        }
    }

    private double calculateIntensity(SynthesisState state, Instant now) {
        if (state.activePattern == null || !state.isInAnomaly(now)) return 0.0;
        long totalSecs = Duration.between(state.anomalyStart, state.anomalyEnd).getSeconds();
        long elapsedSecs = Duration.between(state.anomalyStart, now).getSeconds();
        double progress = totalSecs > 0 ? (double) elapsedSecs / totalSecs : 0.0;
        return state.activePattern.getTemporalShape().intensityFactor(progress);
    }

    // --- Reading generators (migrated from TelemetrySimulator + intensity modulation) ---

    private Map<String, Object> generateTrackerReadings(
            SynthesisState state, AnomalyPattern pattern, double intensity, Instant now) {
        Map<String, Object> readings = new HashMap<>();
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        int hour = now.atZone(ZoneId.of("Asia/Shanghai")).getHour();
        double hourFactor = (hour >= 6 && hour <= 20) ? 1.0 : 0.2;

        // Step count: circadian rhythm, modulated by anomaly
        int baseSteps;
        if (hour >= 6 && hour <= 20) {
            baseSteps = rng.nextInt(800, 2501);
        } else {
            baseSteps = rng.nextInt(50, 301);
        }
        // Anomaly modulation
        if (pattern == AnomalyPattern.ESTRUS) {
            baseSteps = (int) (baseSteps * (1.0 + intensity * 1.5));
        } else if (pattern == AnomalyPattern.LAMENESS) {
            baseSteps = (int) (baseSteps * (1.0 - intensity * 0.7));
        }
        readings.put("stepCount", Math.min(Math.max(baseSteps, 0), 65535));

        // Distance from steps
        double distance = baseSteps * rng.nextDouble(0.3, 0.6);
        readings.put("distanceMeters", round(distance, 1));

        // Accelerometer (s16 range)
        readings.put("accelX", rng.nextInt(-2000, 2001));
        readings.put("accelY", rng.nextInt(-2000, 2001));
        readings.put("accelZ", rng.nextInt(-2000, 2001));

        // GPS: random walk (migrated from GPS consolidation design)
        double step = rng.nextDouble(0.0002, 0.0005);
        double bearing = rng.nextDouble(0, 2 * Math.PI);
        state.currentLat += step * Math.sin(bearing);
        state.currentLng += step * Math.cos(bearing);
        readings.put("latitude", state.currentLat);
        readings.put("longitude", state.currentLng);

        // Battery: slow decay
        state.batteryLevel = Math.max(0, state.batteryLevel - rng.nextInt(0, 2));
        readings.put("batteryLevel", state.batteryLevel);

        // Activity index
        readings.put("activityIndex", round(hourFactor * rng.nextDouble(30, 80), 1));

        return readings;
    }

    private Map<String, Object> generateCapsuleReadings(
            SynthesisState state, AnomalyPattern pattern, double intensity, Instant now) {
        Map<String, Object> readings = new HashMap<>();
        ThreadLocalRandom rng = ThreadLocalRandom.current();

        // 7 temperature points
        List<BigDecimal> temperatures = new ArrayList<>();
        double baseTemp = 38.5 + state.tempBaselineOffset;
        // Fever modulation
        if (pattern == AnomalyPattern.HIGH_FEVER && pattern.getTempMax() != null) {
            baseTemp += intensity * (pattern.getTempMax() - 38.5);
        } else if (pattern == AnomalyPattern.LOW_GRADE_FEVER && pattern.getTempMax() != null) {
            baseTemp += intensity * (pattern.getTempMax() - 38.5);
        }
        for (int i = 0; i < 7; i++) {
            double temp = baseTemp + rng.nextDouble(-0.15, 0.15);
            temperatures.add(BigDecimal.valueOf(round(temp, 2)));
        }
        readings.put("temperatures", temperatures);

        // Gastric motility (u32 raw value)
        long motility = state.motilityBaseline;
        // Motility anomaly modulation
        if (pattern == AnomalyPattern.ACUTE_MOTILITY_DROP) {
            motility = (long) (motility * (1.0 - intensity * 0.8));
        } else if (pattern == AnomalyPattern.CHRONIC_MOTILITY_DROP) {
            motility = (long) (motility * (1.0 - intensity * 0.6));
        }
        motility += rng.nextLong(-50000, 50001);
        readings.put("gastricMotility", Math.max(0, motility));

        // Accelerometer (u8 range)
        readings.put("accelX", rng.nextInt(0, 256));
        readings.put("accelY", rng.nextInt(0, 256));
        readings.put("accelZ", rng.nextInt(0, 256));

        // Battery voltage: slow decay
        state.batteryVoltage = Math.max(2800, state.batteryVoltage - rng.nextInt(0, 5));
        readings.put("batteryVoltage", state.batteryVoltage);

        return readings;
    }

    private static double round(double value, int places) {
        double scale = Math.pow(10, places);
        return Math.round(value * scale) / scale;
    }
}
