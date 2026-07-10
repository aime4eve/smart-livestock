package com.smartlivestock.iot.application.dto;

import com.smartlivestock.iot.domain.model.GpsLog;

import java.math.BigDecimal;
import java.time.Instant;

public record GpsLogDto(
        Long id,
        Long deviceId,
        BigDecimal latitude,
        BigDecimal longitude,
        BigDecimal accuracy,
        Instant recordedAt
) {
    public static GpsLogDto from(GpsLog gpsLog) {
        return new GpsLogDto(
                gpsLog.getId(),
                gpsLog.getDeviceId(),
                gpsLog.getLatitude(),
                gpsLog.getLongitude(),
                gpsLog.getAccuracy(),
                gpsLog.getRecordedAt()
        );
    }
}
