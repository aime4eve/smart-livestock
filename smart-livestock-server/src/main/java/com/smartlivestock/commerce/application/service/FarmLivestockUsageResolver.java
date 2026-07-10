package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.port.RanchQueryPort;
import org.springframework.stereotype.Component;

/**
 * Counts livestock per farm for the livestock_management quota gate.
 */
@Component
public class FarmLivestockUsageResolver implements UsageResolver {

    private final RanchQueryPort ranchQueryPort;

    public FarmLivestockUsageResolver(RanchQueryPort ranchQueryPort) {
        this.ranchQueryPort = ranchQueryPort;
    }

    @Override
    public String featureKey() {
        return "livestock_management";
    }

    @Override
    public int resolve(Long tenantId, Long farmId) {
        return ranchQueryPort.countLivestockByFarmIdAndTenantId(farmId, tenantId);
    }
}
