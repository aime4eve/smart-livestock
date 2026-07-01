package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.command.InstallDeviceCommand;
import com.smartlivestock.iot.application.dto.InstallationDto;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class InstallationApplicationService {

    private final DeviceRepository deviceRepository;
    private final InstallationRepository installationRepository;

    @Transactional
    public InstallationDto install(InstallDeviceCommand command) {
        Device device = deviceRepository.findById(command.deviceId())
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备不存在: " + command.deviceId()));
        if (device.getStatus() != DeviceStatus.ACTIVE) {
            throw new ApiException(ErrorCode.DEVICE_NOT_ACTIVE,
                    "设备未激活，无法安装: " + command.deviceId());
        }
        if (installationRepository.findActiveByDeviceId(command.deviceId()).isPresent()) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "设备已安装在其他牲畜上: " + command.deviceId());
        }
        if (installationRepository.findActiveByLivestockIdAndDeviceType(
                command.livestockId(), device.getDeviceType()).isPresent()) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    "该牲畜已安装同类型设备: " + device.getDeviceType());
        }
        Installation installation = new Installation(command.deviceId(), command.livestockId(), command.operatorId());
        Installation saved = installationRepository.save(installation);
        return InstallationDto.from(saved);
    }

    @Transactional(readOnly = true)
    public Optional<InstallationDto> getActiveInstallation(Long deviceId) {
        return installationRepository.findActiveByDeviceId(deviceId)
                .map(InstallationDto::from);
    }

    /**
     * Remove (uninstall) the currently active installation for the given device.
     *
     * @param deviceId   the device whose active installation should be removed
     * @param operatorId the user performing the removal
     */
    @Transactional
    public void remove(Long deviceId, Long operatorId) {
        Installation installation = installationRepository.findActiveByDeviceId(deviceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备无活跃安装记录: " + deviceId));
        installation.remove();
        installationRepository.save(installation);
    }

    @Transactional(readOnly = true)
    public Optional<InstallationDto> findById(Long id) {
        return installationRepository.findById(id).map(InstallationDto::from);
    }

    @Transactional(readOnly = true)
    public List<InstallationDto> findByLivestockIds(List<Long> livestockIds) {
        return installationRepository.findByLivestockIdIn(livestockIds).stream()
                .map(InstallationDto::from)
                .toList();
    }

    @Transactional
    public InstallationDto removeById(Long installationId) {
        Installation installation = installationRepository.findById(installationId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "安装记录不存在: " + installationId));
        installation.remove();
        Installation saved = installationRepository.save(installation);
        return InstallationDto.from(saved);
    }

    @Transactional(readOnly = true)
    public List<InstallationDto> findAllActive() {
        return installationRepository.findAllActive().stream()
                .map(InstallationDto::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public Optional<InstallationDto> getActiveInstallationByLivestock(Long livestockId) {
        return installationRepository.findActiveByLivestockId(livestockId)
                .map(InstallationDto::from);
    }
}
