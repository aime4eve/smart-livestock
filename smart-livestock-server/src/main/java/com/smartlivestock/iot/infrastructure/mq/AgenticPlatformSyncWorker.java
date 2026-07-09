package com.smartlivestock.iot.infrastructure.mq;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.iot.application.AgenticPlatformTelemetrySyncJob;
import com.smartlivestock.iot.application.DeviceTelemetrySyncTask;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.ConsumeMode;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * RocketMQ consumer: receives device sync tasks and delegates to AgenticPlatformTelemetrySyncJob.
 * Multiple instances + consumeThreadMax = 20 for horizontal scalability.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "agentic-platform.sync.enabled", havingValue = "true")
@RocketMQMessageListener(
        topic = "device-telemetry-sync",
        consumerGroup = "platform-sync-worker",
        consumeThreadMax = 20,
        consumeMode = ConsumeMode.CONCURRENTLY
)
public class AgenticPlatformSyncWorker implements RocketMQListener<String> {

    private final ObjectMapper objectMapper;
    private final AgenticPlatformTelemetrySyncJob syncJob;

    @Override
    public void onMessage(String message) {
        try {
            DeviceTelemetrySyncTask task = objectMapper.readValue(message, DeviceTelemetrySyncTask.class);
            syncJob.syncDevice(task.deviceId());
        } catch (Exception e) {
            log.error("[PlatformSync] sync task failed: {}", e.getMessage());
            throw new RuntimeException(e);
        }
    }
}
