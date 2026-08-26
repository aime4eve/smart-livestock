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
import java.time.temporal.ChronoUnit;
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
    private final ConcurrentHashMap<Long, Instant> nextDueByDevice = new ConcurrentHashMap<>();

    public void clearDeviceSchedules(Collection<Long> deviceIds) {
        if (deviceIds == null || deviceIds.isEmpty()) return;
        for (Long deviceId : deviceIds) {
            nextDueByDevice.remove(deviceId);
        }
    }

    public void generate(SynthesisScenario scenario) {
        List<ActiveInstallationInfo> installations =
                deviceQueryPort.findActiveInstallationsByScenario(scenario.getId());
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
            Instant readingTime = inst.deviceType() == DeviceType.CAPSULE
                    ? stableSampleTime(now, 300) : now;
            Map<String, Object> readings = generateBaseline(
                    inst, state, readingTime, primaryFence, inst.rules());

            // Layer 2: category-specific overlay
           switch (scenario.getType().getCategory()) {
               case HEALTH -> applyHealthModulation(readings, state, scenario, targets, inst.livestockId(), now);
               case FENCE  -> applyFenceDisplacement(readings, state, scenario, targets, inst, now);
               case DEVICE -> applyDeviceFault(readings, state, scenario, targets, inst, now);
               case BASELINE -> {}
           }

            try {
                ingestionPort.ingest(inst.deviceId(), readings, readingTime, TelemetrySource.DATAGEN);
            } catch (Exception e) {
                log.warn("Failed to ingest for device [{}]: {}", inst.deviceId(), e.getMessage());
            }
        }
    }

    private boolean isDue(ActiveInstallationInfo inst, Instant now) {
        Duration interval = switch (inst.deviceType()) {
            case TRACKER -> Duration.ofSeconds(inst.rules().trackerIntervalSeconds());
            case CAPSULE -> Duration.ofSeconds(inst.rules().capsuleIntervalSeconds());
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
            ActiveInstallationInfo inst, SynthesisState state, Instant now,
            PrimaryFence primaryFence, DatagenFarmRules rules) {
        return switch (inst.deviceType()) {
            case TRACKER -> generateTrackerBaseline(state, now, primaryFence, rules);
            case CAPSULE -> generateCapsuleBaseline(state, now, rules);
            default -> Map.of();
        };
    }

    private Map<String, Object> generateTrackerBaseline(
            SynthesisState state, Instant now, PrimaryFence primaryFence,
            DatagenFarmRules rules) {
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

        moveTracker(state, now, primaryFence, rules);
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
                .map(fence -> new PrimaryFence(fence.fenceId(), fence.vertices()))
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
        state.activeFenceId = fence.fenceId();
        state.movementMode = SynthesisState.MovementMode.IN_FENCE;
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

    private record PrimaryFence(Long fenceId, List<CoordinateInfo> vertices) {}

    private void moveTracker(
            SynthesisState state, Instant now, PrimaryFence fence,
            DatagenFarmRules rules) {
        ThreadLocalRandom rng = ThreadLocalRandom.current();

        if (fence == null) {
            double[] next = boundedStep(state, rng, 25);
            state.currentLat = next[0];
            state.currentLng = next[1];
            return;
        }

        state.activeFenceId = fence.fenceId();
        expireFenceExcursion(state, now);

        if (state.movementMode == SynthesisState.MovementMode.RETURN) {
            returnToFence(state, fence);
            return;
        }

        if (state.movementMode == SynthesisState.MovementMode.EXCURSION) {
            moveDuringExcursion(state, now, fence, rng);
            return;
        }

        boolean otherExcursion = states.values().stream().anyMatch(other ->
                other.livestockId != state.livestockId
                        && fence.fenceId().equals(other.activeFenceId)
                        && other.movementMode == SynthesisState.MovementMode.EXCURSION);
        if (!otherExcursion
                && state.fenceExcursionStart == null
                && rng.nextDouble() < rules.fenceExcursionProbability()) {
            state.fenceExcursionStart = now;
            state.fenceExcursionEnd = now.plus(Duration.ofMinutes(randomMinutes(
                    rules.fenceExcursionMinMinutes(),
                    rules.fenceExcursionMaxMinutes())));
            state.movementMode = SynthesisState.MovementMode.EXCURSION;
            moveDuringExcursion(state, now, fence, rng);
            return;
        }

        moveInsideFence(state, fence, rng);
    }

    private void expireFenceExcursion(SynthesisState state, Instant now) {
        if (state.fenceExcursionEnd != null && !now.isBefore(state.fenceExcursionEnd)) {
            boolean outside = state.fenceExcursionStart != null;
            state.movementMode = outside
                    ? SynthesisState.MovementMode.RETURN
                    : SynthesisState.MovementMode.IN_FENCE;
            if (!outside) {
                state.fenceExcursionStart = null;
                state.fenceExcursionEnd = null;
            }
        }
    }

    private void moveInsideFence(
            SynthesisState state, PrimaryFence fence, ThreadLocalRandom rng) {
        double[] candidate = boundedStep(state, rng, 25);
        if (containsPoint(fence, candidate[0], candidate[1])) {
            state.currentLat = candidate[0];
            state.currentLng = candidate[1];
            return;
        }

        double[] target = interiorPointNearBoundary(fence, nearestBoundary(
                state.currentLat, state.currentLng, fence));
        double[] next = stepTowards(
                state.currentLat, state.currentLng, target[0], target[1], 20);
        // Always advance the walk. If the position is already outside because of
        // legacy state, this also starts bringing it back instead of freezing it.
        state.currentLat = next[0];
        state.currentLng = next[1];
        if (containsPoint(fence, state.currentLat, state.currentLng)) {
            state.movementMode = SynthesisState.MovementMode.IN_FENCE;
            state.fenceExcursionStart = null;
            state.fenceExcursionEnd = null;
        }
    }

    private void moveDuringExcursion(
            SynthesisState state, Instant now, PrimaryFence fence,
            ThreadLocalRandom rng) {
        if (!containsPoint(fence, state.currentLat, state.currentLng)) {
            double[] candidate = boundedStep(state, rng, 20);
            double distance = boundaryDistanceMeters(candidate[0], candidate[1], fence);
            if (!containsPoint(fence, candidate[0], candidate[1]) && distance <= 40) {
                state.currentLat = candidate[0];
                state.currentLng = candidate[1];
                return;
            }
            clampNearBoundary(state, fence, 25);
            return;
        }

        double[] target = boundedOutsideTarget(state, fence, rng);
        double[] next = stepTowards(
                state.currentLat, state.currentLng, target[0], target[1], 25);
        state.currentLat = next[0];
        state.currentLng = next[1];
        if (!containsPoint(fence, state.currentLat, state.currentLng)) {
            state.fenceExcursionStart = state.fenceExcursionStart == null
                    ? now : state.fenceExcursionStart;
            clampNearBoundary(state, fence, 35);
        }
    }

    private void returnToFence(SynthesisState state, PrimaryFence fence) {
        if (containsPoint(fence, state.currentLat, state.currentLng)) {
            state.movementMode = SynthesisState.MovementMode.IN_FENCE;
            state.fenceExcursionStart = null;
            state.fenceExcursionEnd = null;
            return;
        }
        double[] target = interiorPointNearBoundary(fence, nearestBoundary(
                state.currentLat, state.currentLng, fence));
        double[] next = stepTowards(
                state.currentLat, state.currentLng, target[0], target[1], 25);
        state.currentLat = next[0];
        state.currentLng = next[1];
        if (containsPoint(fence, state.currentLat, state.currentLng)) {
            state.movementMode = SynthesisState.MovementMode.IN_FENCE;
            state.activeFenceId = fence.fenceId();
            state.fenceExcursionStart = null;
            state.fenceExcursionEnd = null;
        }
    }

    private double[] boundedStep(
            SynthesisState state, ThreadLocalRandom rng, double maxMeters) {
        double meters = rng.nextDouble(8, maxMeters + 1);
        double bearing = rng.nextDouble(0, 2 * Math.PI);
        return offset(state.currentLat, state.currentLng, bearing, meters);
    }

    private double[] boundedOutsideTarget(
            SynthesisState state, PrimaryFence fence, ThreadLocalRandom rng) {
        double[] boundary = nearestBoundary(state.currentLat, state.currentLng, fence);
        for (int attempt = 0; attempt < 24; attempt++) {
            double bearing = rng.nextDouble(0, 2 * Math.PI);
            double distance = rng.nextDouble(12, 31);
            double[] candidate = offset(boundary[0], boundary[1], bearing, distance);
            if (!containsPoint(fence, candidate[0], candidate[1])) return candidate;
        }
        return offset(boundary[0], boundary[1], 0, 20);
    }

    private void clampNearBoundary(
            SynthesisState state, PrimaryFence fence, double distance) {
        double[] boundary = nearestBoundary(state.currentLat, state.currentLng, fence);
        double bearing = bearing(
                state.currentLat, state.currentLng, boundary[0], boundary[1]);
        // The vector from boundary back to the current point points outward.
        double outward = bearing + Math.PI;
        double[] bounded = offset(boundary[0], boundary[1], outward, distance);
        state.currentLat = bounded[0];
        state.currentLng = bounded[1];
    }

    private double[] interiorPointNearBoundary(PrimaryFence fence, double[] boundary) {
        double centerLat = averageLatitude(fence.vertices());
        double centerLng = averageLongitude(fence.vertices());
        double[] towardCenter = stepTowards(
                boundary[0], boundary[1], centerLat, centerLng, 5);
        if (containsPoint(fence, towardCenter[0], towardCenter[1])) return towardCenter;

        ThreadLocalRandom rng = ThreadLocalRandom.current();
        for (int attempt = 0; attempt < 24; attempt++) {
            double[] candidate = offset(
                    boundary[0], boundary[1], rng.nextDouble(0, 2 * Math.PI), 5);
            if (containsPoint(fence, candidate[0], candidate[1])) return candidate;
        }
        return new double[]{centerLat, centerLng};
    }

    private double[] stepTowards(
            double fromLat, double fromLng, double toLat, double toLng,
            double maxMeters) {
        double bearing = bearing(fromLat, fromLng, toLat, toLng);
        double distance = distanceMeters(fromLat, fromLng, toLat, toLng);
        return offset(fromLat, fromLng, bearing, Math.min(maxMeters, distance));
    }

    private double bearing(double fromLat, double fromLng, double toLat, double toLng) {
        double latDelta = (toLat - fromLat) * 111_000d;
        double lngDelta = (toLng - fromLng) * 111_000d
                * Math.cos(Math.toRadians(fromLat));
        if (Math.hypot(latDelta, lngDelta) < 0.01) return 0;
        return Math.atan2(latDelta, lngDelta);
    }

    private double distanceMeters(double fromLat, double fromLng,
                                  double toLat, double toLng) {
        double latDelta = (toLat - fromLat) * 111_000d;
        double lngDelta = (toLng - fromLng) * 111_000d
                * Math.cos(Math.toRadians(fromLat));
        return Math.hypot(latDelta, lngDelta);
    }

    private double[] offset(double lat, double lng, double bearing, double meters) {
        return new double[]{
                lat + meters * Math.sin(bearing) / 111_000d,
                lng + meters * Math.cos(bearing)
                        / (111_000d * Math.max(0.1, Math.cos(Math.toRadians(lat))))
        };
    }

    private double boundaryDistanceMeters(
            double latitude, double longitude, PrimaryFence fence) {
        double[] nearest = nearestBoundary(latitude, longitude, fence);
        return distanceMeters(latitude, longitude, nearest[0], nearest[1]);
    }

    private double[] nearestBoundary(
            double latitude, double longitude, PrimaryFence fence) {
        List<CoordinateInfo> vertices = fence.vertices();
        double bestLat = vertices.get(0).latitude();
        double bestLng = vertices.get(0).longitude();
        double bestDistance = Double.MAX_VALUE;
        for (int i = 0, j = vertices.size() - 1; i < vertices.size(); j = i++) {
            double aLat = vertices.get(i).latitude();
            double aLng = vertices.get(i).longitude();
            double bLat = vertices.get(j).latitude();
            double bLng = vertices.get(j).longitude();

            double aLatMeters = aLat * 111_000d;
            double aLngMeters = aLng * 111_000d * Math.cos(Math.toRadians(latitude));
            double bLatMeters = bLat * 111_000d;
            double bLngMeters = bLng * 111_000d * Math.cos(Math.toRadians(latitude));
            double pLatMeters = latitude * 111_000d;
            double pLngMeters = longitude * 111_000d * Math.cos(Math.toRadians(latitude));

            double dx = bLngMeters - aLngMeters;
            double dy = bLatMeters - aLatMeters;
            double lengthSquared = dx * dx + dy * dy;
            double t = lengthSquared == 0 ? 0
                    : ((pLngMeters - aLngMeters) * dx + (pLatMeters - aLatMeters) * dy)
                      / lengthSquared;
            t = Math.max(0, Math.min(1, t));
            double candidateLatMeters = aLatMeters + t * dy;
            double candidateLngMeters = aLngMeters + t * dx;
            double candidateLat = candidateLatMeters / 111_000d;
            double candidateLng = candidateLngMeters
                    / (111_000d * Math.cos(Math.toRadians(latitude)));
            double distance = distanceMeters(latitude, longitude, candidateLat, candidateLng);
            if (distance < bestDistance) {
                bestDistance = distance;
                bestLat = candidateLat;
                bestLng = candidateLng;
            }
        }
        return new double[]{
                bestLat, bestLng
        };
    }

    private double averageLatitude(List<CoordinateInfo> vertices) {
        return vertices.stream().mapToDouble(CoordinateInfo::latitude).average().orElse(0);
    }

    private double averageLongitude(List<CoordinateInfo> vertices) {
        return vertices.stream().mapToDouble(CoordinateInfo::longitude).average().orElse(0);
    }

    private Map<String, Object> generateCapsuleBaseline(
            SynthesisState state, Instant now, DatagenFarmRules rules) {
        Map<String, Object> readings = new HashMap<>();
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        int hour = now.atZone(ZoneId.of("Asia/Shanghai")).getHour();
        double hourFactor = (hour >= 6 && hour <= 20) ? 1.0 : 0.2;

        updateDemoHealthEvent(state, now, rules);
        List<BigDecimal> temperatures = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            Instant pointTime = now.minus(Duration.ofMinutes(5L * (6 - i)));
            double temp = baselineTemperature(state, pointTime)
                    + demoTemperatureDelta(state, pointTime);
            temperatures.add(BigDecimal.valueOf(round(temp, 2)));
        }
        readings.put("temperatures", temperatures);

        long motility = Math.round(state.motilityBaseline
                * baselineMotilityRatio(state, now)
                * demoMotilityRatio(state, now));
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

    private void updateDemoHealthEvent(
            SynthesisState state, Instant now, DatagenFarmRules rules) {
        if (state.demoHealthEvent != SynthesisState.DemoHealthEvent.NONE) {
            if (now.isBefore(state.demoHealthEventEnd)) return;
            state.demoHealthEvent = SynthesisState.DemoHealthEvent.NONE;
            state.demoHealthEventStart = null;
            state.demoHealthEventEnd = null;
        }

        ThreadLocalRandom rng = ThreadLocalRandom.current();
        if (rng.nextDouble() >= rules.healthEventProbability()) return;

        boolean fever = rng.nextBoolean();
        state.demoHealthEvent = fever
                ? SynthesisState.DemoHealthEvent.FEVER
                : SynthesisState.DemoHealthEvent.MOTILITY_DROP;
        state.demoHealthEventStart = now;
        state.demoHealthEventEnd = now.plus(Duration.ofMinutes(fever
                ? randomMinutes(rules.feverDurationMinMinutes(), rules.feverDurationMaxMinutes())
                : randomMinutes(rules.motilityDurationMinMinutes(), rules.motilityDurationMaxMinutes())));
    }

    private int randomMinutes(int minInclusive, int maxInclusive) {
        return ThreadLocalRandom.current().nextInt(minInclusive, maxInclusive + 1);
    }

    private double demoTemperatureDelta(SynthesisState state, Instant pointTime) {
        if (state.demoHealthEvent != SynthesisState.DemoHealthEvent.FEVER) return 0;
        if (pointTime.isBefore(state.demoHealthEventStart)
                || !pointTime.isBefore(state.demoHealthEventEnd)) return 0;
        return eventIntensity(state.demoHealthEventProgress(pointTime)) * 1.8;
    }

    private double baselineTemperature(SynthesisState state, Instant pointTime) {
        long seconds = Duration.between(Instant.EPOCH, pointTime).getSeconds();
        double phase = (state.livestockId % 17) / 17.0;
        double daily = Math.sin(2 * Math.PI * (seconds / 86400.0 + phase));
        double slow = Math.sin(2 * Math.PI * (seconds / 21600.0 + phase * 1.7));
        return 38.5 + state.tempBaselineOffset + 0.055 * daily + 0.025 * slow;
    }

    private double baselineMotilityRatio(SynthesisState state, Instant pointTime) {
        long seconds = Duration.between(Instant.EPOCH, pointTime).getSeconds();
        double phase = (state.livestockId % 13) / 13.0;
        double slow = Math.sin(2 * Math.PI * (seconds / 21600.0 + phase));
        double feeding = Math.sin(2 * Math.PI * (seconds / 14400.0 + phase * 0.7));
        return 1.0 + 0.035 * slow + 0.015 * feeding;
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

    private Instant stableSampleTime(Instant value, int intervalSeconds) {
        long epochSecond = value.getEpochSecond() / intervalSeconds * intervalSeconds;
        return Instant.ofEpochSecond(epochSecond).truncatedTo(ChronoUnit.SECONDS);
    }

    private static double round(double value, int places) {
        double scale = Math.pow(10, places);
        return Math.round(value * scale) / scale;
    }
}
