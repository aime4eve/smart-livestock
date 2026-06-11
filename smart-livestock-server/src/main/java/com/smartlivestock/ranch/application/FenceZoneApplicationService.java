package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.FenceZoneDto;
import com.smartlivestock.ranch.domain.model.FenceZone;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.repository.FenceZoneRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FenceZoneApplicationService {

    private final FenceZoneRepository fenceZoneRepository;

    @Transactional(readOnly = true)
    public List<FenceZoneDto> listByFarm(Long farmId) {
        return fenceZoneRepository.findByFarmId(farmId).stream()
                .map(FenceZoneDto::from)
                .toList();
    }

    @Transactional
    public FenceZoneDto create(Long farmId, Long fenceId, String name, String zoneType,
                               List<GpsCoordinate> vertices, int alertRadius, String severity) {
        FenceZone zone = new FenceZone(fenceId, farmId, name, zoneType, vertices, alertRadius, severity);
        FenceZone saved = fenceZoneRepository.save(zone);
        return FenceZoneDto.from(saved);
    }
}
