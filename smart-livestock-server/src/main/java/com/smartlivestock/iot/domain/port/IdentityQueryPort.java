package com.smartlivestock.iot.domain.port;

import com.smartlivestock.iot.domain.port.dto.FarmInfo;

import java.util.Optional;

/**
 * ACL query port for IoT context to read Identity context data.
 */
public interface IdentityQueryPort {
    Optional<FarmInfo> findFarmById(Long farmId);
}
