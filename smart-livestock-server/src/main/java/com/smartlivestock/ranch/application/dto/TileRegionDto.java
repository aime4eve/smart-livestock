package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.model.TileRegion;
import java.time.Instant;

public record TileRegionDto(
        Long id, String name,
        double minLon, double minLat, double maxLon, double maxLat,
        int minZoom, int maxZoom,
        String fileName, Long fileSize, String md5,
        Instant generatedAt, String status
) {
    public static TileRegionDto from(TileRegion r) {
        return new TileRegionDto(r.getId(), r.getName(),
                r.getMinLon(), r.getMinLat(), r.getMaxLon(), r.getMaxLat(),
                r.getMinZoom(), r.getMaxZoom(),
                r.getFileName(), r.getFileSize(), r.getMd5(),
                r.getGeneratedAt(), r.getStatus());
    }
}
