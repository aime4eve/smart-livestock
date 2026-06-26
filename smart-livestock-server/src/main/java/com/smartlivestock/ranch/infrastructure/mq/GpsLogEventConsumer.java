package com.smartlivestock.ranch.infrastructure.mq;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.*;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.dto.InstallationInfo;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.domain.service.FenceBreachDetector;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/**
 * RocketMQ consumer: listens on "gps-log-updated" topic.
 * Performs fence breach detection, buffer zone approach detection, and auto-resolve.
 *
 * Logic:
 * - Livestock outside all fences + in buffer zone → FENCE_APPROACH (WARNING)
 * - Livestock outside all fences + outside buffer → FENCE_BREACH (CRITICAL)
 * - Livestock returned inside fence → auto-resolve existing FENCE_BREACH/FENCE_APPROACH
 */
@Slf4j
@Component
@RocketMQMessageListener(
        topic = "gps-log-updated",
        consumerGroup = "ranch-gps-consumer"
)
@RequiredArgsConstructor
public class GpsLogEventConsumer implements RocketMQListener<String> {

    private final ObjectMapper objectMapper;
    private final IoTQueryPort ioTQueryPort;
    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;
    private final AlertRepository alertRepository;
    private final FenceBreachDetector fenceBreachDetector;

    @Override
    @Transactional
    public void onMessage(String message) {
        try {
            JsonNode root = objectMapper.readTree(message);

            Long deviceId = root.path("deviceId").asLong();
            BigDecimal latitude = new BigDecimal(root.path("latitude").asText());
            BigDecimal longitude = new BigDecimal(root.path("longitude").asText());

            log.debug("Processing GPS log for device [{}]", deviceId);

            InstallationInfo installation = ioTQueryPort.findActiveInstallation(deviceId).orElse(null);
            if (installation == null) {
                log.debug("No active installation for device [{}] - skipping", deviceId);
                return;
            }

            Long livestockId = installation.livestockId();
            Livestock livestock = livestockRepository.findById(livestockId).orElse(null);
            if (livestock == null) {
                log.warn("Livestock [{}] not found - skipping", livestockId);
                return;
            }

            Long farmId = livestock.getFarmId();
            List<Fence> fences = fenceRepository.findByFarmId(farmId);
            if (fences.isEmpty()) return;

            GpsCoordinate position = new GpsCoordinate(latitude, longitude);

            // Update livestock position
            livestock.updatePosition(latitude, longitude);
            livestockRepository.save(livestock);

            // Detect fence status
            // If point is inside at least one active fence → safe (no alerts)
            boolean insideAnyFence = fences.stream()
                    .filter(Fence::isActive)
                    .anyMatch(fence -> fence.contains(position));
            if (insideAnyFence) {
                autoResolveFenceAlerts(livestockId, farmId);
                return;
            }

            // Point is outside ALL active fences → detect breach or approach
            List<Fence> breachedFences = fenceBreachDetector.findBreachedFences(fences, position);
            List<Fence> approachingFences = fenceBreachDetector.findApproachingFences(fences, position);

            if (!breachedFences.isEmpty()) {
                // Livestock is outside fence boundary
                // Check if it's in buffer zone (approaching) or fully outside (breach)
                for (Fence fence : breachedFences) {
                    boolean inBuffer = fenceBreachDetector.isApproaching(fence, position);
                    if (inBuffer) {
                        // In buffer zone but outside fence → FENCE_APPROACH
                        createAlertIfNeeded(livestock, fence, AlertType.FENCE_APPROACH, Severity.WARNING, position);
                    } else {
                        // Fully outside fence and buffer → FENCE_BREACH
                        createAlertIfNeeded(livestock, fence, AlertType.FENCE_BREACH, Severity.CRITICAL, position);
                    }
                }
                // Auto-resolve any opposite type alerts for same fence
                // (e.g. if now breaching, resolve old approach alert)
                autoResolveOppositeTypeAlerts(livestockId, breachedFences);
            } else {
                // Only approaching (in buffer zone but still "outside" fence in the contains check)
                // This case shouldn't normally happen since approaching = inBuffer && !inFence,
                // which means isBreaching would also be true. But handle it defensively.
                for (Fence fence : approachingFences) {
                    createAlertIfNeeded(livestock, fence, AlertType.FENCE_APPROACH, Severity.WARNING, position);
                }
            }

        } catch (Exception e) {
            log.error("Failed to process GPS log message: {}", e.getMessage(), e);
            throw new RuntimeException(e);
        }
    }

