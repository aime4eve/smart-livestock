package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.model.FenceZone;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;

import java.util.List;

public record FenceZoneDto(
        Long id,
        Long fenceId,
        Long farmId,
        String name,
        String zoneType,
        List<GpsCoordinate> vertices,
        int alertRadius,
        String severity,
        boolean active
) {
    public static FenceZoneDto from(FenceZone zone) {
        return new FenceZoneDto(
                zone.getId(),
                zone.getFenceId(),
                zone.getFarmId(),
                zone.getName(),
                zone.getZoneType(),
                zone.getVertices(),
                zone.getAlertRadius(),
                zone.getSeverity(),
                zone.isActive()
        );
    }
}
