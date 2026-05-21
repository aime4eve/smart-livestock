package com.smartlivestock.commerce.application.service;

import com.smartlivestock.ranch.domain.repository.FenceRepository;
import org.springframework.stereotype.Component;

@Component
public class FarmFenceUsageResolver implements UsageResolver {

    private final FenceRepository fenceRepository;

    public FarmFenceUsageResolver(FenceRepository fenceRepository) {
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
