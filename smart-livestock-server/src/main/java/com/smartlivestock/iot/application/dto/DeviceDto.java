package com.smartlivestock.iot.application.dto;

import com.smartlivestock.iot.domain.model.Device;

import java.math.BigDecimal;
import java.time.Instant;

public record DeviceDto(
        Long id,
        Long tenantId,
        String deviceCode,
        String deviceType,
        String status,
        String runtimeStatus,
        Integer batteryLevel,
        String firmwareVersion,
        String devEui,
        Instant lastOnlineAt,
        Long platformDeviceId,
        Integer rssi,
        BigDecimal snr,
        String lastGateway,
        Integer antiDisassemblyStatus,
        String softwareVersion,
        String hardwareVersion,
        String workMode,
        Instant lastTelemetrySyncedAt
) {
    public static DeviceDto from(Device device) {
        return new DeviceDto(
                device.getId(),
                device.getTenantId(),
                device.getDeviceCode(),
                device.getDeviceType().name(),
                device.getStatus().name(),
                device.getRuntimeStatus(),
                device.getBatteryLevel(),
                device.getFirmwareVersion(),
                device.getDevEui(),
                device.getLastOnlineAt(),
                device.getPlatformDeviceId(),
                device.getRssi(),
                device.getSnr(),
                device.getLastGateway(),
                device.getAntiDisassemblyStatus(),
                device.getSoftwareVersion(),
                device.getHardwareVersion(),
                device.getWorkMode(),
                device.getLastTelemetrySyncedAt()
        );
    }
}
