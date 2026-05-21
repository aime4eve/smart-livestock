package com.smartlivestock.commerce.application.service;

import com.smartlivestock.ranch.infrastructure.persistence.SpringDataLivestockRepository;
import org.springframework.stereotype.Component;

@Component
public class FarmLivestockUsageResolver implements UsageResolver {

    private final SpringDataLivestockRepository livestockRepository;

    public FarmLivestockUsageResolver(SpringDataLivestockRepository livestockRepository) {
        this.livestockRepository = livestockRepository;
    }

    @Override
    public String featureKey() {
        return "livestock_management";
    }

    @Override
    public int resolve(Long tenantId, Long farmId) {
        return (int) livestockRepository.countByFarmId(farmId);
    }
}
