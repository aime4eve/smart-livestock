package com.smartlivestock.ranch.infrastructure.persistence.mapper;

import com.smartlivestock.ranch.domain.model.TileDownloadLog;
import com.smartlivestock.ranch.infrastructure.persistence.entity.TileDownloadLogJpaEntity;

public final class TileDownloadLogMapper {
    private TileDownloadLogMapper() {}

    public static TileDownloadLogJpaEntity toJpaEntity(TileDownloadLog l) {
        TileDownloadLogJpaEntity jpa = new TileDownloadLogJpaEntity();
        jpa.setId(l.getId());
        jpa.setFarmTileTaskId(l.getFarmTileTaskId()); jpa.setUserId(l.getUserId());
        jpa.setDeviceInfo(l.getDeviceInfo()); jpa.setBytesDownloaded(l.getBytesDownloaded());
        jpa.setStartedAt(l.getStartedAt()); jpa.setFinishedAt(l.getFinishedAt());
        return jpa;
    }

    public static TileDownloadLog toDomain(TileDownloadLogJpaEntity jpa) {
        TileDownloadLog l = new TileDownloadLog();
        l.setId(jpa.getId());
        l.setFarmTileTaskId(jpa.getFarmTileTaskId()); l.setUserId(jpa.getUserId());
        l.setDeviceInfo(jpa.getDeviceInfo()); l.setBytesDownloaded(jpa.getBytesDownloaded());
        l.setStartedAt(jpa.getStartedAt()); l.setFinishedAt(jpa.getFinishedAt());
        return l;
    }
}
