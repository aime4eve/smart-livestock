package com.smartlivestock.ranch.application.dto;

import java.util.List;

public record FarmTileStatusDto(
        Long farmId,
        List<RegionStatus> regions,
        double coverageRatio,
        boolean coverageWarning
) {
    public record RegionStatus(
            Long regionId, String regionName,
            String status, Long fileSize,
            String fileName, String md5
    ) {}
}
