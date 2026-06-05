package com.smartlivestock.identity.infrastructure.acl;

import com.smartlivestock.identity.domain.port.RanchQueryPort;
import com.smartlivestock.identity.domain.port.dto.AlertDto;
import com.smartlivestock.identity.domain.port.dto.LivestockDto;
import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.LivestockApplicationService;
import org.springframework.stereotype.Component;

import java.util.List;

@Component("identityRanchQueryPort")
public class RanchQueryPortImpl implements RanchQueryPort {

    private final LivestockApplicationService livestockApplicationService;
    private final AlertApplicationService alertApplicationService;

    public RanchQueryPortImpl(LivestockApplicationService livestockApplicationService,
                               AlertApplicationService alertApplicationService) {
        this.livestockApplicationService = livestockApplicationService;
        this.alertApplicationService = alertApplicationService;
    }

    @Override
    public List<LivestockDto> findLivestockByFarmId(Long farmId) {
        return livestockApplicationService.listByFarm(farmId).stream()
                .map(this::toIdentityLivestockDto)
                .toList();
    }

    @Override
    public List<AlertDto> findAlertsByFarmId(Long farmId) {
        return alertApplicationService.listByFarm(farmId).stream()
                .map(this::toIdentityAlertDto)
                .toList();
    }

    private LivestockDto toIdentityLivestockDto(com.smartlivestock.ranch.application.dto.LivestockDto l) {
        return new LivestockDto(l.id(), l.farmId(), l.livestockCode(), l.breed(), l.gender(), l.healthStatus());
    }

    private AlertDto toIdentityAlertDto(com.smartlivestock.ranch.application.dto.AlertDto a) {
        return new AlertDto(a.id(), a.farmId(), a.livestockId(), a.type(), a.severity(), a.status(), a.message());
    }
}
