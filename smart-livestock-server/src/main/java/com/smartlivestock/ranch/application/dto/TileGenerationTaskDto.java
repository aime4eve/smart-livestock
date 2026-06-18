package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.model.TileGenerationTask;
import java.time.Instant;

public record TileGenerationTaskDto(
        Long id, Long regionId, String regionName,
        double minLon, double minLat, double maxLon, double maxLat,
        int minZoom, int maxZoom,
        String status, String triggeredBy,
        Integer tileCount, Double fileSizeMb,
        Double coverageRatio, boolean customRegion,
        String errorMessage, String progress,
        Instant startedAt, Instant finishedAt, Instant createdAt
) {
    public static TileGenerationTaskDto from(TileGenerationTask t) {
        return new TileGenerationTaskDto(t.getId(), t.getRegionId(), t.getRegionName(),
                t.getMinLon(), t.getMinLat(), t.getMaxLon(), t.getMaxLat(),
                t.getMinZoom(), t.getMaxZoom(),
                t.getStatus(), t.getTriggeredBy(),
                t.getTileCount(), t.getFileSizeMb(),
                t.getCoverageRatio(), t.isCustomRegion(),
                t.getErrorMessage(), t.getProgress(),
                t.getStartedAt(), t.getFinishedAt(), null);
    }
}
