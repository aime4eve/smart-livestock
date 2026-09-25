package com.smartlivestock.health.application;

import com.smartlivestock.health.application.service.HealthAnomalyService;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository.ActiveLivestock;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Periodic trigger for AI anomaly assessment, replacing the inline
 * processTelemetry call removed on 2026-06-30 (REQUIRES_NEW inside the
 * telemetry-consuming transaction corrupted Hibernate sessions under backlog).
 *
 * Runs serially on the scheduler thread, fully outside any consuming
 * transaction: at most one pooled connection is held at a time (inside
 * assess), so the original incident shape cannot recur. Per-livestock
 * frequency is bounded by the Redis dedup key (default 60min).
 *
 * Single-instance assumption: today one app container per environment, and
 * the Redis dedup makes concurrent runs idempotent. If the app is ever
 * scaled to multiple replicas, add ShedLock (or reuse the dedup as a lock)
 * before removing this note.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HealthAnomalyScheduler {

    private final HealthAnomalyService healthAnomalyService;
    private final HealthSnapshotRepository snapshotRepo;

    @Value("${ai.assessment.enabled:true}")
    private boolean enabled;

    @Value("${ai.assessment.active-window-minutes:120}")
    private int activeWindowMinutes;

    @Value("${ai.assessment.max-per-poll:200}")
    private int maxPerPoll;

    @Value("${ai.assessment.tenant-id:1}")
    private Long tenantId;

    @Scheduled(fixedDelayString = "${ai.assessment.poll-ms:300000}")
    public void assessActiveLivestock() {
        if (!enabled) {
            return;
        }
        try {
            Instant cutoff = Instant.now().minus(Duration.ofMinutes(activeWindowMinutes));
            List<ActiveLivestock> active = snapshotRepo.findRecentlyActive(cutoff, maxPerPoll);
            if (active.isEmpty()) {
                return;
            }

            int assessed = 0;
            for (ActiveLivestock item : active) {
                try {
                    healthAnomalyService.assess(tenantId, item.farmId(),
                            item.livestockId(), item.telemetrySource());
                    assessed++;
                } catch (Exception e) {
                    // assess() already swallows internally; this guards the
                    // loop itself so one bad row cannot stop the batch
                    log.warn("AI assessment dispatch failed for livestock [{}]: {}",
                            item.livestockId(), e.getMessage());
                }
            }
            log.info("AI anomaly poll complete: {} livestock dispatched", assessed);
        } catch (Exception e) {
            log.error("AI anomaly poll failed: {}", e.getMessage());
        }
    }
}
