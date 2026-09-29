package com.smartlivestock.ranch.domain.port;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

/**
 * ACL query port for Ranch context to read Health context data.
 */
public interface HealthQueryPort {

    record LivestockHealthState(
            Long livestockId,
            String tempStatus,
            String motilityStatus,
            int estrusScore,
            BigDecimal currentTemp,
            BigDecimal currentMotility,
            String activityStatus
    ) {}

    /**
     * Epidemic mark-diseased state of one livestock for the detail view
     * (plan Task 6): the outbound row with the latest {@code markedAt}
     * supplies the disease type / stamp, and {@code contactCount} is the
     * number of marked outbound rows (contacts claimed by this epidemic
     * source). Empty when the livestock is not currently marked.
     */
    record MarkedSourceState(
            String diseaseType,
            Instant markedAt,
            int contactCount
    ) {}

    record HealthOverview(
            int totalLivestock,
            Double healthyRate,
            int alertCount,
            int criticalCount,
            int feverAbnormalCount,
            int feverCriticalCount,
            int digestiveAbnormalCount,
            int digestiveWatchCount,
            int estrusHighScoreCount,
            double epidemicAbnormalRate
    ) {}

    Optional<LivestockHealthState> findHealthByLivestockId(Long livestockId);
    List<LivestockHealthState> findHealthByFarmId(Long farmId);
    HealthOverview getHealthOverview(Long farmId);
    Optional<MarkedSourceState> findMarkedSourceByLivestockId(Long livestockId);
}
