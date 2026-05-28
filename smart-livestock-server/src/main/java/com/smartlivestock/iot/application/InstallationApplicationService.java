package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.command.InstallDeviceCommand;
import com.smartlivestock.iot.application.dto.InstallationDto;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class InstallationApplicationService {

    private final InstallationRepository installationRepository;

    @Transactional
    public InstallationDto install(InstallDeviceCommand command) {
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
}
