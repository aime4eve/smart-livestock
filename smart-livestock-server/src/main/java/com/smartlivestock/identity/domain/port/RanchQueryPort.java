package com.smartlivestock.identity.domain.port;

import com.smartlivestock.identity.domain.port.dto.LivestockDto;
import com.smartlivestock.identity.domain.port.dto.AlertDto;

import java.util.List;

public interface RanchQueryPort {
    List<LivestockDto> findLivestockByFarmId(Long farmId);
    List<AlertDto> findAlertsByFarmId(Long farmId);
}
