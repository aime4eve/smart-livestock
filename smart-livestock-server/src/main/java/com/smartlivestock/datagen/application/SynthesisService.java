package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.*;
import com.smartlivestock.datagen.domain.port.DeviceQueryPort;
import com.smartlivestock.datagen.domain.port.FenceQueryPort;
import com.smartlivestock.datagen.domain.port.TelemetryIngestionPort;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import com.smartlivestock.datagen.domain.port.dto.CoordinateInfo;
import com.smartlivestock.datagen.domain.port.dto.FenceGeometryInfo;
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
 * Unified synthesis engine: three-layer model.
 *
 * Layer 1: Baseline data generation (normal circadian rhythm + noise)
 * Layer 2: Health scenario overlay (multi-dimensional anomaly modulation)
 * Layer 3: Fence scenario overlay (GPS displacement to outside/approaching fence)
 *
 * Design §8A: generate() does NOT have @Transactional.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SynthesisService {

    private final TelemetryIngestionPort ingestionPort;
    private final DeviceQueryPort deviceQueryPort;
    private final FenceQueryPort fenceQueryPort;
    private final SynthesisScenarioRepository scenarioRepository;
    private final GroundTruthLabelService labelService;

    private final ConcurrentHashMap<Long, SynthesisState> states = new ConcurrentHashMap<>();

    public void generate(SynthesisScenario scenario) {
        List<ActiveInstallationInfo> installations = deviceQueryPort.findActiveInstallations();
        if (installations.isEmpty()) return;

        Instant now = Instant.now();
        if (!scenario.isActiveAt(now)) return;

        ScenarioType type = scenario.getScenarioType();
        Set<Long> targets = selectTargetsIfNeeded(installations, scenario, now);

        for (ActiveInstallationInfo inst : installations) {
            SynthesisState state = states.computeIfAbsent(
                    inst.livestockId(), id -> SynthesisState.create(id, inst));

            // Update active scenario state (health or fence)
            if (type == ScenarioType.HEALTH) {
                updateHealthState(state, inst.livestockId(), scenario, targets, now);
            } else {
                updateFenceState(state, inst.livestockId(), scenario, targets, now);
            }

            double intensity = calculateHealthIntensity(state, now);

            // Layer 1 + 2: Generate readings with health modulation
            Map<String, Object> readings = switch (inst.deviceType()) {
                case TRACKER -> generateTrackerReadings(state, scenario, intensity, now);
                case CAPSULE -> generateCapsuleReadings(state, scenario, intensity, now);
                default -> Map.of();
            };

            // Layer 3: Fence displacement overlay (TRACKER only)
            if ((type == ScenarioType.FENCE_BREACH || type == ScenarioType.FENCE_APPROACH)
                    && inst.deviceType() == com.smartlivestock.iot.domain.model.DeviceType.TRACKER
                    && state.isInFenceScenario(now)) {
                applyFenceDisplacement(state, scenario, inst.livestockId(), now, readings);
            }

            try {
                ingestionPort.ingest(inst.deviceId(), readings, now);
            } catch (Exception e) {
                log.warn("Failed to ingest synthetic data for device [{}]: {}", inst.deviceId(), e.getMessage());
            }
        }
    }

    // --- Target selection ---

    private Set<Long> selectTargetsIfNeeded(List<ActiveInstallationInfo> installations,
            SynthesisScenario scenario, Instant now) {
        boolean isNormal = (scenario.getScenarioType() == ScenarioType.HEALTH
                && scenario.getPattern() == AnomalyPattern.NORMAL);
        if (isNormal) return Set.of();

        // Check if any state already has active scenario
        boolean hasActive = states.values().stream().anyMatch(s ->
                (scenario.getScenarioType() == ScenarioType.HEALTH
                    ? (s.activePattern == scenario.getPattern() && now.isBefore(s.anomalyEnd))
                    : (s.activeFenceScenario == scenario.getScenarioType() && now.isBefore(s.fenceScenarioEnd))));
        if (hasActive) {
            Set<Long> active = new HashSet<>();
            for (var entry : states.entrySet()) {
                SynthesisState s = entry.getValue();
                boolean isActive = scenario.getScenarioType() == ScenarioType.HEALTH
                    ? (s.activePattern == scenario.getPattern() && now.isBefore(s.anomalyEnd))
                    : (s.activeFenceScenario == scenario.getScenarioType() && now.isBefore(s.fenceScenarioEnd));
                if (isActive) active.add(entry.getKey());
            }
            return active;
        }

        List<Long> allLivestock = installations.stream()
                .map(ActiveInstallationInfo::livestockId).distinct().toList();
        int targetCount = Math.max(1, (int) Math.round(allLivestock.size() * scenario.getPenetrationRate()));
        Collections.shuffle(allLivestock);
        return new HashSet<>(allLivestock.subList(0, Math.min(targetCount, allLivestock.size())));
    }

    // --- Health state management ---

    private void updateHealthState(SynthesisState state, Long livestockId,
            SynthesisScenario scenario, Set<Long> targets, Instant now) {
        // Check expiry
        if (state.activePattern != null && state.anomalyEnd != null && !now.isBefore(state.anomalyEnd)) {
            state.activePattern = null;
            state.anomalyStart = null;
            state.anomalyEnd = null;
        }
        if (targets.contains(livestockId) && state.activePattern == null
                && scenario.getPattern() != AnomalyPattern.NORMAL) {
            AnomalyPattern pattern = scenario.getPattern();
            state.activePattern = pattern;
            state.anomalyStart = now;
            state.anomalyEnd = now.plus(pattern.getDuration());
            writeHealthLabel(livestockId, pattern, now, state.anomalyEnd);
        }
    }

    private void writeHealthLabel(Long livestockId, AnomalyPattern pattern, Instant start, Instant end) {
        GroundTruthLabel label = new GroundTruthLabel();
        label.setLivestockId(livestockId);
        label.setScenarioType(ScenarioType.HEALTH);
        label.setPattern(pattern);
        label.setPeriodStart(start);
        label.setPeriodEnd(end);
        label.setSource(LabelSource.SYNTHETIC);
        label.setSeverity(0.8);
        label.setLabeledAt(start);
        labelService.saveLabel(label);
    }

    private double calculateHealthIntensity(SynthesisState state, Instant now) {
        if (state.activePattern == null || !state.isInAnomaly(now)) return 0.0;
        long total = Duration.between(state.anomalyStart, state.anomalyEnd).getSeconds();
        long elapsed = Duration.between(state.anomalyStart, now).getSeconds();
        double progress = total > 0 ? (double) elapsed / total : 0.0;
        return state.activePattern.getTemporalShape().intensityFactor(progress);
    }

    // --- Fence state management ---

    private void updateFenceState(SynthesisState state, Long livestockId,
            SynthesisScenario scenario, Set<Long> targets, Instant now) {
        // Check expiry
        if (state.activeFenceScenario != null && state.fenceScenarioEnd != null
                && !now.isBefore(state.fenceScenarioEnd)) {
            state.activeFenceScenario = null;
            state.fenceScenarioStart = null;
            state.fenceScenarioEnd = null;
        }
        if (targets.contains(livestockId) && state.activeFenceScenario == null) {
            state.activeFenceScenario = scenario.getScenarioType();
            state.fenceScenarioStart = now;
            state.fenceScenarioEnd = now.plus(Duration.ofMinutes(30));
            writeFenceLabel(livestockId, scenario.getScenarioType(), now, state.fenceScenarioEnd);
        }
    }

    private void writeFenceLabel(Long livestockId, ScenarioType type, Instant start, Instant end) {
        GroundTruthLabel label = new GroundTruthLabel();
        label.setLivestockId(livestockId);
        label.setScenarioType(type);
        label.setPattern(AnomalyPattern.NORMAL);
        label.setPeriodStart(start);
        label.setPeriodEnd(end);
        label.setSource(LabelSource.SYNTHETIC);
        label.setSeverity(0.9);
        label.setLabeledAt(start);
        labelService.saveLabel(label);
    }

    // --- Layer 3: Fence displacement ---

    private void applyFenceDisplacement(SynthesisState state, SynthesisScenario scenario,
            Long livestockId, Instant now, Map<String, Object> readings) {
        List<FenceGeometryInfo> fences = fenceQueryPort.findActiveFencesByLivestockId(livestockId);
        if (fences.isEmpty()) return;

        FenceGeometryInfo fence = fences.get(ThreadLocalRandom.current().nextInt(fences.size()));
        List<CoordinateInfo> vertices = fence.vertices();
        if (vertices.size() < 3) return;

        double maxLat = vertices.stream().mapToDouble(CoordinateInfo::latitude).max().getAsDouble();
        double minLat = vertices.stream().mapToDouble(CoordinateInfo::latitude).min().getAsDouble();
        double minLng = vertices.stream().mapToDouble(CoordinateInfo::longitude).min().getAsDouble();
        double maxLng = vertices.stream().mapToDouble(CoordinateInfo::longitude).max().getAsDouble();
        double centerLng = (minLng + maxLng) / 2;

        if (scenario.getScenarioType() == ScenarioType.FENCE_BREACH) {
            // Move ~50m beyond north edge
            state.currentLat = maxLat + 0.0005;
            state.currentLng = centerLng;
        } else {
            // FENCE_APPROACH: near edge, still inside
            state.currentLat = maxLat - 0.0001;
            state.currentLng = centerLng;
        }

        readings.put("latitude", state.currentLat);
        readings.put("longitude", state.currentLng);
    }

    // --- Reading generators with multi-dimensional modulation ---

    private Map<String, Object> generateTrackerReadings(
            SynthesisState state, SynthesisScenario scenario, double intensity, Instant now) {
        Map<String, Object> readings = new HashMap<>();
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        int hour = now.atZone(ZoneId.of("Asia/Shanghai")).getHour();
        double hourFactor = (hour >= 6 && hour <= 20) ? 1.0 : 0.2;

        AnomalyPattern pattern = state.activePattern != null ? state.activePattern : AnomalyPattern.NORMAL;

        // Step count: circadian + anomaly modulation
        int baseSteps = (hour >= 6 && hour <= 20) ? rng.nextInt(800, 2501) : rng.nextInt(50, 301);
        double stepMod = getStepModulation(pattern, intensity);
        int steps = (int) (baseSteps * (1.0 + stepMod));
        readings.put("stepCount", Math.min(Math.max(steps, 0), 65535));

        double distance = steps * rng.nextDouble(0.3, 0.6);
        readings.put("distanceMeters", round(distance, 1));

        readings.put("accelX", rng.nextInt(-2000, 2001));
        readings.put("accelY", rng.nextInt(-2000, 2001));
        readings.put("accelZ", rng.nextInt(-2000, 2001));

        // GPS: random walk (unless fence scenario overrides later)
        double step = rng.nextDouble(0.0002, 0.0005);
        double bearing = rng.nextDouble(0, 2 * Math.PI);
        state.currentLat += step * Math.sin(bearing);
        state.currentLng += step * Math.cos(bearing);
        readings.put("latitude", state.currentLat);
        readings.put("longitude", state.currentLng);

        state.batteryLevel = Math.max(0, state.batteryLevel - rng.nextInt(0, 2));
        readings.put("batteryLevel", state.batteryLevel);

        // Activity index: NOW modulated by anomaly (fix: was random-only before)
        double baseActivity = hourFactor * rng.nextDouble(30, 80);
        double activityMod = getActivityModulation(pattern, intensity);
        readings.put("activityIndex", round(Math.max(0, baseActivity * (1.0 + activityMod)), 1));

        return readings;
    }

    private Map<String, Object> generateCapsuleReadings(
            SynthesisState state, SynthesisScenario scenario, double intensity, Instant now) {
        Map<String, Object> readings = new HashMap<>();
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        AnomalyPattern pattern = state.activePattern != null ? state.activePattern : AnomalyPattern.NORMAL;

        // Temperature: baseline + fever modulation + correlated temp rise
        List<BigDecimal> temperatures = new ArrayList<>();
        double baseTemp = 38.5 + state.tempBaselineOffset;
        double tempMod = getTempModulation(pattern, intensity);
        baseTemp += tempMod;
        for (int i = 0; i < 7; i++) {
            double temp = baseTemp + rng.nextDouble(-0.15, 0.15);
            temperatures.add(BigDecimal.valueOf(round(temp, 2)));
        }
        readings.put("temperatures", temperatures);

        // Gastric motility: baseline + anomaly modulation
        long motility = state.motilityBaseline;
        double motilityMod = getMotilityModulation(pattern, intensity);
        motility = (long) (motility * (1.0 + motilityMod));
        motility += rng.nextLong(-50000, 50001);
        readings.put("gastricMotility", Math.max(0, motility));

        readings.put("accelX", rng.nextInt(0, 256));
        readings.put("accelY", rng.nextInt(0, 256));
        readings.put("accelZ", rng.nextInt(0, 256));

        state.batteryVoltage = Math.max(2800, state.batteryVoltage - rng.nextInt(0, 5));
        readings.put("batteryVoltage", state.batteryVoltage);

        // Fix: CAPSULE also generates activityIndex (needed by ai-platform's 3rd dimension)
        int hour = now.atZone(ZoneId.of("Asia/Shanghai")).getHour();
        double hourFactor = (hour >= 6 && hour <= 20) ? 1.0 : 0.2;
        double baseActivity = hourFactor * rng.nextDouble(30, 80);
        double activityMod = getActivityModulation(pattern, intensity);
        readings.put("activityIndex", round(Math.max(0, baseActivity * (1.0 + activityMod)), 1));

        return readings;
    }

    // --- Multi-dimensional modulation functions (design §3.2 table) ---

    private double getActivityModulation(AnomalyPattern pattern, double intensity) {
        return switch (pattern) {
            case LOW_GRADE_FEVER -> -intensity * 0.4;
            case HIGH_FEVER -> -intensity * 0.6;
            case CHRONIC_MOTILITY_DROP -> -intensity * 0.2;
            case ACUTE_MOTILITY_DROP -> -intensity * 0.3;
            case ESTRUS -> intensity * 0.8;
            case LAMENESS -> -intensity * 0.7;
            case NORMAL -> 0.0;
        };
    }

    private double getStepModulation(AnomalyPattern pattern, double intensity) {
        return switch (pattern) {
            case LOW_GRADE_FEVER -> -intensity * 0.3;
            case HIGH_FEVER -> -intensity * 0.5;
            case CHRONIC_MOTILITY_DROP -> -intensity * 0.15;
            case ACUTE_MOTILITY_DROP -> -intensity * 0.2;
            case ESTRUS -> intensity * 1.5;
            case LAMENESS -> -intensity * 0.7;
            case NORMAL -> 0.0;
        };
    }

    private double getTempModulation(AnomalyPattern pattern, double intensity) {
        return switch (pattern) {
            case LOW_GRADE_FEVER -> intensity * (pattern.getTempMax() - 38.5);
            case HIGH_FEVER -> intensity * (pattern.getTempMax() - 38.5);
            case CHRONIC_MOTILITY_DROP -> intensity * 0.5;  // correlated low-grade temp rise
            case ACUTE_MOTILITY_DROP -> 0.0;
            case ESTRUS -> 0.3;  // slight temp rise during estrus
            case LAMENESS -> 0.0;
            case NORMAL -> 0.0;
        };
    }

    private double getMotilityModulation(AnomalyPattern pattern, double intensity) {
        return switch (pattern) {
            case LOW_GRADE_FEVER -> -intensity * 0.2;
            case HIGH_FEVER -> -intensity * 0.3;
            case CHRONIC_MOTILITY_DROP -> -intensity * 0.6;
            case ACUTE_MOTILITY_DROP -> -intensity * 0.8;
            case ESTRUS -> 0.0;
            case LAMENESS -> -intensity * 0.1;
            case NORMAL -> 0.0;
        };
    }

    private static double round(double value, int places) {
        double scale = Math.pow(10, places);
        return Math.round(value * scale) / scale;
    }
}
