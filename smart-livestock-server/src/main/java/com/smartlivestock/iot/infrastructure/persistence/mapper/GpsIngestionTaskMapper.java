package com.smartlivestock.iot.infrastructure.persistence.mapper;

import com.smartlivestock.iot.domain.model.GpsIngestionTask;
import com.smartlivestock.iot.domain.model.GpsIngestionTaskStatus;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsIngestionTaskJpaEntity;

public final class GpsIngestionTaskMapper {
    private GpsIngestionTaskMapper() {}

    public static GpsIngestionTaskJpaEntity toJpa(GpsIngestionTask task) {
        GpsIngestionTaskJpaEntity jpa = new GpsIngestionTaskJpaEntity();
        jpa.setId(task.getId());
        jpa.setDeviceId(task.getDeviceId());
        jpa.setLatitude(task.getLatitude());
        jpa.setLongitude(task.getLongitude());
        jpa.setAccuracy(task.getAccuracy());
        jpa.setRecordedAt(task.getRecordedAt());
        jpa.setSource(task.getSource() != null ? task.getSource().name() : TelemetrySource.HTTP.name());
        jpa.setStatus(task.getStatus() != null ? task.getStatus().name() : GpsIngestionTaskStatus.PENDING.name());
        jpa.setAttempts(task.getAttempts());
        jpa.setNextAttemptAt(task.getNextAttemptAt());
        jpa.setLastError(task.getLastError());
        jpa.setCreatedAt(task.getCreatedAt());
        jpa.setUpdatedAt(task.getUpdatedAt());
        return jpa;
    }

    public static GpsIngestionTask toDomain(GpsIngestionTaskJpaEntity jpa) {
        GpsIngestionTask task = new GpsIngestionTask();
        task.setId(jpa.getId());
        task.setDeviceId(jpa.getDeviceId());
        task.setLatitude(jpa.getLatitude());
        task.setLongitude(jpa.getLongitude());
        task.setAccuracy(jpa.getAccuracy());
        task.setRecordedAt(jpa.getRecordedAt());
        task.setSource(TelemetrySource.valueOf(jpa.getSource()));
        task.setStatus(GpsIngestionTaskStatus.valueOf(jpa.getStatus()));
        task.setAttempts(jpa.getAttempts());
        task.setNextAttemptAt(jpa.getNextAttemptAt());
        task.setLastError(jpa.getLastError());
        task.setCreatedAt(jpa.getCreatedAt());
        task.setUpdatedAt(jpa.getUpdatedAt());
        return task;
    }
}
