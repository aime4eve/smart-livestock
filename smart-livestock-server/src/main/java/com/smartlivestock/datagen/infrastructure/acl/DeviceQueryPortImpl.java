package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.port.DeviceQueryPort;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class DeviceQueryPortImpl implements DeviceQueryPort {
    private final InstallationRepository installationRepository;
    private final DeviceRepository deviceRepository;
    private final LivestockRepository livestockRepository;

    @Override
    public List<ActiveInstallationInfo> findActiveInstallations() {
        return installationRepository.findAllActive().stream()
            .map(inst -> {
                var device = deviceRepository.findById(inst.getDeviceId()).orElse(null);
                if (device == null || device.getStatus() != DeviceStatus.ACTIVE) return null;
                Livestock livestock = livestockRepository.findById(inst.getLivestockId()).orElse(null);
                Double lat = livestock != null && livestock.getLastLatitude() != null
                        ? livestock.getLastLatitude().doubleValue() : null;
                Double lng = livestock != null && livestock.getLastLongitude() != null
                        ? livestock.getLastLongitude().doubleValue() : null;
                return new ActiveInstallationInfo(
                    inst.getDeviceId(), inst.getLivestockId(), device.getDeviceType(), lat, lng);
            })
            .filter(java.util.Objects::nonNull)
            .toList();
    }
}
