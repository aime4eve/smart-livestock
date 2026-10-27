package com.smartlivestock.identity.application;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * NIX-325 schedulers: export package generation (async, streaming) and
 * post-window package cleanup. Cron-configurable like LivestockPresenceJob.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataExportScheduler {

    private final DataExportApplicationService dataExportApplicationService;

    @Scheduled(cron = "${smartlivestock.export.generation-cron:0 */10 * * * *}")
    public void generatePending() {
        try {
            dataExportApplicationService.generateNextPending();
        } catch (Exception e) {
            log.error("NIX-325 export generation pass failed: {}", e.getMessage(), e);
        }
    }

    @Scheduled(cron = "${smartlivestock.export.cleanup-cron:0 40 3 * * *}")
    public void cleanupExpiredPackages() {
        try {
            dataExportApplicationService.cleanupExpiredPackages();
        } catch (Exception e) {
            log.error("NIX-325 export cleanup pass failed: {}", e.getMessage(), e);
        }
    }
}
