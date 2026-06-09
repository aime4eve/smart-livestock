package com.smartlivestock.ranch.domain.port;

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
            int estrusScore
    ) {}

    record HealthOverview(
            int totalLivestock,
            double healthyRate,
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
}
