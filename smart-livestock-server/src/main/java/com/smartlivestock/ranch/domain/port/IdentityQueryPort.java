package com.smartlivestock.ranch.domain.port;

import com.smartlivestock.ranch.domain.port.dto.FarmInfo;

import java.util.Optional;

public interface IdentityQueryPort {
    Optional<FarmInfo> findFarmById(Long farmId);
}
