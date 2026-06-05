package com.smartlivestock.iot.application.service;

import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.iot.application.GpsLogApplicationService;
import com.smartlivestock.iot.application.dto.GpsLogDto;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
 * For each installation, resolves the livestock → farm → fences chain:
 * <ul>
 *   <li>Has fences: generates a random point inside a fence polygon</li>
 *   <li>No fences: generates a random point around the farm's own center coordinates</li>
 * </ul>
 * Only active when {@code gps.simulator.enabled=true}.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "gps.simulator.enabled", havingValue = "true")
public class GpsSimulator {

    private static final BigDecimal DEFAULT_OFFSET = new BigDecimal("0.003");

    private final InstallationRepository installationRepository;
    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;
    private final FarmRepository farmRepository;
    private final GpsLogApplicationService gpsLogService;

    /**
     * Generate simulated GPS data for all active installations periodically.
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
            GpsCoordinate point = generatePointForInstallation(installation);

            if (point == null) {
                log.trace("Could not resolve GPS position for device [{}] — skipping",
                        installation.getDeviceId());
                continue;
            }

            BigDecimal accuracy = randomAccuracy();

            GpsLogDto gpsLog = gpsLogService.logGps(
                    installation.getDeviceId(),
                    point.latitude(),
                    point.longitude(),
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
     * Resolve GPS point for an installation:
     * 1. installation → livestock → farm
     * 2. farm has fences → random point inside a fence polygon
     * 3. farm has no fences → random point around farm's own center coordinates
     */
    private GpsCoordinate generatePointForInstallation(Installation installation) {
        Long livestockId = installation.getLivestockId();
        if (livestockId == null) {
            return null;
        }

        Livestock livestock = livestockRepository.findById(livestockId).orElse(null);
        if (livestock == null) {
            return null;
        }

        Long farmId = livestock.getFarmId();
        Farm farm = farmRepository.findById(farmId).orElse(null);
        if (farm == null) {
            return null;
        }

        // Try fence-aware generation first
        List<Fence> fences = fenceRepository.findByFarmId(farmId);
        List<Fence> activeFences = fences.stream().filter(Fence::isActive).toList();

        if (!activeFences.isEmpty()) {
            Fence fence = activeFences.get(ThreadLocalRandom.current().nextInt(activeFences.size()));
            GpsCoordinate point = randomPointInPolygon(fence);
            if (point != null) {
                return point;
            }
        }

        // Fallback: farm center + small offset
        BigDecimal farmLat = farm.getLatitude();
        BigDecimal farmLng = farm.getLongitude();
        if (farmLat == null || farmLng == null) {
            return null;
        }

        return new GpsCoordinate(
                randomCoordinate(farmLat, DEFAULT_OFFSET),
                randomCoordinate(farmLng, DEFAULT_OFFSET)
        );
    }

    /**
     * Generate a random point inside the fence polygon using bounding-box rejection sampling.
     */
    private GpsCoordinate randomPointInPolygon(Fence fence) {
        List<GpsCoordinate> vertices = fence.getVertices();
        if (vertices == null || vertices.size() < 3) {
            return null;
        }

        BigDecimal minLat = vertices.stream().map(GpsCoordinate::latitude).min(BigDecimal::compareTo).orElse(null);
        BigDecimal maxLat = vertices.stream().map(GpsCoordinate::latitude).max(BigDecimal::compareTo).orElse(null);
        BigDecimal minLng = vertices.stream().map(GpsCoordinate::longitude).min(BigDecimal::compareTo).orElse(null);
        BigDecimal maxLng = vertices.stream().map(GpsCoordinate::longitude).max(BigDecimal::compareTo).orElse(null);

        if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
            return null;
        }

        ThreadLocalRandom rng = ThreadLocalRandom.current();

        for (int attempt = 0; attempt < 100; attempt++) {
            BigDecimal lat = minLat.add(BigDecimal.valueOf(rng.nextDouble()).multiply(maxLat.subtract(minLat)))
                    .setScale(7, RoundingMode.HALF_UP);
            BigDecimal lng = minLng.add(BigDecimal.valueOf(rng.nextDouble()).multiply(maxLng.subtract(minLng)))
                    .setScale(7, RoundingMode.HALF_UP);

            GpsCoordinate candidate = new GpsCoordinate(lat, lng);
            if (fence.contains(candidate)) {
                return candidate;
            }
        }

        // Fallback: fence centroid
        BigDecimal avgLat = minLat.add(maxLat).divide(BigDecimal.valueOf(2), 7, RoundingMode.HALF_UP);
        BigDecimal avgLng = minLng.add(maxLng).divide(BigDecimal.valueOf(2), 7, RoundingMode.HALF_UP);
        return new GpsCoordinate(avgLat, avgLng);
    }

    private BigDecimal randomCoordinate(BigDecimal center, BigDecimal maxOffset) {
        double randomOffset = ThreadLocalRandom.current().nextDouble(-1.0, 1.0) * maxOffset.doubleValue();
        return center.add(BigDecimal.valueOf(randomOffset)).setScale(7, RoundingMode.HALF_UP);
    }

    private BigDecimal randomAccuracy() {
        double accuracy = ThreadLocalRandom.current().nextDouble(1.0, 20.0);
        return BigDecimal.valueOf(accuracy).setScale(2, RoundingMode.HALF_UP);
    }
}
