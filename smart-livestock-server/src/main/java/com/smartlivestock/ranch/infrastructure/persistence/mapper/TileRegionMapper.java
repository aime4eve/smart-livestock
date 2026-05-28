package com.smartlivestock.ranch.infrastructure.persistence.mapper;

import com.smartlivestock.ranch.domain.model.TileRegion;
import com.smartlivestock.ranch.infrastructure.persistence.entity.TileRegionJpaEntity;

public final class TileRegionMapper {
    private TileRegionMapper() {}

    public static TileRegionJpaEntity toJpaEntity(TileRegion r) {
        TileRegionJpaEntity jpa = new TileRegionJpaEntity();
        jpa.setId(r.getId());
        jpa.setName(r.getName());
        jpa.setMinLon(r.getMinLon()); jpa.setMinLat(r.getMinLat());
        jpa.setMaxLon(r.getMaxLon()); jpa.setMaxLat(r.getMaxLat());
        jpa.setMinZoom(r.getMinZoom()); jpa.setMaxZoom(r.getMaxZoom());
        jpa.setFileName(r.getFileName()); jpa.setFileSize(r.getFileSize());
        jpa.setMd5(r.getMd5()); jpa.setGeneratedAt(r.getGeneratedAt());
        jpa.setStatus(r.getStatus());
        return jpa;
    }

    public static TileRegion toDomain(TileRegionJpaEntity jpa) {
        TileRegion r = new TileRegion();
        r.setId(jpa.getId());
        r.setName(jpa.getName());
        r.setMinLon(jpa.getMinLon()); r.setMinLat(jpa.getMinLat());
        r.setMaxLon(jpa.getMaxLon()); r.setMaxLat(jpa.getMaxLat());
        r.setMinZoom(jpa.getMinZoom()); r.setMaxZoom(jpa.getMaxZoom());
        r.setFileName(jpa.getFileName()); r.setFileSize(jpa.getFileSize());
        r.setMd5(jpa.getMd5()); r.setGeneratedAt(jpa.getGeneratedAt());
        r.setStatus(jpa.getStatus());
        return r;
    }
}
