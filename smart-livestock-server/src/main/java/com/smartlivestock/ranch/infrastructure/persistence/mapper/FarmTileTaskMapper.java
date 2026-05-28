package com.smartlivestock.ranch.infrastructure.persistence.mapper;

import com.smartlivestock.ranch.domain.model.FarmTileTask;
import com.smartlivestock.ranch.infrastructure.persistence.entity.FarmTileTaskJpaEntity;

public final class FarmTileTaskMapper {
    private FarmTileTaskMapper() {}

    public static FarmTileTaskJpaEntity toJpaEntity(FarmTileTask t) {
        FarmTileTaskJpaEntity jpa = new FarmTileTaskJpaEntity();
        jpa.setId(t.getId());
        jpa.setFarmId(t.getFarmId()); jpa.setRegionId(t.getRegionId());
        jpa.setStatus(t.getStatus()); jpa.setFileSize(t.getFileSize());
        jpa.setRequestedAt(t.getRequestedAt()); jpa.setCompletedAt(t.getCompletedAt());
        return jpa;
    }

    public static FarmTileTask toDomain(FarmTileTaskJpaEntity jpa) {
        FarmTileTask t = new FarmTileTask();
        t.setId(jpa.getId());
        t.setFarmId(jpa.getFarmId()); t.setRegionId(jpa.getRegionId());
        t.setStatus(jpa.getStatus()); t.setFileSize(jpa.getFileSize());
        t.setRequestedAt(jpa.getRequestedAt()); t.setCompletedAt(jpa.getCompletedAt());
        return t;
    }
}
