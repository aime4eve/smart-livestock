package com.smartlivestock.ranch.domain.port;

import com.smartlivestock.ranch.domain.port.dto.DeviceStatsInfo;
import com.smartlivestock.ranch.domain.port.dto.InstallationInfo;

import java.util.Optional;

public interface IoTQueryPort {
    Optional<InstallationInfo> findActiveInstallation(Long deviceId);
    DeviceStatsInfo getDeviceStats(Long tenantId);

    boolean hasActiveInstallationByLivestock(Long livestockId);

    double getDeviceOnlineRate(Long tenantId);
}
