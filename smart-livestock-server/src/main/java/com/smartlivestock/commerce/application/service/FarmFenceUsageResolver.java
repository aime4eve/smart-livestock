package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.port.RanchQueryPort;
import org.springframework.stereotype.Component;

/**
 * Counts fences per farm for the fence_management quota gate.
 */
@Component
public class FarmFenceUsageResolver implements UsageResolver {

    private final RanchQueryPort ranchQueryPort;

    public FarmFenceUsageResolver(RanchQueryPort ranchQueryPort) {
        this.ranchQueryPort = ranchQueryPort;
    }

    @Override
    public String featureKey() {
        return "fence_management";
    }

    @Override
    public int resolve(Long tenantId, Long farmId) {
        return ranchQueryPort.countFencesByFarmIdAndTenantId(farmId, tenantId);
    }
}
