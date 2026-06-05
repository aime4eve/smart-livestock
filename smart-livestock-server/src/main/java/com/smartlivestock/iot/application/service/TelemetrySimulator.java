package com.smartlivestock.iot.application.service;

import com.smartlivestock.iot.application.TelemetryIngestionService;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.ZoneId;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Stateful telemetry simulator with per-livestock simulation state.
 * Generates realistic time-series data following circadian rhythm patterns.
 * Uses ACL ports (RanchQueryPort) instead of direct cross-context repository access.
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "telemetry.simulator.enabled", havingValue = "true")
public class TelemetrySimulator {

    private final InstallationRepository installationRepository;
    private final DeviceRepository deviceRepository;
    private final RanchQueryPort ranchQueryPort;
    private final TelemetryIngestionService telemetryIngestionService;

    private final ConcurrentHashMap<Long, SimulationState> states = new ConcurrentHashMap<>();

    public TelemetrySimulator(InstallationRepository installationRepository,
                               DeviceRepository deviceRepository,
                               RanchQueryPort ranchQueryPort,
                               TelemetryIngestionService telemetryIngestionService) {
        this.installationRepository = installationRepository;
        this.deviceRepository = deviceRepository;
        this.ranchQueryPort = ranchQueryPort;
        this.telemetryIngestionService = telemetryIngestionService;
    }

    @Scheduled(fixedRateString = "${telemetry.simulator.interval-ms:30000}")
    @Transactional
    public void generateTelemetry() {
        List<Installation> activeInstallations = installationRepository.findAllActive();

        if (activeInstallations.isEmpty()) {
            log.debug("No active installations found - skipping telemetry simulation");
            return;
        }

        log.debug("Generating telemetry for {} active installations", activeInstallations.size());

        Instant now = Instant.now();
        int generated = 0;

        for (Installation installation : activeInstallations) {
            Long deviceId = installation.getDeviceId();
            Long livestockId = installation.getLivestockId();

            Device device = deviceRepository.findById(deviceId).orElse(null);
            if (device == null || device.getStatus() != DeviceStatus.ACTIVE) {
                continue;
            }

            SimulationState state = states.computeIfAbsent(livestockId, id -> SimulationState.create(device.getDeviceType(), id));

            Map<String, Object> readings = generateReadings(device.getDeviceType(), state, now);

            try {
                telemetryIngestionService.ingest(deviceId, readings, now);
                generated++;
            } catch (Exception e) {
                log.warn("Failed to ingest telemetry for device [{}]: {}", deviceId, e.getMessage());
            }
        }

        log.debug("Telemetry simulation complete - generated {} readings", generated);
    }

    private Map<String, Object> generateReadings(DeviceType deviceType, SimulationState state, Instant now) {
        Map<String, Object> readings = new HashMap<>();
        ThreadLocalRandom rng = ThreadLocalRandom.current();
        double hourFactor = hourFactor(now);
        int hour = now.atZone(ZoneId.of("Asia/Shanghai")).getHour();

        switch (deviceType) {
            case TRACKER -> generateTrackerReadings(readings, state, rng, hourFactor, hour);
            case CAPSULE -> generateCapsuleReadings(readings, state, rng, hourFactor);
            default -> log.debug("Unsupported device type for telemetry: {}", deviceType);
        }

        return readings;
    }

    private void generateTrackerReadings(Map<String, Object> readings, SimulationState state,
                                          ThreadLocalRandom rng, double hourFactor, int hour) {
        // Step count: circadian rhythm + estrus boost
        int baseSteps;
        if (hour >= 6 && hour <= 20) {
            baseSteps = rng.nextInt(800, 2501);
        } else {
            baseSteps = rng.nextInt(50, 301);
        }
        if (state.inEstrus) {
            baseSteps = (int) (baseSteps * 2.5);
        }
        readings.put("stepCount", Math.min(baseSteps, 65535)); // u16 max

        // Distance from steps
        double distance = baseSteps * rng.nextDouble(0.3, 0.6);
        readings.put("distanceMeters", round(distance, 1));

        // Accelerometer (s16 range)
        readings.put("accelX", rng.nextInt(-2000, 2001));
        readings.put("accelY", rng.nextInt(-2000, 2001));
        readings.put("accelZ", rng.nextInt(-2000, 2001));

        // GPS: placeholder — actual fence-aware GPS requires FenceInfo from RanchQueryPort
        // For now, generate a point near the farm center (fence-aware logic in future iteration)
        readings.put("latitude", 28.229 + rng.nextDouble(-0.005, 0.005));
        readings.put("longitude", 112.938 + rng.nextDouble(-0.005, 0.005));

        // Battery: slow decay
        state.batteryLevel = Math.max(0, state.batteryLevel - rng.nextInt(0, 2));
        readings.put("batteryLevel", state.batteryLevel);

        // Activity index from steps
        readings.put("activityIndex", round(hourFactor * rng.nextDouble(30, 80), 1));
    }

    private void generateCapsuleReadings(Map<String, Object> readings, SimulationState state,
                                          ThreadLocalRandom rng, double hourFactor) {
        // 7 temperature points
        List<BigDecimal> temperatures = new ArrayList<>();
        double baseTemp = 38.5 + state.tempBaselineOffset.doubleValue();
        if (state.abnormalTemp) {
            baseTemp += rng.nextDouble(0.8, 2.0);
        }
        for (int i = 0; i < 7; i++) {
            double temp = baseTemp + rng.nextDouble(-0.15, 0.15);
            temperatures.add(BigDecimal.valueOf(round(temp, 2)));
        }
        readings.put("temperatures", temperatures);

        // Gastric motility (u32 raw value)
        long motility = state.motilityBaseline.longValue();
        if (state.abnormalMotility) {
            motility = (long) (motility * 0.2);
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
    }

    private double hourFactor(Instant now) {
        int hour = now.atZone(ZoneId.of("Asia/Shanghai")).getHour();
        return (hour >= 6 && hour <= 20) ? 1.0 : 0.2;
    }

    private static double round(double value, int places) {
        double scale = Math.pow(10, places);
        return Math.round(value * scale) / scale;
    }

    /**
     * Per-livestock simulation state for consistent baseline and anomaly flags.
     */
    static class SimulationState {
        BigDecimal tempBaselineOffset;     // +/-0.3C individual offset
        BigDecimal motilityBaseline;       // 2.5-3.5 * 100000
        boolean abnormalTemp;              // 5% probability
        boolean abnormalMotility;          // 3% probability
        boolean inEstrus;                  // 5% for females
        int batteryLevel;                  // 0-100, slow decay
        int batteryVoltage;                // 2800-3600 mV

        private SimulationState() {}

        static SimulationState create(DeviceType deviceType, Long livestockId) {
            ThreadLocalRandom rng = ThreadLocalRandom.current();
            SimulationState state = new SimulationState();
            state.tempBaselineOffset = BigDecimal.valueOf(rng.nextDouble(-0.3, 0.3));
            state.motilityBaseline = BigDecimal.valueOf(rng.nextDouble(2.5, 3.5) * 100000);
            state.abnormalTemp = rng.nextDouble() < 0.05;
            state.abnormalMotility = rng.nextDouble() < 0.03;
            state.inEstrus = rng.nextDouble() < 0.05; // simplified: no gender check
            state.batteryLevel = rng.nextInt(70, 101);
            state.batteryVoltage = rng.nextInt(3200, 3601);
            return state;
        }
    }
}
