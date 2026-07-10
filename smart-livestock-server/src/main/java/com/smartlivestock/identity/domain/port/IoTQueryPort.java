package com.smartlivestock.identity.domain.port;

import com.smartlivestock.identity.domain.port.dto.InstallationDto;

import java.util.List;

public interface IoTQueryPort {
    List<InstallationDto> findInstallationsByFarmId(Long farmId);
    long countActiveDevicesByTenant();
}
