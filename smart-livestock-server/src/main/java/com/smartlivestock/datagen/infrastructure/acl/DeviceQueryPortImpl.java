package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.port.DeviceQueryPort;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class DeviceQueryPortImpl implements DeviceQueryPort {
    private final InstallationRepository installationRepository;
    private final DeviceRepository deviceRepository;

    @Override
    public List<ActiveInstallationInfo> findActiveInstallations() {
        return installationRepository.findAllActive().stream()
            .map(inst -> {
                var device = deviceRepository.findById(inst.getDeviceId()).orElse(null);
                if (device == null || device.getStatus() != DeviceStatus.ACTIVE) return null;
                return new ActiveInstallationInfo(
                    inst.getDeviceId(), inst.getLivestockId(), device.getDeviceType());
            })
            .filter(java.util.Objects::nonNull)
            .toList();
    }
}
