package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.repository.DeviceRepository;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Scheduled dispatcher: scans ACTIVE devices with platform_device_id,
 * and syncs each device's telemetry directly via a bounded thread pool.
 * <p>
 * Previously used RocketMQ for dispatch→worker decoupling, but the
 * full-snapshot dispatch model (all devices every cycle) combined with
 * CLUSTERING-mode ordered consumption caused severe message backlog:
 * old duplicate messages for early devices blocked newer devices'
 * messages from ever being consumed. The direct-call approach eliminates
 * this entirely — each cycle processes all devices within a bounded
 * concurrency window, with no queue to accumulate.
 */
@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "agentic-platform.sync.enabled", havingValue = "true")
public class AgenticPlatformSyncDispatcher {

    private final DeviceRepository deviceRepository;
    private final AgenticPlatformTelemetrySyncJob syncJob;

    @Value("${agentic-platform.sync.batch-size:1000}")
    private int batchSize;

    @Value("${agentic-platform.sync.concurrency:5}")
    private int concurrency;

    private ExecutorService syncExecutor;

    @Scheduled(fixedDelayString = "${agentic-platform.sync.dispatch-interval-ms:300000}")
    public void dispatch() {
        if (syncExecutor == null || syncExecutor.isShutdown()) {
            syncExecutor = Executors.newFixedThreadPool(concurrency);
        }

        int offset = 0;
        int total = 0;

        while (true) {
            List<Long> deviceIds = deviceRepository.findActivePlatformDeviceIds(offset, batchSize);
            if (deviceIds.isEmpty()) break;

            for (Long deviceId : deviceIds) {
                syncExecutor.submit(() -> {
                    try {
                        syncJob.syncDevice(deviceId);
                    } catch (Exception e) {
                        log.error("[PlatformSync] device {} sync failed: {}", deviceId, e.getMessage());
                    }
                });
            }

            total += deviceIds.size();
            offset += batchSize;
        }

        if (total > 0) {
            log.info("[PlatformSync] dispatched {} device sync tasks (concurrency={})", total, concurrency);
        }
    }

    @PreDestroy
    void shutdown() {
        if (syncExecutor != null) {
            log.info("[PlatformSync] shutting down sync executor, waiting up to 60s for in-flight tasks");
            syncExecutor.shutdown();
            try {
                if (!syncExecutor.awaitTermination(60, TimeUnit.SECONDS)) {
                    syncExecutor.shutdownNow();
                }
            } catch (InterruptedException e) {
                syncExecutor.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }
    }
}
