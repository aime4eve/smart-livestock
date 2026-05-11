package com.smartlivestock.iot.application.service;

import com.smartlivestock.iot.application.GpsLogApplicationService;
import com.smartlivestock.iot.application.dto.GpsLogDto;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/**
 * GPS simulator that generates mock GPS coordinates for all active installations.
 * <p>
 * Generates random GPS positions around configurable center coordinates,
 * simulating device movement within a farm area. Only active when
 * {@code gps.simulator.enabled=true} in application configuration.
 * <p>
 * Used during Phase 1 development before real IoT device data is available.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "gps.simulator.enabled", havingValue = "true")
public class GpsSimulator {

    private final InstallationRepository installationRepository;
    private final GpsLogApplicationService gpsLogService;

    @Value("${gps.simulator.center-lat:28.2458}")
    private BigDecimal centerLat;

    @Value("${gps.simulator.center-lng:112.8519}")
    private BigDecimal centerLng;

    @Value("${gps.simulator.offset:0.005}")
    private BigDecimal offset;

    /**
     * Generate simulated GPS data for all active installations periodically.
     * <p>
     * For each active installation, generates a random GPS coordinate
     * within the configured offset range around the center point and
     * logs it via {@link GpsLogApplicationService#logGps}.
     */
    @Scheduled(fixedRateString = "${gps.simulator.interval-ms:30000}")
    @Transactional
    public void generateGpsData() {
        List<Installation> activeInstallations = installationRepository.findAllActive();

        if (activeInstallations.isEmpty()) {
            log.debug("No active installations found — skipping GPS simulation");
            return;
        }

        log.debug("Generating GPS data for {} active installations", activeInstallations.size());

        Instant now = Instant.now();
        int generated = 0;

        for (Installation installation : activeInstallations) {
            BigDecimal latitude = randomCoordinate(centerLat, offset);
            BigDecimal longitude = randomCoordinate(centerLng, offset);
            BigDecimal accuracy = randomAccuracy();

            GpsLogDto gpsLog = gpsLogService.logGps(
                    installation.getDeviceId(),
                    latitude,
                    longitude,
                    accuracy,
                    now
            );

            generated++;
            log.trace("Generated GPS for device [{}]: ({}, {})",
                    gpsLog.deviceId(), gpsLog.latitude(), gpsLog.longitude());
        }

        log.debug("GPS simulation complete — generated {} points", generated);
    }

    /**
     * Generate a random coordinate around the center with the given offset.
     *
     * @param center the center coordinate value
     * @param maxOffset the maximum offset in degrees
     * @return a random coordinate within [center - maxOffset, center + maxOffset]
     */
    private BigDecimal randomCoordinate(BigDecimal center, BigDecimal maxOffset) {
        double randomOffset = ThreadLocalRandom.current().nextDouble(-1.0, 1.0) * maxOffset.doubleValue();
        return center.add(BigDecimal.valueOf(randomOffset)).setScale(7, RoundingMode.HALF_UP);
    }

    /**
     * Generate a random accuracy value between 1 and 20 meters.
     *
     * @return accuracy in meters
     */
    private BigDecimal randomAccuracy() {
        double accuracy = ThreadLocalRandom.current().nextDouble(1.0, 20.0);
        return BigDecimal.valueOf(accuracy).setScale(2, RoundingMode.HALF_UP);
    }
}
