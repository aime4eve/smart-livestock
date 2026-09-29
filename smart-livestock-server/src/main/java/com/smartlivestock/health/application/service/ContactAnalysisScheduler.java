package com.smartlivestock.health.application.service;

import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Resident track of the epidemic contact design (spec §4.1, 2026-09-29):
 * every night it rolls the whole-farm contact pool forward by re-running the
 * shared analysis kernel over the last {@code analysis-window-hours} of GPS
 * data for every farm. Rows produced here carry no epidemic semantics
 * (diseaseType/markedAt stay null); the kernel only upserts unmarked rows,
 * so marked history survives rolling re-computation.
 * <p>
 * Single-instance assumption, same as the other schedulers in this app (see
 * HealthAnomalyScheduler); the kernel upsert is idempotent, so an accidental
 * overlap is harmless. Farm enumeration goes straight to the identity farm
 * repository because no cross-context "list all farms" query port exists.
 * <p>
 * Empty-GPS windows are not failures: the kernel already logs an INFO skip
 * per farm, so this scheduler only logs errors for genuinely failed farms.
 */
@Slf4j
@Service
public class ContactAnalysisScheduler {

    private final ContactAnalysisService contactAnalysisService;
    private final FarmRepository farmRepository;

    @Value("${health.contact.scheduler-enabled:true}")
    private boolean enabled;

    @Value("${health.contact.analysis-window-hours:72}")
    private long analysisWindowHours;

    public ContactAnalysisScheduler(ContactAnalysisService contactAnalysisService,
                                    FarmRepository farmRepository) {
        this.contactAnalysisService = contactAnalysisService;
        this.farmRepository = farmRepository;
    }

    /** Result of one pass over all farms, shared with the admin trigger. */
    public record FarmAnalysisOutcome(Map<Long, Integer> writtenByFarm, List<Long> failedFarms) {}

    /**
     * Daily 02:00 rolling re-computation of the contact pool. Gated by
     * {@code health.contact.scheduler-enabled}; the manual admin trigger
     * deliberately bypasses this switch for verification.
     */
    @Scheduled(cron = "${health.contact.analysis-cron:0 0 2 * * *}")
    public void analyzeAllFarmsDaily() {
        if (!enabled) {
            return;
        }
        runForAllFarms();
    }

    /**
     * Analyze every farm over the rolling window. One farm failing must not
     * block the others: failures are logged with the farmId and collected in
     * {@link FarmAnalysisOutcome#failedFarms()}.
     */
    public FarmAnalysisOutcome runForAllFarms() {
        long startedAt = System.currentTimeMillis();
        List<Farm> farms = farmRepository.findAll();
        // Single cutoff per pass keeps the window comparable across farms.
        Instant cutoff = Instant.now().minus(Duration.ofHours(analysisWindowHours));

        Map<Long, Integer> writtenByFarm = new LinkedHashMap<>();
        List<Long> failedFarms = new ArrayList<>();
        for (Farm farm : farms) {
            Long farmId = farm.getId();
            if (farmId == null) {
                continue;
            }
            try {
                writtenByFarm.put(farmId, contactAnalysisService.analyzeAndStore(farmId, null, cutoff));
            } catch (Exception e) {
                failedFarms.add(farmId);
                log.error("Contact analysis failed for farm [{}]: {}", farmId, e.getMessage(), e);
            }
        }

        int totalWritten = writtenByFarm.values().stream().mapToInt(Integer::intValue).sum();
        log.info("Contact analysis run complete: farms={} ok={} failed={} totalWritten={} windowHours={} elapsedMs={}",
                farms.size(), writtenByFarm.size(), failedFarms.size(), totalWritten, analysisWindowHours,
                System.currentTimeMillis() - startedAt);
        return new FarmAnalysisOutcome(writtenByFarm, failedFarms);
    }
}
