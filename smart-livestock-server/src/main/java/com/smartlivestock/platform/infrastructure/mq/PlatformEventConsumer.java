package com.smartlivestock.platform.infrastructure.mq;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.platform.messaging.NotificationService;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.stereotype.Component;

/**
 * Platform notification consumer for IoT events.
 * Replaces @TransactionalEventListener in NotificationEventListener.
 */
@Slf4j
@Component
@RocketMQMessageListener(
        topic = "device-activated",
        consumerGroup = "platform-notification-consumer"
)
public class PlatformEventConsumer implements RocketMQListener<String> {

    private final ObjectMapper objectMapper;
    private final NotificationService notificationService;

    public PlatformEventConsumer(ObjectMapper objectMapper, NotificationService notificationService) {
        this.objectMapper = objectMapper;
        this.notificationService = notificationService;
    }

    @Override
    public void onMessage(String message) {
        try {
            JsonNode root = objectMapper.readTree(message);
            Long deviceId = root.path("deviceId").asLong();
            log.debug("Platform received device-activated for device [{}]", deviceId);
            // Device events lack tenantId — notification deferred to context layer
        } catch (Exception e) {
            log.error("Failed to process platform event: {}", e.getMessage(), e);
        }
    }
}
