package com.smartlivestock.health.application;

import com.smartlivestock.health.application.service.IndividualBaselineLearningService;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository.ActiveLivestock;
import com.smartlivestock.health.infrastructure.config.BaselineLearningProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Periodic trigger of the individual temperature baseline learning
 * (plan 2026-11-03 Task 3). Mirrors {@link HealthAnomalyScheduler}: scan
 * recently active livestock, recalculate each head in its own transaction
 * ({@code REQUIRES_NEW} inside the service), and never let one bad head stop
 * the batch. The poll delay comes from
 * {@code smartlivestock.health.baseline-learning.poll-ms} (default 15 min).
 *
 * <p>Concurrency: single-instance assumption — today one app container per
 * environment, and the Redis SET-NX key inside
 * {@code recalculate(id, false)} makes concurrent runs of the same livestock
 * idempotent anyway (key TTL = min recalc interval). If the app is ever
 * scaled to multiple replicas, add ShedLock before removing this note.</p>
 *
 * <p>{@code enabled=false} only stops this automatic batch — manual
 * recalculations and baseline consumption are unaffected (same semantics as
 * the drinking detector switch).</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class IndividualBaselineLearningScheduler {

    /** Recency window of the candidate scan: any temperature in the last day. */
    private static final Duration ACTIVE_WINDOW = Duration.ofHours(24);

    private final IndividualBaselineLearningService learningService;
    private final HealthSnapshotRepository snapshotRepo;
    private final BaselineLearningProperties properties;

    @Scheduled(fixedDelayString = "${smartlivestock.health.baseline-learning.poll-ms:900000}")
    public void recalculateActiveLivestock() {
        if (!properties.isEnabled()) {
            return;
        }
        try {
            Instant cutoff = Instant.now().minus(ACTIVE_WINDOW);
            List<ActiveLivestock> active = snapshotRepo.findRecentlyActive(
                    cutoff, properties.getMaxPerPoll());
            if (active.isEmpty()) {
                return;
            }

            int recalculated = 0;
            for (ActiveLivestock item : active) {
                try {
                    learningService.recalculate(item.livestockId(), false);
                    recalculated++;
                } catch (Exception e) {
                    // One bad head must not stop the batch — the recalculation
                    // already ran inside its own REQUIRES_NEW transaction.
                    log.warn("Baseline learning failed for livestock [{}]: {}",
                            item.livestockId(), e.getMessage());
                }
            }
            log.info("Baseline learning poll complete: {} livestock processed", recalculated);
        } catch (Exception e) {
            log.error("Baseline learning poll failed: {}", e.getMessage());
        }
    }
}
