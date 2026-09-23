package com.smartlivestock.health.domain.port;

import com.smartlivestock.health.domain.port.dto.LivestockInfo;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * ACL query port for Health context to read Ranch context data.
 */
public interface RanchQueryPort {
    Optional<LivestockInfo> findLivestockById(Long livestockId);
    List<LivestockInfo> findAllByFarmId(Long farmId);
    int countActiveAlertsByFarmId(Long farmId);

    /**
     * Whether the livestock already has an ACTIVE alert of the given
     * ranch AlertType name (e.g. "TEMPERATURE_ABNORMAL").
     * Used by the health alert bridge to deduplicate ticket creation.
     */
    boolean hasActiveAlert(Long livestockId, String alertType);

    /** ACTIVE alerts of the farm filtered by ranch AlertType names. */
    List<AlertBrief> findActiveAlertsByFarmIdAndTypes(Long farmId, Collection<String> types);

    /**
     * Alerts of the farm resolved (AUTO_RESOLVED/DISMISSED) at or after
     * {@code since}, filtered by type names — powers "recovered today"
     * workbench groups and the epidemic 7-day window.
     */
    List<AlertBrief> findResolvedAlertsByFarmIdAndTypesSince(Long farmId, Collection<String> types, Instant since);

    /** Which of the given alert ids the user already read. */
    Set<Long> findReadAlertIds(Long userId, Collection<Long> alertIds);

    /** Minimal alert projection shared with the health workbenches. */
    record AlertBrief(Long alertId, Long livestockId, String type, String severity,
                      Instant createdAt, Instant resolvedAt) {}
}
