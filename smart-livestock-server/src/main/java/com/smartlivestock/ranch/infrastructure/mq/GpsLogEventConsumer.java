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
 * RocketMQ consumer: listens on "gps-log-updated" topic, performs fence breach detection.
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

            // Find active installation via ACL port
            InstallationInfo installation = ioTQueryPort.findActiveInstallation(deviceId).orElse(null);
            if (installation == null) {
                log.debug("No active installation for device [{}] - skipping breach check", deviceId);
                return;
            }

            Long livestockId = installation.livestockId();

            Livestock livestock = livestockRepository.findById(livestockId).orElse(null);
            if (livestock == null) {
                log.warn("Livestock [{}] not found - skipping breach check", livestockId);
                return;
            }

            Long farmId = livestock.getFarmId();
            List<Fence> fences = fenceRepository.findByFarmId(farmId);
            if (fences.isEmpty()) return;

            GpsCoordinate position = new GpsCoordinate(latitude, longitude);
            List<Fence> breachedFences = fenceBreachDetector.findBreachedFences(fences, position);
            if (breachedFences.isEmpty()) return;

            livestock.updatePosition(latitude, longitude);
            livestockRepository.save(livestock);

            for (Fence breached : breachedFences) {
                String msg = String.format("牲畜 [%s] 越出围栏 [%s]，位置: (%s, %s)",
                        livestock.getLivestockCode(), breached.getName(), latitude, longitude);
                Alert alert = new Alert(farmId, livestockId, breached.getId(),
                        AlertType.FENCE_BREACH, Severity.WARNING, msg);
                alertRepository.save(alert);
                log.info("Created FENCE_BREACH alert for livestock [{}] fence [{}]", livestockId, breached.getId());
            }
        } catch (Exception e) {
            log.error("Failed to process GPS log message: {}", e.getMessage(), e);
            throw new RuntimeException(e);
        }
    }
}
