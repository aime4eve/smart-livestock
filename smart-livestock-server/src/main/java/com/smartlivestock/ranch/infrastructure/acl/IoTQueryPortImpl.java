package com.smartlivestock.ranch.infrastructure.acl;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.dto.DeviceStatsInfo;
import com.smartlivestock.ranch.domain.port.dto.InstallationInfo;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component("ranchIoTQueryPort")
public class IoTQueryPortImpl implements IoTQueryPort {

    private final DeviceRepository deviceRepository;
    private final InstallationRepository installationRepository;
    private final DeviceApplicationService deviceApplicationService;

    public IoTQueryPortImpl(DeviceRepository deviceRepository,
                             InstallationRepository installationRepository,
                             DeviceApplicationService deviceApplicationService) {
        this.deviceRepository = deviceRepository;
        this.installationRepository = installationRepository;
        this.deviceApplicationService = deviceApplicationService;
    }

    @Override
    public Optional<InstallationInfo> findActiveInstallation(Long deviceId) {
        return installationRepository.findActiveByDeviceId(deviceId)
                .map(i -> new InstallationInfo(i.getId(), i.getDeviceId(), i.getLivestockId()));
    }

    @Override
    public DeviceStatsInfo getDeviceStats(Long tenantId) {
        long active = deviceApplicationService.countActiveByTenant();
        return new DeviceStatsInfo(active);
    }

    @Override
    public double getDeviceOnlineRate(Long tenantId) {
        var all = deviceRepository.findByTenantId(tenantId);
        if (all.isEmpty()) return 1.0;
        long active = all.stream()
                .filter(d -> d.getStatus() == DeviceStatus.ACTIVE)
                .count();
        return (double) active / all.size();
    }

    @Override
    public boolean hasActiveInstallationByLivestock(Long livestockId) {
        return installationRepository.findByLivestockId(livestockId).stream()
                .anyMatch(i -> i.getRemovedAt() == null);
    }
}
