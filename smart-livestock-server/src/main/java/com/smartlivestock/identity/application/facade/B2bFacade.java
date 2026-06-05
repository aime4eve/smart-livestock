package com.smartlivestock.identity.application.facade;

import com.smartlivestock.identity.domain.port.CommerceQueryPort;
import com.smartlivestock.identity.domain.port.IoTQueryPort;
import com.smartlivestock.identity.domain.port.RanchQueryPort;
import com.smartlivestock.identity.domain.port.dto.AlertDto;
import com.smartlivestock.identity.domain.port.dto.ContractDto;
import com.smartlivestock.identity.domain.port.dto.InstallationDto;
import com.smartlivestock.identity.domain.port.dto.LivestockDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Facade that aggregates data from multiple contexts via ACL ports
 * for the B2b admin dashboard.
 */
@Component
@RequiredArgsConstructor
public class B2bFacade {

    private final RanchQueryPort ranchQueryPort;
    private final CommerceQueryPort commerceQueryPort;
    private final IoTQueryPort ioTQueryPort;

    public List<LivestockDto> findLivestockByFarmId(Long farmId) {
        return ranchQueryPort.findLivestockByFarmId(farmId);
    }

    public List<AlertDto> findAlertsByFarmId(Long farmId) {
        return ranchQueryPort.findAlertsByFarmId(farmId);
    }

    public List<InstallationDto> findInstallationsByFarmId(Long farmId) {
        return ioTQueryPort.findInstallationsByFarmId(farmId);
    }

    public long countActiveDevicesByTenant() {
        return ioTQueryPort.countActiveDevicesByTenant();
    }

    public java.util.Optional<ContractDto> findActiveContract(Long tenantId) {
        return commerceQueryPort.findActiveContractByTenantId(tenantId);
    }
}
