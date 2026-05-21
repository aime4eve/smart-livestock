package com.smartlivestock.commerce.application.service;

import com.smartlivestock.ranch.infrastructure.persistence.SpringDataFenceRepository;
import org.springframework.stereotype.Component;

@Component
public class FarmFenceUsageResolver implements UsageResolver {

    private final SpringDataFenceRepository fenceRepository;

    public FarmFenceUsageResolver(SpringDataFenceRepository fenceRepository) {
        this.fenceRepository = fenceRepository;
    }

    @Override
    public String featureKey() {
        return "fence_management";
    }

    @Override
    public int resolve(Long tenantId, Long farmId) {
        return (int) fenceRepository.countByFarmId(farmId);
    }
}
