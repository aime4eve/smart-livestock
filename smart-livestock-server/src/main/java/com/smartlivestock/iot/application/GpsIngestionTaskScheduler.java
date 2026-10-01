package com.smartlivestock.iot.application;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Consumes the GPS ingestion outbox on a DEDICATED executor. The shared
 * Spring scheduler was observed dying silently in the field (2026-09-30,
 * thread dump: no scheduling threads at all, no error logged), which left
 * ~2000 GPS tasks PENDING and gps_logs frozen — the map and fence features
 * lose all position data the moment the shared pool dies. A self-managed
 * executor with a catch-Throwable loop survives that failure mode.
 */
@Slf4j
@Service
public class GpsIngestionTaskScheduler {
    private final GpsIngestionTaskProcessor processor;

    @Value("${gps.ingestion.batch-size:100}")
    private int batchSize;

    @Value("${gps.ingestion.max-attempts:10}")
    private int maxAttempts;

    @Value("${gps.ingestion.retry-delay:30s}")
    private Duration retryDelay;

    @Value("${gps.ingestion.poll-ms:500}")
    private long pollMs;

    private ScheduledExecutorService pollExecutor;

    public GpsIngestionTaskScheduler(GpsIngestionTaskProcessor processor) {
        this.processor = processor;
    }

    @PostConstruct
    public void start() {
        pollExecutor = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "gps-ingestion-poll");
            t.setDaemon(true);
            return t;
        });
        // fixedDelay: a slow batch can never stack up.
        pollExecutor.scheduleWithFixedDelay(this::processReadyTasks, pollMs, pollMs, TimeUnit.MILLISECONDS);
        log.info("GPS ingestion poll started on a dedicated executor (fixedDelay={}ms)", pollMs);
    }

    @PreDestroy
    public void stop() {
        if (pollExecutor != null) {
            pollExecutor.shutdownNow();
        }
    }

    void processReadyTasks() {
        // catch Throwable — a scheduleWithFixedDelay task is cancelled the
        // first time its runnable throws, so nothing may escape this method.
        try {
            List<Long> taskIds = processor.findReadyTaskIds(Instant.now(), batchSize);
            if (taskIds.isEmpty()) {
                return;
            }

            int succeeded = 0;
            int failed = 0;
            for (Long taskId : taskIds) {
                try {
                    if (processor.processTask(taskId)) {
                        succeeded++;
                    }
                } catch (Exception e) {
                    failed++;
                    String error = e.getClass().getSimpleName() + ": " + e.getMessage();
                    try {
                        processor.recordFailure(taskId, error, maxAttempts, Instant.now().plus(retryDelay));
                    } catch (Exception recordError) {
                        log.error("Failed to record GPS ingestion task failure [{}]: {}",
                                taskId, recordError.getMessage());
                    }
                    log.warn("GPS ingestion task [{}] failed ({}): {}",
                            taskId, e.getClass().getSimpleName(), e.getMessage());
                }
            }

            if (failed > 0) {
                log.warn("GPS ingestion batch complete: succeeded={}, failed={}", succeeded, failed);
            } else {
                log.info("GPS ingestion batch complete: succeeded={}", succeeded);
            }
        } catch (Throwable t) {
            log.error("GPS ingestion poll failed - dedicated schedule kept alive", t);
        }
    }
}
