package com.smartlivestock.health.application;

import com.smartlivestock.health.application.service.CalvingPredictionApplicationService;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository.ActiveLivestock;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Periodic trigger of the calving-risk evaluation (NIX-381 Task 3, plan
 * 2026-11-06 "触发模型与调用链"). Calving signs are a 24–48h slow trend, so the
 * herd is scored on a fixed delay (default 1h, {@code smartlivestock.calving.poll-ms})
 * instead of per telemetry event. Mirrors {@link IndividualBaselineLearningScheduler}:
 * scan livestock with recent temperature telemetry, evaluate each head in
 * its own {@code REQUIRES_NEW} transaction, and never let one bad head stop
 * the batch. The feature gate is checked per head inside the evaluation
 * (explicit farm → tenant resolution; this thread has no TenantContext).
 *
 * <p>No Redis throttle: fixedDelay never overlaps itself and v1 has no second
 * trigger (no manual re-evaluation API). Single-instance assumption as the
 * other health schedulers — add ShedLock before scaling to multiple replicas.</p>
 *
 * <p>{@code enabled=false} stops the automatic evaluation only; existing
 * scores, history rows and tickets are left as they are.</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CalvingPredictionScheduler {

    private final CalvingPredictionApplicationService calvingPredictionService;
    private final HealthSnapshotRepository snapshotRepo;
    private final CalvingPredictionProperties properties;

    @Scheduled(fixedDelayString = "${smartlivestock.calving.poll-ms:3600000}")
    public void evaluateActiveLivestock() {
        if (!properties.isEnabled()) {
            return;
        }
        try {
            Instant cutoff = Instant.now().minus(Duration.ofMinutes(properties.getActiveWindowMinutes()));
            List<ActiveLivestock> active = snapshotRepo.findRecentlyActive(cutoff, properties.getMaxPerPoll());
            if (active.isEmpty()) {
                return;
            }

            int evaluated = 0;
            for (ActiveLivestock item : active) {
                try {
                    calvingPredictionService.evaluateHead(item.livestockId());
                    evaluated++;
                } catch (Exception e) {
                    // evaluateHead already swallows internally; this guards the
                    // loop itself (e.g. a commit failure surfacing from the
                    // REQUIRES_NEW boundary) so one bad head cannot stop the batch.
                    log.warn("Calving evaluation dispatch failed for livestock [{}]: {}",
                            item.livestockId(), e.getMessage());
                }
            }
            log.info("Calving prediction poll complete: {} livestock dispatched", evaluated);
        } catch (Exception e) {
            log.error("Calving prediction poll failed: {}", e.getMessage());
        }
    }
}
