package com.smartlivestock.health.application;

import com.smartlivestock.health.application.service.DrinkingEventDetectionService;
import com.smartlivestock.health.application.service.DrinkingRecalculationService;
import com.smartlivestock.health.application.service.DrinkingRecalculationService.FarmSweep;
import com.smartlivestock.health.application.service.DrinkingRecalculationService.RecalcWindow;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Nightly drinking-event recalculation (NIX-256 Task 4): every farm with
 * active capsule bindings re-derives yesterday's Asia/Shanghai cow-day
 * (F5) through {@link DrinkingRecalculationService#recalculateAllFarms}.
 *
 * <p>No scheduler bean is created here — SchedulerPoolConfig provides the
 * app-wide explicit taskScheduler (8 threads) and @Scheduled routes to it
 * automatically (N4 ruling; mixed scheduler beans were the root cause of
 * the 2026-09-30 silent-death incident). Runs serially on one pooled
 * thread; single-instance assumption per HealthAnomalyScheduler.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "health.drinking.enabled", havingValue = "true", matchIfMissing = true)
public class DrinkingEventScheduler {

    private final DrinkingRecalculationService recalculationService;

    /**
     * Daily batch, default 03:40 server time — after datagen retention
     * (03:00) and partition maintenance (02:10) have settled, before the
     * morning dashboards.
     */
    @Scheduled(cron = "${health.drinking.analysis-cron:0 40 3 * * *}")
    public void nightlyRecalculate() {
        run(Instant.now());
    }

    /** Testable core: the sweep window is derived from {@code now}. */
    void run(Instant now) {
        long startedAt = System.currentTimeMillis();
        RecalcWindow window = yesterdayWindow(now);
        log.info("Drinking nightly recalculation started: window=[{}, {})", window.from(), window.to());
        FarmSweep sweep = recalculationService.recalculateAllFarms(window.from(), window.to());
        log.info("Drinking nightly recalculation finished: farms={} (failed={}), devices={}, events={}, took {} ms",
                sweep.farms(), sweep.failedFarms(), sweep.devices(), sweep.events(),
                System.currentTimeMillis() - startedAt);
    }

    /**
     * Yesterday's cow-day window (F5): [yesterday 00:00, today 00:00) in
     * Asia/Shanghai, derived from {@code now}. Package-visible static pure
     * function so the day-boundary math is unit-testable in isolation.
     */
    static RecalcWindow yesterdayWindow(Instant now) {
        LocalDate today = LocalDate.ofInstant(now, DrinkingEventDetectionService.COW_DAY_ZONE);
        Instant to = today.atStartOfDay(DrinkingEventDetectionService.COW_DAY_ZONE).toInstant();
        Instant from = to.minus(Duration.ofDays(1));
        return new RecalcWindow(from, to);
    }
}
