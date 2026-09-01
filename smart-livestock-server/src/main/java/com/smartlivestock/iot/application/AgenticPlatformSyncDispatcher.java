package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * Scheduled dispatcher: scans ACTIVE devices with platform_device_id,
 * and syncs each device's telemetry directly via a bounded thread pool.
 * <p>
 * Previously used RocketMQ for dispatch->worker decoupling, but the
 * full-snapshot dispatch model (all devices every cycle) combined with
 * CLUSTERING-mode ordered consumption caused severe message backlog:
 * old duplicate messages for early devices blocked newer devices'
 * messages from ever being consumed. The direct-call approach eliminates
 * this entirely -- each cycle processes all devices within a bounded
 * concurrency window, with no queue to accumulate.
 * <p>
 * Backpressure: uses an explicit bounded queue (at least 1000 capacity)
 * with CallerRunsPolicy so no device task is ever silently dropped.
 * If the previous cycle hasn't finished, the queue still has pending
 * tasks and dispatch() skips the new cycle entirely (logged as INFO).
 */
@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "agentic-platform.sync.enabled", havingValue = "true")
public class AgenticPlatformSyncDispatcher {

    private final DeviceRepository deviceRepository;
    private final AgenticPlatformTelemetrySyncJob syncJob;
    private final TbDeviceBindingRepository tbDeviceBindingRepository;

    @Value("${agentic-platform.sync.batch-size:1000}")
    private int batchSize;

    @Value("${agentic-platform.sync.concurrency:5}")
    private int concurrency;

    /**
     * NIX-179: when true, devices bound to the ThingsBoard channel are skipped
     * by the blade poller to prevent the same frame arriving from both sources.
     * Default false keeps existing behavior untouched.
     */
    @Value("${smartlivestock.tb.blade-exclusion:false}")
    private boolean tbBladeExclusion;

    @Value("${smartlivestock.tb.tenant-id:1}")
    private Long tbTenantId;

    /** Blade fallback tuning: a binding whose TB cursor is frozen longer than
     * this window (or that fails this many cycles in a row) degrades to blade. */
    @Value("${smartlivestock.tb.fallback.stale-after-ms:900000}")
    private long tbFallbackStaleAfterMs;

    @Value("${smartlivestock.tb.fallback.failure-threshold:3}")
    private int tbFallbackFailureThreshold;

    /** Loaded once per cycle; empty when exclusion is off or no devices bound. */
    private volatile java.util.Set<Long> tbBoundDeviceIds = java.util.Set.of();

    private ThreadPoolExecutor syncExecutor;
    private int queueCapacity;

    @Scheduled(fixedDelayString = "${agentic-platform.sync.dispatch-interval-ms:300000}")
    public void dispatch() {
        if (syncExecutor == null || syncExecutor.isShutdown()) {
            // Queue must hold at least one full dispatch cycle worth of tasks,
            // otherwise devices at the end of the list get silently dropped.
            queueCapacity = Math.max(concurrency * 10, 1000);
            BlockingQueue<Runnable> queue = new LinkedBlockingQueue<>(queueCapacity);
            syncExecutor = new ThreadPoolExecutor(
                    concurrency, concurrency,
                    0L, TimeUnit.MILLISECONDS,
                    queue,
                    new ThreadPoolExecutor.CallerRunsPolicy());
        }

        // Backpressure: skip this cycle if the previous one hasn't finished.
        int pending = syncExecutor.getQueue().size();
        int active = syncExecutor.getActiveCount();
        if (pending > 0) {
            log.info("[PlatformSync] previous cycle still running (active={}, pending={}), skipping this cycle",
                    active, pending);
            return;
        }

        int offset = 0;
        int total = 0;
        refreshTbBoundDeviceIds();

        while (true) {
            List<Long> deviceIds = deviceRepository.findActivePlatformDeviceIds(offset, batchSize);
            if (deviceIds.isEmpty()) break;

            for (Long deviceId : deviceIds) {
                if (tbBoundDeviceIds.contains(deviceId)) continue;
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
            log.info("[PlatformSync] dispatched {} device sync tasks (concurrency={}, queueCapacity={})", total, concurrency, queueCapacity);
        }
    }

    private void refreshTbBoundDeviceIds() {
        if (!tbBladeExclusion) {
            tbBoundDeviceIds = java.util.Set.of();
            return;
        }
        try {
            // Dynamic fallback: only TB-healthy bindings stay excluded. A bound
            // device whose TB cursor froze (e.g. a modified TB rule chain) or
            // that keeps failing degrades to the blade channel automatically;
            // once TB recovers and the cursor advances, it is excluded again.
            // Double-source overlap stays safe through the (device_id,
            // report_time) idempotency in the unified ingest path.
            long now = System.currentTimeMillis();
            java.util.List<TbDeviceBinding> bindings = tbDeviceBindingRepository
                    .findByTenantIdAndStatus(tbTenantId, TbDeviceBinding.Status.RESOLVED);
            java.util.Set<Long> healthy = new java.util.HashSet<>();
            java.util.List<Long> degraded = new java.util.ArrayList<>();
            for (TbDeviceBinding binding : bindings) {
                if (binding.isTbChannelHealthy(now, tbFallbackStaleAfterMs, tbFallbackFailureThreshold)) {
                    healthy.add(binding.getDeviceId());
                } else {
                    degraded.add(binding.getDeviceId());
                }
            }
            if (!degraded.isEmpty()) {
                log.warn("[PlatformSync] TB channel degraded for device(s) {}, blade fallback active (healthy exclusions: {})",
                        degraded, healthy.size());
            }
            tbBoundDeviceIds = java.util.Collections.unmodifiableSet(healthy);
        } catch (Exception e) {
            // Fail-open: exclusion is an optimization against double-pull; a
            // binding lookup failure must never stop the blade channel.
            log.warn("[PlatformSync] TB binding lookup failed, blade exclusion disabled this cycle: {}", e.getMessage());
            tbBoundDeviceIds = java.util.Set.of();
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
