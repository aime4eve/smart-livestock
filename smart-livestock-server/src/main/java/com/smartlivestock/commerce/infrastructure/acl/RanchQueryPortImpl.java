package com.smartlivestock.commerce.infrastructure.acl;

import com.smartlivestock.commerce.domain.port.RanchQueryPort;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import org.springframework.stereotype.Component;

@Component("commerceRanchQueryPort")
public class RanchQueryPortImpl implements RanchQueryPort {

    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;

    public RanchQueryPortImpl(LivestockRepository livestockRepository, FenceRepository fenceRepository) {
        this.livestockRepository = livestockRepository;
        this.fenceRepository = fenceRepository;
    }

    @Override
    public int countLivestockByFarmIdAndTenantId(Long farmId, Long tenantId) {
        return (int) livestockRepository.countByFarmIdAndTenantId(farmId, tenantId);
    }

    @Override
    public int countFencesByFarmIdAndTenantId(Long farmId, Long tenantId) {
        return (int) fenceRepository.countByFarmIdAndTenantId(farmId, tenantId);
    }
}
