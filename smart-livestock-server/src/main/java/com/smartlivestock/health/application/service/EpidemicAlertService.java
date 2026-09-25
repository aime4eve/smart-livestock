package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort.AlertBrief;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Set;

/**
 * Farm-wide EPIDEMIC warning ticket (NIX-245): the epidemic scene had no
 * ticket path at all. Plain-language rule (spec §5.5): more than 10% of the
 * herd had a health ticket in the last 7 days → open ONE farm-level warning;
 * back under 5% → auto-resolve it. Deduplicated: never two ACTIVE farm
 * epidemic tickets.
 */
@Slf4j
@Service
public class EpidemicAlertService {

    static final double OPEN_RATE = 0.10;
    static final double RESOLVE_RATE = 0.05;
    static final Duration WINDOW = Duration.ofDays(7);
    static final Set<String> SOURCE_TYPES = HealthEpisodeService.EPIDEMIC_SOURCE_TYPES;

    private final HealthSnapshotRepository snapshotRepo;
    private final RanchQueryPort ranchQueryPort;
    private final RanchCommandPort ranchCommandPort;

    @Value("${health.epidemic.enabled:true}")
    private boolean enabled;

    public EpidemicAlertService(HealthSnapshotRepository snapshotRepo,
                                RanchQueryPort ranchQueryPort,
                                RanchCommandPort ranchCommandPort) {
        this.snapshotRepo = snapshotRepo;
        this.ranchQueryPort = ranchQueryPort;
        this.ranchCommandPort = ranchCommandPort;
    }

    @Scheduled(cron = "${health.epidemic.check-cron:0 20 * * * *}")
    public void checkAllFarms() {
        if (!enabled) return;
        for (Long farmId : snapshotRepo.findDistinctFarmIds()) {
            try {
                evaluate(farmId);
            } catch (Exception e) {
                log.warn("Epidemic check failed for farm [{}]: {}", farmId, e.getMessage());
            }
        }
    }

    /** @return current 7-day abnormal rate (also used by the epidemic board). */
    public double evaluate(Long farmId) {
        int total = ranchQueryPort.findAllByFarmId(farmId).size();
        if (total == 0) return 0;

        Instant since = Instant.now().minus(WINDOW);
        Set<Long> affected = new java.util.HashSet<>();
        for (AlertBrief a : ranchQueryPort.findActiveAlertsByFarmIdAndTypes(farmId, SOURCE_TYPES)) {
            if (a.livestockId() != null) affected.add(a.livestockId());
        }
        for (AlertBrief a : ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(farmId, SOURCE_TYPES, since)) {
            if (a.livestockId() != null) affected.add(a.livestockId());
        }
        double rate = (double) affected.size() / total;

        boolean hasActive = !ranchQueryPort
                .findActiveAlertsByFarmIdAndTypes(farmId, HealthEpisodeService.EPIDEMIC_TYPES).isEmpty();

        if (rate >= OPEN_RATE && !hasActive) {
            ranchCommandPort.createAlert(new AlertInfo(
                    farmId, null, "EPIDEMIC", "CRITICAL",
                    String.format("7 天内 %.0f%% 的牲畜出现过健康异常（%d/%d），疑似群发风险",
                            rate * 100, affected.size(), total),
                    "RULE", "alert.health.epidemic",
                    List.of(String.valueOf(affected.size()), String.valueOf(total))));
            log.info("Opened farm epidemic warning for farm [{}] (rate={}, {}/{})",
                    farmId, rate, affected.size(), total);
        } else if (rate < RESOLVE_RATE && hasActive) {
            ranchCommandPort.resolveFarmAlertsByType(farmId, "EPIDEMIC");
            log.info("Resolved farm epidemic warning for farm [{}] (rate={})", farmId, rate);
        }
        return rate;
    }
}
