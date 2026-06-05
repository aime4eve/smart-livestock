package com.smartlivestock.iot.domain.port;

import com.smartlivestock.iot.domain.port.dto.FenceInfo;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;

import java.util.List;
import java.util.Optional;

/**
 * ACL query port for IoT context to read Ranch context data.
 * Implementation in infrastructure/acl/ layer calls Ranch repositories.
 */
public interface RanchQueryPort {
    Optional<LivestockInfo> findLivestockById(Long livestockId);
    List<LivestockInfo> findAllByFarmId(Long farmId);
    List<FenceInfo> findFencesByFarmId(Long farmId);
}
