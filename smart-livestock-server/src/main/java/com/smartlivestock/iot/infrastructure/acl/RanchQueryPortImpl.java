package com.smartlivestock.iot.infrastructure.acl;

import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.CoordinateInfo;
import com.smartlivestock.iot.domain.port.dto.FenceInfo;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * ACL implementation: IoT context querying Ranch context data.
 * Lives in infrastructure layer - allowed to import Ranch repositories.
 */
@Component("iotRanchQueryPort")
public class RanchQueryPortImpl implements RanchQueryPort {

    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;

    public RanchQueryPortImpl(LivestockRepository livestockRepository, FenceRepository fenceRepository) {
        this.livestockRepository = livestockRepository;
        this.fenceRepository = fenceRepository;
    }

    @Override
    public Optional<LivestockInfo> findLivestockById(Long livestockId) {
        return livestockRepository.findById(livestockId)
                .map(this::toLivestockInfo);
    }

    @Override
    public List<LivestockInfo> findAllByFarmId(Long farmId) {
        return livestockRepository.findByFarmId(farmId).stream()
                .map(this::toLivestockInfo)
                .toList();
    }

    @Override
    public List<FenceInfo> findFencesByFarmId(Long farmId) {
        return fenceRepository.findByFarmId(farmId).stream()
                .map(this::toFenceInfo)
                .toList();
    }

    private LivestockInfo toLivestockInfo(Livestock livestock) {
        return new LivestockInfo(
                livestock.getId(),
                livestock.getFarmId(),
                livestock.getLivestockCode(),
                livestock.getGender()
        );
    }

    private FenceInfo toFenceInfo(Fence fence) {
        List<CoordinateInfo> coords = fence.getVertices().stream()
                .map(v -> new CoordinateInfo(v.latitude(), v.longitude()))
                .toList();
        return new FenceInfo(fence.getId(), fence.getName(), coords);
    }
}
