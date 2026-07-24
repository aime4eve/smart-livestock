package com.smartlivestock.iot.infrastructure.mq;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.iot.application.AgenticPlatformTelemetrySyncJob;
import com.smartlivestock.iot.application.DeviceTelemetrySyncTask;
import feign.codec.DecodeException;
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
 * <p>
 * Feign DecodeException (token expired) is caught and logged without re-throwing,
 * so RocketMQ does not endlessly retry a poisoned message. The sync job itself
 * already retries once with a fresh token; if that also fails, we give up
 * gracefully and wait for the next scheduled sync cycle.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "agentic-platform.sync.use-rocketmq", havingValue = "true")
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
        } catch (DecodeException e) {
            // Token expired and retry also failed — log and move on.
            // RocketMQ will not retry, next scheduled sync will succeed with fresh token.
            log.warn("[PlatformSync] token expired after retry (both attempts failed): {}", e.getMessage());
        } catch (Exception e) {
            log.error("[PlatformSync] sync task failed: {}", e.getMessage(), e);
            throw new RuntimeException(e);
        }
    }
}
