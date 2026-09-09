package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.command.CreateFenceCommand;
import com.smartlivestock.ranch.application.command.UpdateFenceCommand;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.FenceZoneRepository;
import com.smartlivestock.ranch.domain.service.BufferPolygonCalculator;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
public class FenceApplicationService {

    private final FenceRepository fenceRepository;
    private final AlertRepository alertRepository;
    private final FenceZoneRepository fenceZoneRepository;
    private final BufferPolygonCalculator bufferPolygonCalculator;

    @Transactional
    public FenceDto createFence(CreateFenceCommand command) {
        Fence fence = new Fence(command.farmId(), command.name(), command.vertices(), command.color());
        if (command.fenceType() != null) {
            fence.setFenceType(command.fenceType());
        }
        computeBufferPolygon(fence);
        Fence saved = fenceRepository.save(fence);
        return FenceDto.from(saved);
    }

    @Transactional(readOnly = true)
    public FenceDto getFence(Long id) {
        Fence fence = fenceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "围栏不存在: " + id));
        return FenceDto.from(fence);
    }

    @Transactional(readOnly = true)
    public List<FenceDto> listByFarm(Long farmId) {
        return fenceRepository.findByFarmId(farmId).stream()
                .map(FenceDto::from)
                .toList();
    }

    @Transactional
    public FenceDto updateFence(Long id, UpdateFenceCommand command) {
        Fence fence = fenceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "围栏不存在: " + id));

        if (command.expectedVersion() != null && fence.getVersion() != command.expectedVersion()) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    String.format("版本冲突: 期望 %d, 实际 %d", command.expectedVersion(), fence.getVersion()));
        }

        fence.setName(command.name());
        fence.setVertices(command.vertices());
        fence.setColor(command.color());
        computeBufferPolygon(fence);
        try {
            Fence saved = fenceRepository.save(fence);
            return FenceDto.from(saved);
        } catch (ObjectOptimisticLockingFailureException e) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    String.format("版本冲突: 围栏已被其他人修改，请刷新后重试"));
        }
    }

    @Transactional
    public FenceDto forceUpdateFence(Long id, List<GpsCoordinate> vertices,
                                      String name, String color, int version) {
        Fence fence = fenceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "围栏不存在: " + id));
        fence.setName(name);
        fence.setVertices(vertices);
        fence.setColor(color);
        computeBufferPolygon(fence);
        try {
            Fence saved = fenceRepository.save(fence);
            return FenceDto.from(saved);
        } catch (ObjectOptimisticLockingFailureException e) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                    String.format("版本冲突: 围栏已被其他人修改，请刷新后重试"));
        }
    }

    /**
     * Deletes a fence together with its zones. Alerts referencing the fence
     * would violate the FK constraint, so the caller decides their fate:
     * delete them along with the fence, or keep the rows and just detach
     * them (alerts.fence_id = NULL; rendered text carries the fence name
     * snapshot, so display is unaffected).
     *
     * @return number of alerts removed when {@code deleteAlerts} is true
     */
    @Transactional
    public int deleteFence(Long id, boolean deleteAlerts) {
        if (fenceRepository.findById(id).isEmpty()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "围栏不存在: " + id);
        }
        int deletedAlerts = 0;
        if (deleteAlerts) {
            alertRepository.deleteReadStatusByFenceId(id);
            deletedAlerts = alertRepository.deleteByFenceId(id);
        } else {
            alertRepository.clearFenceReference(id);
        }
        fenceZoneRepository.deleteByFenceId(id);
        fenceRepository.deleteById(id);
        return deletedAlerts;
    }

    /**
     * Pre-compute buffer polygon for the fence using JTS.
     * Uses the first vertex latitude as reference for metric projection.
     */
    private void computeBufferPolygon(Fence fence) {
        if (fence.getVertices() == null || fence.getVertices().size() < 3) return;
        BigDecimal refLat = fence.getVertices().get(0).latitude();
        List<GpsCoordinate> buffer = bufferPolygonCalculator.computeBuffer(
                fence.getVertices(), fence.getBufferDistance(), refLat);
        fence.setBufferPolygon(buffer);
    }
}
