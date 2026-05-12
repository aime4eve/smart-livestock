package com.smartlivestock.ranch.infrastructure.event;

import com.smartlivestock.iot.domain.event.GpsLogUpdatedEvent;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.domain.service.FenceBreachDetector;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Cross-context event handler: GPS → Fence breach → Alert.
 * <p>
 * Listens for {@link GpsLogUpdatedEvent} from the IoT context, determines if the GPS
 * position breaches any active fence, and creates an Alert in the Ranch context.
 * <p>
 * Cross-context references are resolved at the application layer through each context's
 * own Repository — no FK constraints cross bounded-context boundaries.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class GpsLogEventHandler {

    private final InstallationRepository installationRepository;
    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;
    private final AlertRepository alertRepository;
    private final FenceBreachDetector fenceBreachDetector;

    /**
     * Handle a GPS log update event:
     * <ol>
     *   <li>Find the active installation for the device (device → livestock binding)</li>
     *   <li>Look up the livestock to determine its farm</li>
     *   <li>Find all fences for that farm</li>
     *   <li>Check if the GPS position is outside any fence</li>
     *   <li>If breached, create an Alert and publish FenceBreachDetectedEvent</li>
     * </ol>
     */
    @EventListener
    @Transactional
    public void onGpsLogUpdated(GpsLogUpdatedEvent event) {
        log.debug("Processing GpsLogUpdatedEvent for device [{}]", event.getDeviceId());

        // Step 1: Find active installation (IoT context query)
        Installation installation = installationRepository
                .findActiveByDeviceId(event.getDeviceId())
                .orElse(null);

        if (installation == null) {
            log.debug("No active installation found for device [{}] — skipping breach check",
                    event.getDeviceId());
            return;
        }

        Long livestockId = installation.getLivestockId();

        // Step 2: Find livestock to determine farm (Ranch context query)
        Livestock livestock = livestockRepository.findById(livestockId).orElse(null);
        if (livestock == null) {
            log.warn("Livestock [{}] from installation not found — skipping breach check", livestockId);
            return;
        }

        Long farmId = livestock.getFarmId();

        // Step 3: Find all fences for the farm
        List<Fence> fences = fenceRepository.findByFarmId(farmId);
        if (fences.isEmpty()) {
            return;
        }

        // Step 4: Build GPS coordinate and check for breaches
        GpsCoordinate position = new GpsCoordinate(event.getLatitude(), event.getLongitude());
        List<Fence> breachedFences = fenceBreachDetector.findBreachedFences(fences, position);

        if (breachedFences.isEmpty()) {
            return;
        }

        // Step 5: Update livestock position and create alerts for each breached fence
        livestock.updatePosition(event.getLatitude(), event.getLongitude());
        livestockRepository.save(livestock);

        for (Fence breached : breachedFences) {
            String message = String.format(
                    "牲畜 [%s] 越出围栏 [%s]，位置: (%s, %s)",
                    livestock.getLivestockCode(),
                    breached.getName(),
                    event.getLatitude(),
                    event.getLongitude());

            Alert alert = new Alert(
                    farmId,
                    livestockId,
                    breached.getId(),
                    AlertType.FENCE_BREACH,
                    Severity.WARNING,
                    message);

            alertRepository.save(alert);
            log.info("Created FENCE_BREACH alert for livestock [{}] fence [{}] at ({}, {})",
                    livestockId, breached.getId(), event.getLatitude(), event.getLongitude());
        }
    }
}
