package com.smartlivestock.health.domain.port;

import com.smartlivestock.health.domain.port.dto.LivestockInfo;

import java.util.List;
import java.util.Optional;

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
}
