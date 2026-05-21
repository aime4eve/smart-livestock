package com.smartlivestock.commerce.application.service;

import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import org.springframework.stereotype.Component;

/**
 * Counts livestock per farm for the livestock_management quota gate.
 */
@Component
public class FarmLivestockUsageResolver implements UsageResolver {

    private final LivestockRepository livestockRepository;

    public FarmLivestockUsageResolver(LivestockRepository livestockRepository) {
        this.livestockRepository = livestockRepository;
    }

    @Override
    public String featureKey() {
        return "livestock_management";
    }

    @Override
    public int resolve(Long tenantId, Long farmId) {
        return (int) livestockRepository.countByFarmIdAndTenantId(farmId, tenantId);
    }
}
