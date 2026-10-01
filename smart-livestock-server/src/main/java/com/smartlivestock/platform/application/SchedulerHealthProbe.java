package com.smartlivestock.platform.application;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Liveness probe for the SHARED scheduler pool (2026-10-01 investigation,
 * docs/superpowers/specs/2026-10-01-scheduler-death-investigation-plan.md).
 * The shared scheduler was observed dying silently in the field — all
 * @Scheduled tasks stop while HTTP/MQ/DB stay healthy, with no error
 * logged. This probe emits one INFO line every 30s; the exact second this
 * line stops is the death timestamp for thread-dump correlation.
 *
 * Resolves the TaskScheduler lazily via ObjectProvider: a hard constructor
 * dependency would fail the whole context when the scheduler bean is of an
 * unexpected type (which is itself diagnostic information — logged).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class SchedulerHealthProbe {

    private final ObjectProvider<TaskScheduler> schedulerProvider;

    @Scheduled(fixedDelayString = "${platform.scheduler-probe.interval-ms:30000}")
    public void probe() {
        try {
            TaskScheduler scheduler = schedulerProvider.getIfAvailable();
            if (scheduler == null) {
                log.info("[SchedProbe] alive (no TaskScheduler bean resolved)");
                return;
            }
            if (scheduler instanceof org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler pool) {
                var executor = pool.getScheduledThreadPoolExecutor();
                log.info("[SchedProbe] alive active={} poolSize={} queue={} completed={}",
                        executor.getActiveCount(), executor.getPoolSize(),
                        executor.getQueue().size(), executor.getCompletedTaskCount());
            } else {
                log.info("[SchedProbe] alive scheduler={} (no executor metrics)",
                        scheduler.getClass().getSimpleName());
            }
        } catch (Throwable t) {
            // Even the probe itself must never die to the same mechanism.
            log.error("[SchedProbe] probe failed - keeping schedule alive", t);
        }
    }
}
