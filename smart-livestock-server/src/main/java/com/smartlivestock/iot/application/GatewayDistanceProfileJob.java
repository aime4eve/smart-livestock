package com.smartlivestock.iot.application;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Daily rebuild of the per-gateway RSSI→distance maps (NIX-219 plan B).
 * Runs after the partition maintenance window, before business hours.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class GatewayDistanceProfileJob {

    private final GatewayDistanceProfileService profileService;

    @Scheduled(cron = "0 40 3 * * *")
    public void rebuildDaily() {
        try {
            int processed = profileService.rebuildAll();
            log.info("GatewayDistanceProfileJob done: {} gateways processed", processed);
        } catch (RuntimeException e) {
            log.error("GatewayDistanceProfileJob failed: {}", e.getMessage(), e);
        }
    }
}
