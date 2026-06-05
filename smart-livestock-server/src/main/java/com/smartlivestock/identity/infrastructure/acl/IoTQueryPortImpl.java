package com.smartlivestock.identity.infrastructure.acl;

import com.smartlivestock.identity.domain.port.IoTQueryPort;
import com.smartlivestock.identity.domain.port.dto.InstallationDto;
import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.InstallationApplicationService;

import org.springframework.stereotype.Component;

import java.util.List;

@Component("identityIoTQueryPort")
public class IoTQueryPortImpl implements IoTQueryPort {

    private final InstallationApplicationService installationApplicationService;
    private final DeviceApplicationService deviceApplicationService;

    public IoTQueryPortImpl(InstallationApplicationService installationApplicationService,
                             DeviceApplicationService deviceApplicationService) {
        this.installationApplicationService = installationApplicationService;
        this.deviceApplicationService = deviceApplicationService;
    }

    @Override
    public List<InstallationDto> findInstallationsByFarmId(Long farmId) {
        return java.util.List.of(); // TODO: add farm-based query to InstallationApplicationService
    }

    @Override
    public long countActiveDevicesByTenant() {
        return deviceApplicationService.countActiveByTenant();
    }
}
