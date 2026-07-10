package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.port.FenceQueryPort;
import com.smartlivestock.datagen.domain.port.dto.CoordinateInfo;
import com.smartlivestock.datagen.domain.port.dto.FenceGeometryInfo;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class FenceQueryPortImpl implements FenceQueryPort {
    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;

    @Override
    public List<FenceGeometryInfo> findActiveFencesByLivestockId(Long livestockId) {
        Livestock livestock = livestockRepository.findById(livestockId).orElse(null);
        if (livestock == null) return List.of();

        Long farmId = livestock.getFarmId();
        List<Fence> fences = fenceRepository.findByFarmId(farmId);

        return fences.stream()
                .filter(Fence::isActive)
                .filter(f -> f.getVertices() != null && f.getVertices().size() >= 3)
                .map(f -> new FenceGeometryInfo(
                        f.getId(), farmId, f.getName(),
                        f.getVertices().stream()
                                .map(v -> new CoordinateInfo(
                                        v.latitude().doubleValue(),
                                        v.longitude().doubleValue()))
                                .toList()
                )).toList();
    }
}
