package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;

import java.util.List;

public record FenceDto(
        Long id,
        Long farmId,
        String name,
        List<GpsCoordinate> vertices,
        String color,
        boolean active
) {
    public static FenceDto from(Fence fence) {
        return new FenceDto(
                fence.getId(),
                fence.getFarmId(),
                fence.getName(),
                fence.getVertices(),
                fence.getColor(),
                fence.isActive()
        );
    }
}
