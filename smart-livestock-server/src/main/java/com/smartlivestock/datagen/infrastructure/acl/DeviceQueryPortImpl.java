package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.port.DeviceQueryPort;
import com.smartlivestock.datagen.domain.model.DatagenDeviceAssignment;
import com.smartlivestock.datagen.domain.repository.DatagenDeviceAssignmentRepository;
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
    private final DatagenDeviceAssignmentRepository assignmentRepository;

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

    @Override
    public List<ActiveInstallationInfo> findActiveInstallationsByScenario(Long scenarioId) {
        return assignmentRepository.findActiveByScenarioId(scenarioId).stream()
                .map(assignment -> {
                    var device = deviceRepository.findById(assignment.getDeviceId()).orElse(null);
                    if (device == null || device.getStatus() != DeviceStatus.ACTIVE
                            || device.getDeletedAt() != null) {
                        return null;
                    }
                    var installation = installationRepository
                            .findActiveByDeviceId(device.getId()).orElse(null);
                    if (installation == null) return null;
                    Livestock livestock = livestockRepository
                            .findById(installation.getLivestockId()).orElse(null);
                    if (livestock == null) return null;
                    return new ActiveInstallationInfo(
                            device.getId(),
                            livestock.getId(),
                            device.getDeviceType(),
                            livestock.getLastLatitude() != null
                                    ? livestock.getLastLatitude().doubleValue() : null,
                            livestock.getLastLongitude() != null
                                    ? livestock.getLastLongitude().doubleValue() : null);
                })
                .filter(java.util.Objects::nonNull)
                .toList();
    }
}
