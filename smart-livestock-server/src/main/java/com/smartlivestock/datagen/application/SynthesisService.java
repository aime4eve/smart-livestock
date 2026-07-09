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

        Set<Long> targets = selectTargetsIfNeeded(installations, scenario, now);

        for (ActiveInstallationInfo inst : installations) {
            SynthesisState state = states.computeIfAbsent(
                    inst.livestockId(), id -> SynthesisState.create(id, inst));

            // Layer 1: baseline data (all categories)
            Map<String, Object> readings = generateBaseline(inst, state, now);

            // Layer 2: category-specific overlay
            switch (scenario.getType().getCategory()) {
                case HEALTH -> applyHealthModulation(readings, state, scenario, targets, inst.livestockId(), now);
                case FENCE  -> applyFenceDisplacement(readings, state, scenario, targets, inst, now);
                case BASELINE -> {}
            }

            try {
                ingestionPort.ingest(inst.deviceId(), readings, now);
            } catch (Exception e) {
                log.warn("Failed to ingest for device [{}]: {}", inst.deviceId(), e.getMessage());
            }
        }
    }

    // --- Target selection ---

    private Set<Long> selectTargetsIfNeeded(List<ActiveInstallationInfo> installations,
            SynthesisScenario scenario, Instant now) {
        if (scenario.getType().getCategory() == ScenarioType.Category.BASELINE) return Set.of();

        boolean hasActive = states.values().stream().anyMatch(s ->
                s.activeType == scenario.getType() && s.isInEvent(now));
        if (hasActive) {
            Set<Long> active = new HashSet<>();
            for (var entry : states.entrySet()) {
                SynthesisState s = entry.getValue();
                if (s.activeType == scenario.getType() && s.isInEvent(now)) active.add(entry.getKey());
            }
            return active;
        }

        List<Long> all = installations.stream()
                .map(ActiveInstallationInfo::livestockId).distinct().toList();
        int count = Math.max(1, (int) Math.round(all.size() * scenario.getPenetrationRate()));
        Collections.shuffle(all);
        return new HashSet<>(all.subList(0, Math.min(count, all.size())));
    }

    // --- Event lifecycle management ---

    private void updateEventLifecycle(SynthesisState state, ScenarioType type,
            Long livestockId, Set<Long> targets, Instant now) {
        // Expire
        if (state.activeType != null && state.eventEnd != null && !now.isBefore(state.eventEnd)) {
            state.activeType = null;
            state.eventStart = null;
            state.eventEnd = null;
        }
        // Start new event
        if (targets.contains(livestockId) && state.activeType == null) {
            Duration duration = type.getDefaultDuration();
            state.activeType = type;
            state.eventStart = now;
            state.eventEnd = now.plus(duration);
            writeLabel(livestockId, type, now, state.eventEnd);
        }
    }

    private void writeLabel(Long livestockId, ScenarioType type, Instant start, Instant end) {
        GroundTruthLabel label = new GroundTruthLabel();
        label.setLivestockId(livestockId);
        label.setType(type);
        label.setPeriodStart(start);
        label.setPeriodEnd(end);
        label.setSource(LabelSource.SYNTHETIC);
        label.setSeverity(0.8);
        label.setLabeledAt(start);
        labelService.saveLabel(label);
    }

    // --- HEALTH modulation (unified formula) ---

    private void applyHealthModulation(Map<String, Object> readings, SynthesisState state,
            SynthesisScenario scenario, Set<Long> targets, Long livestockId, Instant now) {
        updateEventLifecycle(state, scenario.getType(), livestockId, targets, now);
        if (!state.isInEvent(now)) return;

        double intensity = scenario.getType().getTemporalShape().intensityFactor(state.eventProgress(now));
        DimensionModulation mod = scenario.getType().getModulation();
        if (mod == null) return;

        // Unified modulation formula
        // Temperature (CAPSULE only)
        if (readings.containsKey("temperatures")) {
            @SuppressWarnings("unchecked")
            List<BigDecimal> temps = (List<BigDecimal>) readings.get("temperatures");
            List<BigDecimal> modulated = new ArrayList<>();
            for (BigDecimal t : temps) {
                double v = t.doubleValue() + intensity * mod.tempDelta();
                modulated.add(BigDecimal.valueOf(round(v, 2)));
            }
            readings.put("temperatures", modulated);
        }
        // Motility (CAPSULE only)
        if (readings.containsKey("gastricMotility")) {
            long m = ((Number) readings.get("gastricMotility")).longValue();
            m = (long) (m * (1.0 + intensity * (mod.motilityRatio() - 1.0)));
            readings.put("gastricMotility", Math.max(0, m));
        }
        // Activity index
        if (readings.containsKey("activityIndex")) {
            double a = ((Number) readings.get("activityIndex")).doubleValue();
            a = a * (1.0 + intensity * (mod.activityRatio() - 1.0));
            readings.put("activityIndex", round(Math.max(0, a), 1));
        }
        // Steps
        if (readings.containsKey("stepCount")) {
            int s = ((Number) readings.get("stepCount")).intValue();
            s = (int) (s * (1.0 + intensity * (mod.stepRatio() - 1.0)));
            readings.put("stepCount", Math.min(Math.max(s, 0), 65535));
        }
    }

    // --- FENCE displacement ---

    private void applyFenceDisplacement(Map<String, Object> readings, SynthesisState state,
            SynthesisScenario scenario, Set<Long> targets, ActiveInstallationInfo inst, Instant now) {
        updateEventLifecycle(state, scenario.getType(), inst.livestockId(), targets, now);
        if (!state.isInEvent(now)) return;
        if (inst.deviceType() != com.smartlivestock.iot.domain.model.DeviceType.TRACKER) return;

        List<FenceGeometryInfo> fences = fenceQueryPort.findActiveFencesByLivestockId(inst.livestockId());
        if (fences.isEmpty()) return;

        FenceGeometryInfo fence = fences.get(ThreadLocalRandom.current().nextInt(fences.size()));
        List<CoordinateInfo> vertices = fence.vertices();
        if (vertices.size() < 3) return;

        double maxLat = vertices.stream().mapToDouble(CoordinateInfo::latitude).max().getAsDouble();
        double minLng = vertices.stream().mapToDouble(CoordinateInfo::longitude).min().getAsDouble();
        double maxLng = vertices.stream().mapToDouble(CoordinateInfo::longitude).max().getAsDouble();

        if (scenario.getType() == ScenarioType.FENCE_BREACH) {
            state.currentLat = maxLat + 0.0005;
            state.currentLng = (minLng + maxLng) / 2;
        } else {
            state.currentLat = maxLat - 0.0001;
            state.currentLng = (minLng + maxLng) / 2;
        }
        readings.put("latitude", state.currentLat);
        readings.put("longitude", state.currentLng);
    }

    // --- Baseline generation (shared by all categories) ---

    private Map<String, Object> generateBaseline(ActiveInstallationInfo inst, SynthesisState state, Instant now) {
        return switch (inst.deviceType()) {
            case TRACKER -> generateTrackerBaseline(state, now);
            case CAPSULE -> generateCapsuleBaseline(state, now);
            default -> Map.of();
        };
    }

    private Map<String, Object> generateTrackerBaseline(SynthesisState state, Instant now) {
        Map<String, Object> readings = new HashMap<>();
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        int hour = now.atZone(ZoneId.of("Asia/Shanghai")).getHour();
        double hourFactor = (hour >= 6 && hour <= 20) ? 1.0 : 0.2;

        int baseSteps = (hour >= 6 && hour <= 20) ? rng.nextInt(800, 2501) : rng.nextInt(50, 301);
        readings.put("stepCount", Math.min(baseSteps, 65535));
        readings.put("distanceMeters", round(baseSteps * rng.nextDouble(0.3, 0.6), 1));
        readings.put("accelX", rng.nextInt(-2000, 2001));
        readings.put("accelY", rng.nextInt(-2000, 2001));
        readings.put("accelZ", rng.nextInt(-2000, 2001));

        double step = rng.nextDouble(0.0002, 0.0005);
        double bearing = rng.nextDouble(0, 2 * Math.PI);
        state.currentLat += step * Math.sin(bearing);
        state.currentLng += step * Math.cos(bearing);
        readings.put("latitude", state.currentLat);
        readings.put("longitude", state.currentLng);

        state.batteryLevel = Math.max(0, state.batteryLevel - rng.nextInt(0, 2));
        readings.put("battery", state.batteryLevel);
        readings.put("rssi", rng.nextInt(-70, -41));
        readings.put("snr", String.valueOf(round(rng.nextDouble(8, 14), 1)));
        readings.put("gatewayId", "datagen-gw-01");
        readings.put("activityIndex", round(hourFactor * rng.nextDouble(30, 80), 1));
        return readings;
    }

    private Map<String, Object> generateCapsuleBaseline(SynthesisState state, Instant now) {
        Map<String, Object> readings = new HashMap<>();
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        int hour = now.atZone(ZoneId.of("Asia/Shanghai")).getHour();
        double hourFactor = (hour >= 6 && hour <= 20) ? 1.0 : 0.2;

        List<BigDecimal> temperatures = new ArrayList<>();
        double baseTemp = 38.5 + state.tempBaselineOffset;
        for (int i = 0; i < 7; i++) {
            double temp = baseTemp + rng.nextDouble(-0.15, 0.15);
            temperatures.add(BigDecimal.valueOf(round(temp, 2)));
        }
        readings.put("temperatures", temperatures);

        long motility = state.motilityBaseline + rng.nextLong(-50000, 50001);
        readings.put("gastricMotility", Math.max(0, motility));

        readings.put("accelX", rng.nextInt(0, 256));
        readings.put("accelY", rng.nextInt(0, 256));
        readings.put("accelZ", rng.nextInt(0, 256));

        state.batteryVoltage = Math.max(2800, state.batteryVoltage - rng.nextInt(0, 5));
        readings.put("batteryVoltage", state.batteryVoltage);
        readings.put("battery", rng.nextInt(85, 100));
        readings.put("rssi", rng.nextInt(-70, -41));
        readings.put("snr", String.valueOf(round(rng.nextDouble(8, 14), 1)));
        readings.put("gatewayId", "datagen-gw-01");

        readings.put("activityIndex", round(hourFactor * rng.nextDouble(30, 80), 1));
        return readings;
    }

    private static double round(double value, int places) {
        double scale = Math.pow(10, places);
        return Math.round(value * scale) / scale;
    }
}
