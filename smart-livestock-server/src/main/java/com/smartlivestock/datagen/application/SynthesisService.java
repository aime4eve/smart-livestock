package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.*;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TelemetrySource;
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
    static final Duration TRACKER_INTERVAL = Duration.ofMinutes(5);
    static final Duration CAPSULE_INTERVAL = Duration.ofMinutes(15);

    private final TelemetryIngestionPort ingestionPort;
    private final DeviceQueryPort deviceQueryPort;
    private final FenceQueryPort fenceQueryPort;
    private final SynthesisScenarioRepository scenarioRepository;
    private final GroundTruthLabelService labelService;

    private final ConcurrentHashMap<Long, SynthesisState> states = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<Long, Instant> nextDueByDevice = new ConcurrentHashMap<>();

    public void generate(SynthesisScenario scenario) {
        List<ActiveInstallationInfo> installations = deviceQueryPort.findActiveInstallations();
        if (installations.isEmpty()) return;

        Instant now = Instant.now();
        if (!scenario.isActiveAt(now)) return;

        Set<Long> targets = selectTargetsIfNeeded(installations, scenario, now);

        for (ActiveInstallationInfo inst : installations) {
            if (!isDue(inst, now)) continue;

            PrimaryFence primaryFence = primaryFenceFor(inst);
            SynthesisState state = states.computeIfAbsent(
                    inst.livestockId(), id -> SynthesisState.create(id, inst));
            if (!state.trackerPositionInitialized
                    && inst.deviceType() == DeviceType.TRACKER
                    && primaryFence != null) {
                constrainInitialState(state, primaryFence);
                state.trackerPositionInitialized = true;
            }

            // Layer 1: baseline data (all categories)
            Map<String, Object> readings = generateBaseline(inst, state, now, primaryFence);

            // Layer 2: category-specific overlay
           switch (scenario.getType().getCategory()) {
               case HEALTH -> applyHealthModulation(readings, state, scenario, targets, inst.livestockId(), now);
               case FENCE  -> applyFenceDisplacement(readings, state, scenario, targets, inst, now);
               case DEVICE -> applyDeviceFault(readings, state, scenario, targets, inst, now);
               case BASELINE -> {}
           }

            try {
                ingestionPort.ingest(inst.deviceId(), readings, now, TelemetrySource.DATAGEN);
            } catch (Exception e) {
                log.warn("Failed to ingest for device [{}]: {}", inst.deviceId(), e.getMessage());
            }
        }
    }

    private boolean isDue(ActiveInstallationInfo inst, Instant now) {
        Duration interval = switch (inst.deviceType()) {
            case TRACKER -> TRACKER_INTERVAL;
            case CAPSULE -> CAPSULE_INTERVAL;
            default -> null;
        };
        if (interval == null) return false;

        Instant due = nextDueByDevice.get(inst.deviceId());
        if (due != null && now.isBefore(due)) return false;

        // Set the next due time before ingestion so a failed row is retried only
        // at the next normal sampling interval, matching real device behavior.
        nextDueByDevice.put(inst.deviceId(), now.plus(interval));
        return true;
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

    // --- DEVICE fault modulation (Phase 3) ---

    private void applyDeviceFault(Map<String, Object> readings, SynthesisState state,
            SynthesisScenario scenario, Set<Long> targets, ActiveInstallationInfo inst, Instant now) {
        updateEventLifecycle(state, scenario.getType(), inst.livestockId(), targets, now);
        if (!state.isInEvent(now)) return;

        double progress = state.eventProgress(now);
        switch (scenario.getType()) {
            case DEVICE_LOW_BATTERY -> {
                // Battery linear decline: 100% → 15% over event duration
                int battery = (int) Math.round(100 - progress * 85);
                readings.put("battery", battery);
            }
            case DEVICE_SIGNAL_DEGRADATION -> {
                // RSSI: -40dBm → -95dBm; SNR: 14 → 3
                int rssi = (int) Math.round(-40 - progress * 55);
                readings.put("rssi", rssi);
                readings.put("snr", String.valueOf(round(14 - progress * 11, 1)));
            }
            case DEVICE_ANTI_DISASSEMBLY -> {
                // Trigger tamper alert mid-event
                if (progress > 0.3) {
                    readings.put("antiDisassemblyStatus", 1);
                }
            }
            default -> {}
        }
    }

    // --- Baseline generation (shared by all categories) ---

    private Map<String, Object> generateBaseline(
            ActiveInstallationInfo inst, SynthesisState state, Instant now, PrimaryFence primaryFence) {
        return switch (inst.deviceType()) {
            case TRACKER -> generateTrackerBaseline(state, now, primaryFence);
            case CAPSULE -> generateCapsuleBaseline(state, now);
            default -> Map.of();
        };
    }

    private Map<String, Object> generateTrackerBaseline(
            SynthesisState state, Instant now, PrimaryFence primaryFence) {
        Map<String, Object> readings = new HashMap<>();
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        int hour = now.atZone(ZoneId.of("Asia/Shanghai")).getHour();
        double hourFactor = (hour >= 6 && hour <= 20) ? 1.0 : 0.2;

        int baseSteps = (hour >= 6 && hour <= 20) ? rng.nextInt(60, 241) : rng.nextInt(10, 81);
        readings.put("stepCount", Math.min(baseSteps, 65535));
        readings.put("distanceMeters", round(baseSteps * rng.nextDouble(0.3, 0.6), 1));
        readings.put("accelX", rng.nextInt(-2000, 2001));
        readings.put("accelY", rng.nextInt(-2000, 2001));
        readings.put("accelZ", rng.nextInt(-2000, 2001));

        moveTracker(state, now, primaryFence);
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

    private PrimaryFence primaryFenceFor(ActiveInstallationInfo inst) {
        if (inst.deviceType() != DeviceType.TRACKER) return null;
        return fenceQueryPort.findActiveFencesByLivestockId(inst.livestockId()).stream()
                .filter(fence -> fence.vertices() != null && fence.vertices().size() >= 3)
                .findFirst()
                .map(fence -> new PrimaryFence(fence.vertices()))
                .orElse(null);
    }

    private void constrainInitialState(SynthesisState state, PrimaryFence fence) {
        if (containsPoint(fence, state.currentLat, state.currentLng)) return;

        double lat = 0;
        double lng = 0;
        for (CoordinateInfo vertex : fence.vertices()) {
            lat += vertex.latitude();
            lng += vertex.longitude();
        }
        state.currentLat = lat / fence.vertices().size();
        state.currentLng = lng / fence.vertices().size();
    }

    private boolean containsPoint(PrimaryFence fence, double latitude, double longitude) {
        List<CoordinateInfo> vertices = fence.vertices();
        boolean inside = false;
        for (int i = 0, j = vertices.size() - 1; i < vertices.size(); j = i++) {
            double yi = vertices.get(i).latitude();
            double xi = vertices.get(i).longitude();
            double yj = vertices.get(j).latitude();
            double xj = vertices.get(j).longitude();
            boolean intersects = ((yi > latitude) != (yj > latitude))
                    && (longitude < (xj - xi) * (latitude - yi) / (yj - yi) + xi);
            if (intersects) inside = !inside;
        }
        return inside;
    }

    private record PrimaryFence(List<CoordinateInfo> vertices) {}

    private void moveTracker(SynthesisState state, Instant now, PrimaryFence fence) {
        ThreadLocalRandom rng = ThreadLocalRandom.current();

        if (fence == null) {
            moveByStep(state, rng);
            return;
        }

        expireFenceExcursion(state, now);
        boolean excursionActive = state.isOnFenceExcursion(now);
        if (!excursionActive
                && state.fenceExcursionStart == null
                && rng.nextDouble() < 0.02) {
            state.fenceExcursionStart = now;
            state.fenceExcursionEnd = now.plus(Duration.ofMinutes(rng.nextInt(10, 31)));
            excursionActive = true;
        }

        // During an excursion prefer points outside; after it ends prefer a small
        // continuous walk back inside instead of snapping to the fence center.
        boolean preferOutside = excursionActive;
        double[] fallback = null;
        double centerLat = averageLatitude(fence.vertices());
        double centerLng = averageLongitude(fence.vertices());
        for (int attempt = 0; attempt < 12; attempt++) {
            double[] candidate = candidateStep(state, rng);
            if (containsPoint(fence, candidate[0], candidate[1]) != preferOutside) continue;
            state.currentLat = candidate[0];
            state.currentLng = candidate[1];
            return;
        }

        if (!preferOutside) {
            fallback = fallbackTowardCenter(state, fence, centerLat, centerLng, rng);
            if (fallback != null) {
                state.currentLat = fallback[0];
                state.currentLng = fallback[1];
            }
        }
    }

    private void expireFenceExcursion(SynthesisState state, Instant now) {
        if (state.fenceExcursionEnd != null && !now.isBefore(state.fenceExcursionEnd)) {
            state.fenceExcursionStart = null;
            state.fenceExcursionEnd = null;
        }
    }

    private void moveByStep(SynthesisState state, ThreadLocalRandom rng) {
        double[] next = candidateStep(state, rng);
        state.currentLat = next[0];
        state.currentLng = next[1];
    }

    private double[] candidateStep(SynthesisState state, ThreadLocalRandom rng) {
        double meters = rng.nextDouble(10, 40);
        double bearing = rng.nextDouble(0, 2 * Math.PI);
        double latitudeStep = meters / 111_000d;
        double longitudeStep = meters
                / (111_000d * Math.max(0.1, Math.cos(Math.toRadians(state.currentLat))));
        return new double[]{
                state.currentLat + latitudeStep * Math.sin(bearing),
                state.currentLng + longitudeStep * Math.cos(bearing)
        };
    }

    private double[] fallbackTowardCenter(
            SynthesisState state, PrimaryFence fence,
            double centerLat, double centerLng, ThreadLocalRandom rng) {
        double latDeltaMeters = (centerLat - state.currentLat) * 111_000d;
        double lngDeltaMeters = (centerLng - state.currentLng)
                * 111_000d * Math.cos(Math.toRadians(state.currentLat));
        double centerDistance = Math.hypot(latDeltaMeters, lngDeltaMeters);

        double stepMeters = rng.nextDouble(10, 20);
        double bearing;
        if (centerDistance > 1) {
            bearing = Math.atan2(latDeltaMeters, lngDeltaMeters);
            stepMeters = Math.min(stepMeters, centerDistance * 0.8);
        } else {
            bearing = rng.nextDouble(0, 2 * Math.PI);
        }

        double latitudeStep = stepMeters * Math.sin(bearing) / 111_000d;
        double longitudeStep = stepMeters * Math.cos(bearing)
                / (111_000d * Math.max(0.1, Math.cos(Math.toRadians(state.currentLat))));
        double[] candidate = {state.currentLat + latitudeStep, state.currentLng + longitudeStep};
        return containsPoint(fence, candidate[0], candidate[1]) ? candidate : null;
    }

    private double averageLatitude(List<CoordinateInfo> vertices) {
        return vertices.stream().mapToDouble(CoordinateInfo::latitude).average().orElse(0);
    }

    private double averageLongitude(List<CoordinateInfo> vertices) {
        return vertices.stream().mapToDouble(CoordinateInfo::longitude).average().orElse(0);
    }

    private Map<String, Object> generateCapsuleBaseline(SynthesisState state, Instant now) {
        Map<String, Object> readings = new HashMap<>();
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        int hour = now.atZone(ZoneId.of("Asia/Shanghai")).getHour();
        double hourFactor = (hour >= 6 && hour <= 20) ? 1.0 : 0.2;

        updateDemoHealthEvent(state, now);
        List<BigDecimal> temperatures = new ArrayList<>();
        double baseTemp = 38.5 + state.tempBaselineOffset;
        for (int i = 0; i < 7; i++) {
            Instant pointTime = now.minus(Duration.ofMinutes(5L * (6 - i)));
            double temp = baseTemp + demoTemperatureDelta(state, pointTime)
                    + rng.nextDouble(-0.12, 0.12);
            temperatures.add(BigDecimal.valueOf(round(temp, 2)));
        }
        readings.put("temperatures", temperatures);

        long motility = Math.round(state.motilityBaseline
                * demoMotilityRatio(state, now)) + rng.nextLong(-25000, 25001);
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

    private void updateDemoHealthEvent(SynthesisState state, Instant now) {
        if (state.demoHealthEvent != SynthesisState.DemoHealthEvent.NONE) {
            if (now.isBefore(state.demoHealthEventEnd)) return;
            state.demoHealthEvent = SynthesisState.DemoHealthEvent.NONE;
            state.demoHealthEventStart = null;
            state.demoHealthEventEnd = null;
        }

        ThreadLocalRandom rng = ThreadLocalRandom.current();
        if (rng.nextDouble() >= 0.005) return;

        boolean fever = rng.nextBoolean();
        state.demoHealthEvent = fever
                ? SynthesisState.DemoHealthEvent.FEVER
                : SynthesisState.DemoHealthEvent.MOTILITY_DROP;
        state.demoHealthEventStart = now;
        state.demoHealthEventEnd = now.plus(Duration.ofHours(fever ? rng.nextInt(4, 9) : rng.nextInt(8, 13)));
    }

    private double demoTemperatureDelta(SynthesisState state, Instant pointTime) {
        if (state.demoHealthEvent != SynthesisState.DemoHealthEvent.FEVER) return 0;
        if (pointTime.isBefore(state.demoHealthEventStart)
                || !pointTime.isBefore(state.demoHealthEventEnd)) return 0;
        return eventIntensity(state.demoHealthEventProgress(pointTime)) * 1.8;
    }

    private double demoMotilityRatio(SynthesisState state, Instant now) {
        if (state.demoHealthEvent != SynthesisState.DemoHealthEvent.MOTILITY_DROP) return 1.0;
        if (now.isBefore(state.demoHealthEventStart)
                || !now.isBefore(state.demoHealthEventEnd)) return 1.0;
        return 1.0 - eventIntensity(state.demoHealthEventProgress(now)) * 0.6;
    }

    private double eventIntensity(double progress) {
        double p = Math.max(0.0, Math.min(1.0, progress));
        if (p < 0.4) return p / 0.4;
        if (p < 0.7) return 1.0;
        return 1.0 - (p - 0.7) / 0.3;
    }

    private static double round(double value, int places) {
        double scale = Math.pow(10, places);
        return Math.round(value * scale) / scale;
    }
}
