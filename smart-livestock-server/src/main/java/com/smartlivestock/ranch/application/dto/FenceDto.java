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
        boolean active,
        int version,
        String fenceType,
        int livestockCount
) {
    public static FenceDto from(Fence fence) {
        return from(fence, 0);
    }

    /**
     * @param livestockCount livestock with a GPS fix currently inside the fence
     *                       (computed by the caller for list endpoints; 0 for
     *                       single-fence mutations)
     */
    public static FenceDto from(Fence fence, int livestockCount) {
        return new FenceDto(
                fence.getId(),
                fence.getFarmId(),
                fence.getName(),
                fence.getVertices(),
                fence.getColor(),
                fence.isActive(),
                fence.getVersion(),
                fence.getFenceType(),
                livestockCount
        );
    }
}
