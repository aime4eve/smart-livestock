package com.smartlivestock.health.infrastructure.mq;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.health.application.service.HealthApplicationService;
import com.smartlivestock.iot.domain.model.DeviceType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * RocketMQ consumer: listens on "telemetry-received" topic, deserializes
 * TelemetryReceivedEvent JSON, and delegates to HealthApplicationService.
 */
@Slf4j
@Component
@RocketMQMessageListener(
        topic = "telemetry-received",
        consumerGroup = "health-telemetry-consumer"
)
@RequiredArgsConstructor
public class TelemetryEventConsumer implements RocketMQListener<String> {

    private final ObjectMapper objectMapper;
    private final HealthApplicationService healthApplicationService;

    @Override
    public void onMessage(String message) {
        try {
            JsonNode root = objectMapper.readTree(message);

            Long deviceId = root.path("deviceId").asLong();
            Long livestockId = root.path("livestockId").asLong();
            Long farmId = root.path("farmId").asLong();
            String deviceTypeStr = root.path("deviceType").asText("CAPSULE");
            DeviceType deviceType = DeviceType.valueOf(deviceTypeStr);

            @SuppressWarnings("unchecked")
            Map<String, Object> readings = objectMapper.convertValue(
                    root.path("readings"), Map.class);

            String recordedAtStr = root.path("recordedAt").asText(null);
            java.time.Instant recordedAt = recordedAtStr != null
                    ? java.time.Instant.parse(recordedAtStr) : java.time.Instant.now();

            healthApplicationService.processTelemetry(
                    deviceId, livestockId, farmId, deviceType, readings, recordedAt);

        } catch (Exception e) {
            log.error("Failed to process telemetry message: {}", e.getMessage(), e);
            throw new RuntimeException(e);
        }
    }
}
