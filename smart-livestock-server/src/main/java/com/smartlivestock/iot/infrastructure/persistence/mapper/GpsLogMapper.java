package com.smartlivestock.iot.infrastructure.persistence.mapper;

import com.smartlivestock.iot.domain.model.GpsLog;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsLogJpaEntity;

public final class GpsLogMapper {

    private GpsLogMapper() {}

    public static GpsLogJpaEntity toJpaEntity(GpsLog gpsLog) {
        GpsLogJpaEntity jpa = new GpsLogJpaEntity();
        jpa.setId(gpsLog.getId());
        jpa.setDeviceId(gpsLog.getDeviceId());
        jpa.setLatitude(gpsLog.getLatitude());
        jpa.setLongitude(gpsLog.getLongitude());
        jpa.setAccuracy(gpsLog.getAccuracy());
        jpa.setRecordedAt(gpsLog.getRecordedAt());
        return jpa;
    }

    public static GpsLog toDomain(GpsLogJpaEntity jpa) {
        GpsLog gpsLog = new GpsLog();
        gpsLog.setId(jpa.getId());
        gpsLog.setDeviceId(jpa.getDeviceId());
        gpsLog.setLatitude(jpa.getLatitude());
        gpsLog.setLongitude(jpa.getLongitude());
        gpsLog.setAccuracy(jpa.getAccuracy());
        gpsLog.setRecordedAt(jpa.getRecordedAt());
        return gpsLog;
    }
}
