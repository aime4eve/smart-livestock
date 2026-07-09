package com.smartlivestock.iot.infrastructure.persistence.mapper;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceJpaEntity;

public final class DeviceMapper {

    private DeviceMapper() {}

    public static DeviceJpaEntity toJpaEntity(Device device) {
        DeviceJpaEntity jpa = new DeviceJpaEntity();
        jpa.setId(device.getId());
        jpa.setTenantId(device.getTenantId());
        jpa.setDeviceCode(device.getDeviceCode());
        jpa.setDeviceType(device.getDeviceType().name());
        jpa.setStatus(device.getStatus().name());
        jpa.setBatteryLevel(device.getBatteryLevel());
        jpa.setFirmwareVersion(device.getFirmwareVersion());
       jpa.setDevEui(device.getDevEui());
       jpa.setRuntimeStatus(device.getRuntimeStatus());
       jpa.setLastOnlineAt(device.getLastOnlineAt());
       jpa.setPlatformDeviceId(device.getPlatformDeviceId());
       jpa.setRssi(device.getRssi());
       jpa.setSnr(device.getSnr());
       jpa.setLastGateway(device.getLastGateway());
       jpa.setAntiDisassemblyStatus(device.getAntiDisassemblyStatus());
       jpa.setSoftwareVersion(device.getSoftwareVersion());
       jpa.setHardwareVersion(device.getHardwareVersion());
       jpa.setWorkMode(device.getWorkMode());
       jpa.setLastTelemetrySyncedAt(device.getLastTelemetrySyncedAt());
       return jpa;
    }

    public static Device toDomain(DeviceJpaEntity jpa) {
        Device device = new Device();
        device.setId(jpa.getId());
        device.setTenantId(jpa.getTenantId());
        device.setDeviceCode(jpa.getDeviceCode());
        device.setDeviceType(DeviceType.valueOf(jpa.getDeviceType()));
        device.setStatus(DeviceStatus.valueOf(jpa.getStatus()));
        device.setBatteryLevel(jpa.getBatteryLevel());
        device.setFirmwareVersion(jpa.getFirmwareVersion());
       device.setDevEui(jpa.getDevEui());
       device.setRuntimeStatus(jpa.getRuntimeStatus());
       device.reconstituteLastOnlineAt(jpa.getLastOnlineAt());
        device.setPlatformDeviceId(jpa.getPlatformDeviceId());
        device.setRssi(jpa.getRssi());
        device.setSnr(jpa.getSnr());
        device.setLastGateway(jpa.getLastGateway());
        device.setAntiDisassemblyStatus(jpa.getAntiDisassemblyStatus());
        device.setSoftwareVersion(jpa.getSoftwareVersion());
        device.setHardwareVersion(jpa.getHardwareVersion());
        device.setWorkMode(jpa.getWorkMode());
        device.setLastTelemetrySyncedAt(jpa.getLastTelemetrySyncedAt());
        return device;
    }
}
