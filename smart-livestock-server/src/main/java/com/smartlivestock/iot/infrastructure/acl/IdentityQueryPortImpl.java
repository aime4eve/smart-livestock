package com.smartlivestock.iot.infrastructure.acl;

import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.iot.domain.port.IdentityQueryPort;
import com.smartlivestock.iot.domain.port.dto.FarmInfo;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component("iotIdentityQueryPort")
public class IdentityQueryPortImpl implements IdentityQueryPort {

    private final FarmRepository farmRepository;

    public IdentityQueryPortImpl(FarmRepository farmRepository) {
        this.farmRepository = farmRepository;
    }

    @Override
    public Optional<FarmInfo> findFarmById(Long farmId) {
        return farmRepository.findById(farmId)
                .map(f -> new FarmInfo(f.getId(), f.getLatitude(), f.getLongitude()));
    }
}
