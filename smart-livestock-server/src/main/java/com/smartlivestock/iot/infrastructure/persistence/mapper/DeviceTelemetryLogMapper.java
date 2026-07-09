package com.smartlivestock.iot.infrastructure.persistence.mapper;

import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;
import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceTelemetryLogJpaEntity;

public final class DeviceTelemetryLogMapper {

    private DeviceTelemetryLogMapper() {}

    public static DeviceTelemetryLogJpaEntity toJpaEntity(DeviceTelemetryLog log) {
        DeviceTelemetryLogJpaEntity jpa = new DeviceTelemetryLogJpaEntity();
        jpa.setId(log.getId());
        jpa.setDeviceId(log.getDeviceId());
        jpa.setTenantId(log.getTenantId());
        jpa.setBatteryLevel(log.getBatteryLevel());
        jpa.setRssi(log.getRssi());
        jpa.setSnr(log.getSnr());
        jpa.setGatewayId(log.getGatewayId());
        jpa.setAntiDisassemblyStatus(log.getAntiDisassemblyStatus());
        jpa.setStepNumber(log.getStepNumber());
        jpa.setLatitude(log.getLatitude());
        jpa.setLongitude(log.getLongitude());
        jpa.setAccelXRaw(log.getAccelXRaw());
        jpa.setAccelYRaw(log.getAccelYRaw());
        jpa.setAccelZRaw(log.getAccelZRaw());
        jpa.setAccelXG(log.getAccelXG());
        jpa.setAccelYG(log.getAccelYG());
        jpa.setAccelZG(log.getAccelZG());
        jpa.setAccelMagnitudeG(log.getAccelMagnitudeG());
        jpa.setMotionIntensity(log.getMotionIntensity());
        jpa.setActivityClass(log.getActivityClass());
        jpa.setRollDegrees(log.getRollDegrees());
        jpa.setPitchDegrees(log.getPitchDegrees());
        jpa.setReportTime(log.getReportTime());
        return jpa;
    }

    public static DeviceTelemetryLog toDomain(DeviceTelemetryLogJpaEntity jpa) {
        DeviceTelemetryLog log = new DeviceTelemetryLog();
        log.setId(jpa.getId());
        log.setDeviceId(jpa.getDeviceId());
        log.setTenantId(jpa.getTenantId());
        log.setBatteryLevel(jpa.getBatteryLevel());
        log.setRssi(jpa.getRssi());
        log.setSnr(jpa.getSnr());
        log.setGatewayId(jpa.getGatewayId());
        log.setAntiDisassemblyStatus(jpa.getAntiDisassemblyStatus());
        log.setStepNumber(jpa.getStepNumber());
        log.setLatitude(jpa.getLatitude());
        log.setLongitude(jpa.getLongitude());
        log.setAccelXRaw(jpa.getAccelXRaw());
        log.setAccelYRaw(jpa.getAccelYRaw());
        log.setAccelZRaw(jpa.getAccelZRaw());
        log.setAccelXG(jpa.getAccelXG());
        log.setAccelYG(jpa.getAccelYG());
        log.setAccelZG(jpa.getAccelZG());
        log.setAccelMagnitudeG(jpa.getAccelMagnitudeG());
        log.setMotionIntensity(jpa.getMotionIntensity());
        log.setActivityClass(jpa.getActivityClass());
        log.setRollDegrees(jpa.getRollDegrees());
        log.setPitchDegrees(jpa.getPitchDegrees());
        log.setReportTime(jpa.getReportTime());
        log.setCreatedAt(jpa.getCreatedAt());
        return log;
    }
}
