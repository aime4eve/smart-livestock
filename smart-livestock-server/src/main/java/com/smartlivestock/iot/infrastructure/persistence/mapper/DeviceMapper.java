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
        jpa.setLastOnlineAt(device.getLastOnlineAt());
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
        device.reconstituteLastOnlineAt(jpa.getLastOnlineAt());
        return device;
    }
}