    /**
     * Auto-resolve all active fence alerts (FENCE_BREACH + FENCE_APPROACH) for a livestock.
     */
    private void autoResolveFenceAlerts(Long livestockId, Long farmId) {
        List<Alert> breachAlerts = alertRepository.findByLivestockIdAndTypeAndStatus(
                livestockId, AlertType.FENCE_BREACH, AlertStatus.ACTIVE);
        List<Alert> approachAlerts = alertRepository.findByLivestockIdAndTypeAndStatus(
                livestockId, AlertType.FENCE_APPROACH, AlertStatus.ACTIVE);

        for (Alert alert : breachAlerts) {
            alert.autoResolve();
            alertRepository.save(alert);
            log.info("Auto-resolved FENCE_BREACH alert [{}] for livestock [{}] - returned to safe zone",
                    alert.getId(), livestockId);
        }
        for (Alert alert : approachAlerts) {
            alert.autoResolve();
            alertRepository.save(alert);
            log.info("Auto-resolved FENCE_APPROACH alert [{}] for livestock [{}] - returned to safe zone",
                    alert.getId(), livestockId);
        }
    }

    /**
     * Create fence alert if there isn't already an active one for this livestock+fence+type.
     */
    private void createAlertIfNeeded(Livestock livestock, Fence fence, AlertType type,
                                      Severity severity, GpsCoordinate position) {
        // Check for existing active alert of same type for this livestock
        List<Alert> existing = alertRepository.findByLivestockIdAndTypeAndStatus(
                livestock.getId(), type, AlertStatus.ACTIVE);
        // Only create if no existing alert for this specific fence
        boolean hasExistingForFence = existing.stream()
                .anyMatch(a -> fence.getId().equals(a.getFenceId()));
        if (hasExistingForFence) return;

        String typeLabel = type == AlertType.FENCE_BREACH ? "越出" : "接近";
        String msg = String.format("牲畜 [%s] %s围栏 [%s]，位置: (%s, %s)",
                livestock.getLivestockCode(), typeLabel, fence.getName(),
                position.latitude(), position.longitude());
        Alert alert = new Alert(livestock.getFarmId(), livestock.getId(), fence.getId(),
                type, severity, msg);
        alertRepository.save(alert);
        log.info("Created {} alert for livestock [{}] fence [{}]", type, livestock.getId(), fence.getId());
    }

    /**
     * When livestock transitions to FENCE_BREACH, auto-resolve any FENCE_APPROACH for same fence.
     * Vice versa is not needed since approach is a softer state.
     */
    private void autoResolveOppositeTypeAlerts(Long livestockId, List<Fence> fences) {
        // If livestock is now fully breaching, resolve any approach alerts for same fences
        List<Alert> approachAlerts = alertRepository.findByLivestockIdAndTypeAndStatus(
                livestockId, AlertType.FENCE_APPROACH, AlertStatus.ACTIVE);
        for (Alert alert : approachAlerts) {
            if (fences.stream().anyMatch(f -> f.getId().equals(alert.getFenceId()))) {
                alert.autoResolve();
                alertRepository.save(alert);
                log.info("Auto-resolved FENCE_APPROACH [{}] - escalated to FENCE_BREACH", alert.getId());
            }
        }
    }
}
