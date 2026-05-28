package com.smartlivestock.shared.messaging;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.core.RocketMQTemplate;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

/**
 * Publishes domain events to RocketMQ topics for cross-context distribution.
 * <p>
 * Gracefully handles RocketMQ unavailability: if no {@link RocketMQTemplate} bean is
 * present (e.g. RocketMQ broker not running, or auto-configuration excluded), publish
 * calls are silently skipped. This allows the application to start and run tests without
 * a running RocketMQ broker.
 */
@Slf4j
@Component
public class RocketMQEventPublisher {

    private final RocketMQTemplate rocketMQTemplate;
    private final ObjectMapper objectMapper;

    public RocketMQEventPublisher(
            ObjectProvider<RocketMQTemplate> rocketMQTemplateProvider,
            ObjectMapper objectMapper) {
        this.rocketMQTemplate = rocketMQTemplateProvider.getIfAvailable();
        this.objectMapper = objectMapper;
        if (this.rocketMQTemplate == null) {
            log.info("RocketMQTemplate not available — event publishing is disabled");
        }
    }

    /**
     * Publish an event payload to the specified RocketMQ topic.
     * If RocketMQ is not available, the call is silently skipped.
     *
     * @param topic the target topic (use constants from {@link Topics})
     * @param event the event payload to send
     */
    public void publish(String topic, Object event) {
        if (rocketMQTemplate == null) {
            log.debug("RocketMQTemplate not available — skipping publish to topic [{}]", topic);
            return;
        }
        try {
            String json = objectMapper.writeValueAsString(event);
            rocketMQTemplate.convertAndSend(topic, json);
            log.debug("Published event to topic [{}]: {}", topic, json);
        } catch (Exception ex) {
            log.warn("Failed to publish event to topic [{}]: {}", topic, ex.getMessage());
            // Graceful degradation: do not crash the application if RocketMQ is temporarily down.
            // In a production system, consider a fallback to an outbox table or retry queue.
        }
    }
}
