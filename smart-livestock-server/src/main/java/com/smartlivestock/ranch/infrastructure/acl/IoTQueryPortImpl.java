package com.smartlivestock.ranch.infrastructure.acl;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.dto.DeviceBrief;
import com.smartlivestock.ranch.domain.port.dto.DeviceStatsInfo;
import com.smartlivestock.ranch.domain.port.dto.InstallationInfo;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

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

    // Count-based: avoids loading the entire tenant device list into memory.
    @Override
    public double getDeviceOnlineRate(Long tenantId) {
        long active = deviceRepository.countByTenantIdAndStatus(tenantId, DeviceStatus.ACTIVE.name());
        long total = deviceRepository.countByTenantIdPaged(tenantId);
        if (total == 0) return 1.0;
        return (double) active / total;
    }

    @Override
    public boolean hasActiveInstallationByLivestock(Long livestockId) {
        return installationRepository.findByLivestockId(livestockId).stream()
                .anyMatch(i -> i.getRemovedAt() == null);
    }

    @Override
    public Map<Long, List<DeviceBrief>> findActiveDevicesByLivestockIds(List<Long> livestockIds) {
        if (livestockIds == null || livestockIds.isEmpty()) {
            return Collections.emptyMap();
        }
        // Batch query active installations for all livestock
        List<Installation> installations = installationRepository.findByLivestockIdIn(livestockIds);
        // Filter to active only
        List<Installation> active = installations.stream()
                .filter(i -> i.getRemovedAt() == null)
                .toList();
        if (active.isEmpty()) {
            return Collections.emptyMap();
        }
        // Batch query devices
        List<Long> deviceIds = active.stream().map(Installation::getDeviceId).distinct().toList();
        Map<Long, Device> deviceMap = deviceIds.stream()
                .map(deviceRepository::findById)
                .filter(Optional::isPresent)
                .map(Optional::get)
                .collect(Collectors.toMap(Device::getId, d -> d));
        // Group by livestockId
        return active.stream()
                .filter(i -> deviceMap.containsKey(i.getDeviceId()))
                .collect(Collectors.groupingBy(
                        Installation::getLivestockId,
                        Collectors.mapping(
                                i -> toDeviceBrief(deviceMap.get(i.getDeviceId())),
                                Collectors.toList()
                        )
                ));
    }

    private DeviceBrief toDeviceBrief(Device device) {
        return new DeviceBrief(
                device.getId(),
                device.getDeviceCode(),
                device.getDevEui(),
                device.getDeviceType() != null ? device.getDeviceType().name() : null
        );
    }
}
