package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.shared.messaging.RocketMQEventPublisher;
import com.smartlivestock.shared.messaging.Topics;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;

/**
 * Scheduled dispatcher: scans ACTIVE devices with platform_device_id,
 * sends sync tasks to RocketMQ topic for workers to consume.
 */
@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "agentic-platform.sync.enabled", havingValue = "true")
public class AgenticPlatformSyncDispatcher {

    private final DeviceRepository deviceRepository;
    private final RocketMQEventPublisher eventPublisher;

    @Value("${agentic-platform.sync.batch-size:1000}")
    private int batchSize;

    @Scheduled(fixedDelayString = "${agentic-platform.sync.dispatch-interval-ms:300000}")
    public void dispatch() {
        int offset = 0;
        int total = 0;

        while (true) {
            List<Long> deviceIds = deviceRepository.findActivePlatformDeviceIds(offset, batchSize);
            if (deviceIds.isEmpty()) break;

            Instant scheduledAt = Instant.now();
            for (Long deviceId : deviceIds) {
                eventPublisher.publish(Topics.DEVICE_TELEMETRY_SYNC,
                        new DeviceTelemetrySyncTask(deviceId, scheduledAt));
            }

            total += deviceIds.size();
            offset += batchSize;
        }

        if (total > 0) {
            log.info("[PlatformSync] dispatched {} device sync tasks", total);
        }
    }
}
