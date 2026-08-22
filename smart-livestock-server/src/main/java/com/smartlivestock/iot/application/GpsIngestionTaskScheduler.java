package com.smartlivestock.iot.application;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class GpsIngestionTaskScheduler {
    private final GpsIngestionTaskProcessor processor;

    @Value("${gps.ingestion.batch-size:100}")
    private int batchSize;

    @Value("${gps.ingestion.max-attempts:10}")
    private int maxAttempts;

    @Value("${gps.ingestion.retry-delay:30s}")
    private Duration retryDelay;

    @Scheduled(fixedDelayString = "${gps.ingestion.poll-ms:500}")
    public void processReadyTasks() {
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
    }
}
