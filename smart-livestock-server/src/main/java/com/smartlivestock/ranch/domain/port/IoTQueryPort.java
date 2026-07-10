package com.smartlivestock.ranch.domain.port;

import com.smartlivestock.ranch.domain.port.dto.DeviceBrief;
import com.smartlivestock.ranch.domain.port.dto.DeviceStatsInfo;
import com.smartlivestock.ranch.domain.port.dto.InstallationInfo;

import java.util.List;
import java.util.Map;
import java.util.Optional;

public interface IoTQueryPort {
    Optional<InstallationInfo> findActiveInstallation(Long deviceId);
    DeviceStatsInfo getDeviceStats(Long tenantId);

    boolean hasActiveInstallationByLivestock(Long livestockId);

    double getDeviceOnlineRate(Long tenantId);

    /**
     * Batch query active devices for multiple livestock.
     * @param livestockIds livestock IDs to query (empty list returns empty map)
     * @return Map: livestockId -> List<DeviceBrief>;
     *         livestock without devices will not appear as a key
     */
    Map<Long, List<DeviceBrief>> findActiveDevicesByLivestockIds(List<Long> livestockIds);
}
