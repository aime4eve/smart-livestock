package com.smartlivestock.ranch.infrastructure.persistence.mapper;

import com.smartlivestock.ranch.domain.model.TileGenerationTask;
import com.smartlivestock.ranch.infrastructure.persistence.entity.TileGenerationTaskJpaEntity;

public final class TileGenerationTaskMapper {
    private TileGenerationTaskMapper() {}

    public static TileGenerationTaskJpaEntity toJpaEntity(TileGenerationTask t) {
        TileGenerationTaskJpaEntity jpa = new TileGenerationTaskJpaEntity();
        jpa.setId(t.getId());
        jpa.setRegionId(t.getRegionId());
        jpa.setMinLon(t.getMinLon()); jpa.setMinLat(t.getMinLat());
        jpa.setMaxLon(t.getMaxLon()); jpa.setMaxLat(t.getMaxLat());
        jpa.setMinZoom(t.getMinZoom()); jpa.setMaxZoom(t.getMaxZoom());
        jpa.setRegionName(t.getRegionName());
        jpa.setStatus(t.getStatus()); jpa.setTriggeredBy(t.getTriggeredBy());
        jpa.setTileCount(t.getTileCount()); jpa.setFileSizeMb(t.getFileSizeMb());
        jpa.setErrorMessage(t.getErrorMessage());
        jpa.setCoverageRatio(t.getCoverageRatio()); jpa.setCustomRegion(t.isCustomRegion());
        jpa.setStartedAt(t.getStartedAt()); jpa.setFinishedAt(t.getFinishedAt());
        return jpa;
    }

    public static TileGenerationTask toDomain(TileGenerationTaskJpaEntity jpa) {
        TileGenerationTask t = new TileGenerationTask();
        t.setId(jpa.getId());
        t.setRegionId(jpa.getRegionId());
        t.setMinLon(jpa.getMinLon()); t.setMinLat(jpa.getMinLat());
        t.setMaxLon(jpa.getMaxLon()); t.setMaxLat(jpa.getMaxLat());
        t.setMinZoom(jpa.getMinZoom()); t.setMaxZoom(jpa.getMaxZoom());
        t.setRegionName(jpa.getRegionName());
        t.setStatus(jpa.getStatus()); t.setTriggeredBy(jpa.getTriggeredBy());
        t.setTileCount(jpa.getTileCount()); t.setFileSizeMb(jpa.getFileSizeMb());
        t.setErrorMessage(jpa.getErrorMessage());
        t.setCoverageRatio(jpa.getCoverageRatio()); t.setCustomRegion(jpa.isCustomRegion());
        t.setStartedAt(jpa.getStartedAt()); t.setFinishedAt(jpa.getFinishedAt());
        return t;
    }
}
