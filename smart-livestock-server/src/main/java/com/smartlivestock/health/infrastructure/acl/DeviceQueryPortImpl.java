package com.smartlivestock.health.infrastructure.acl;

import com.smartlivestock.health.domain.port.DeviceQueryPort;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Health → IoT ACL (NIX-256 Task 3). "In body" = an installation row with
 * {@code removed_at IS NULL} whose device is an ACTIVE capsule.
 */
@Component("healthDeviceQueryPort")
public class DeviceQueryPortImpl implements DeviceQueryPort {

    private final InstallationRepository installationRepository;
    private final DeviceRepository deviceRepository;

    public DeviceQueryPortImpl(InstallationRepository installationRepository,
                               DeviceRepository deviceRepository) {
        this.installationRepository = installationRepository;
        this.deviceRepository = deviceRepository;
    }

    @Override
    public List<CapsuleBinding> findActiveCapsuleBindings(Collection<Long> livestockIds) {
        if (livestockIds == null || livestockIds.isEmpty()) {
            return List.of();
        }
        List<Installation> installations = installationRepository.findByLivestockIdIn(List.copyOf(livestockIds));
        return toActiveCapsuleBindings(installations);
    }

    @Override
    public List<CapsuleBinding> findAllActiveCapsuleBindings() {
        return toActiveCapsuleBindings(installationRepository.findAllActive());
    }

    @Override
    public java.util.Optional<CapsuleBinding> findActiveCapsuleBinding(Long livestockId) {
        return findActiveCapsuleBindings(List.of(livestockId)).stream().findFirst();
    }

    @Override
    public java.util.Optional<CapsuleBinding> findActiveCapsuleBindingByDeviceId(Long deviceId) {
        return installationRepository.findActiveByDeviceId(deviceId)
                .filter(installation -> isDeviceActiveCapsule(installation.getDeviceId()))
                .map(installation -> new CapsuleBinding(installation.getLivestockId(), installation.getDeviceId()));
    }

    @Override
    public boolean deviceExists(Long deviceId) {
        return deviceId != null && deviceRepository.findById(deviceId).isPresent();
    }

    /** Active installations whose device is an ACTIVE capsule → bindings. */
    private List<CapsuleBinding> toActiveCapsuleBindings(List<Installation> installations) {
        if (installations.isEmpty()) {
            return List.of();
        }
        Set<Long> activeCapsuleDeviceIds = deviceRepository
                .findAllByIdIn(installations.stream().map(Installation::getDeviceId).toList())
                .stream()
                .filter(device -> device.getDeviceType() == DeviceType.CAPSULE)
                .filter(device -> device.getStatus() == DeviceStatus.ACTIVE)
                .map(Device::getId)
                .collect(Collectors.toSet());
        return installations.stream()
                .filter(Installation::isActive)
                .filter(installation -> activeCapsuleDeviceIds.contains(installation.getDeviceId()))
                .map(installation -> new CapsuleBinding(installation.getLivestockId(), installation.getDeviceId()))
                .toList();
    }

    private boolean isDeviceActiveCapsule(Long deviceId) {
        return deviceRepository.findById(deviceId)
                .map(device -> device.getDeviceType() == DeviceType.CAPSULE
                        && device.getStatus() == DeviceStatus.ACTIVE)
                .orElse(false);
    }
}
