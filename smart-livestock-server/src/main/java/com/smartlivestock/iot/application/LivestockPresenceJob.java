package com.smartlivestock.iot.application;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

/**
 * Scheduled evaluators for the presence scenarios (NIX-219 F4/F5/F6):
 * hourly outlier watch, evening return-home roll call (cron configurable),
 * and the nightly roaming-radius aggregation for the health profile.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class LivestockPresenceJob {

    private final LivestockPresenceService presenceService;

    @Scheduled(cron = "0 15 * * * *")
    public void evaluateOutliersHourly() {
        try {
            presenceService.evaluateOutliers();
        } catch (RuntimeException e) {
            log.error("outlier evaluation failed: {}", e.getMessage(), e);
        }
    }

    @Scheduled(cron = "${smartlivestock.presence.return-home.cron:0 30 19 * * *}")
    public void evaluateReturnHome() {
        try {
            presenceService.evaluateReturnHome();
        } catch (RuntimeException e) {
            log.error("return-home evaluation failed: {}", e.getMessage(), e);
        }
    }

    @Scheduled(cron = "0 20 4 * * *")
    public void aggregateRoamDaily() {
        try {
            presenceService.aggregateRoamDaily(LocalDate.now().minusDays(1));
        } catch (RuntimeException e) {
            log.error("roam aggregation failed: {}", e.getMessage(), e);
        }
    }
}
