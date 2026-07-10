package com.smartlivestock.ranch.infrastructure.acl;

import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.ranch.domain.port.dto.FarmInfo;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component("ranchIdentityQueryPort")
public class IdentityQueryPortImpl implements IdentityQueryPort {

    private final FarmRepository farmRepository;

    public IdentityQueryPortImpl(FarmRepository farmRepository) {
        this.farmRepository = farmRepository;
    }

    @Override
    public Optional<FarmInfo> findFarmById(Long farmId) {
        return farmRepository.findById(farmId)
                .map(f -> new FarmInfo(f.getId(), f.getTenantId(), f.getName(), f.getLatitude(), f.getLongitude()));
    }
}
