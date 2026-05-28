package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.command.CreateFenceCommand;
import com.smartlivestock.ranch.application.command.UpdateFenceCommand;
import com.smartlivestock.ranch.application.dto.FenceDto;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FenceApplicationService {

    private final FenceRepository fenceRepository;

    @Transactional
    public FenceDto createFence(CreateFenceCommand command) {
        Fence fence = new Fence(command.farmId(), command.name(), command.vertices(), command.color());
        if (command.fenceType() != null) {
            fence.setFenceType(command.fenceType());
        }
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
        fence.setVersion(fence.getVersion() + 1);
        Fence saved = fenceRepository.save(fence);
        return FenceDto.from(saved);
    }

    @Transactional
    public FenceDto forceUpdateFence(Long id, List<GpsCoordinate> vertices,
                                      String name, String color, int version) {
        Fence fence = fenceRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "围栏不存在: " + id));
        fence.setName(name);
        fence.setVertices(vertices);
        fence.setColor(color);
        fence.setVersion(version + 1);
        Fence saved = fenceRepository.save(fence);
        return FenceDto.from(saved);
    }

    @Transactional
    public void deleteFence(Long id) {
        if (fenceRepository.findById(id).isEmpty()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "围栏不存在: " + id);
        }
        fenceRepository.deleteById(id);
    }
}
