package com.smartlivestock.datagen.domain.port.dto;

import com.smartlivestock.iot.domain.model.DeviceType;

public record ActiveInstallationInfo(Long deviceId, Long livestockId, DeviceType deviceType,
                                     Double latitude, Double longitude) {
    // Backward-compat for callers without coordinates
    public ActiveInstallationInfo(Long deviceId, Long livestockId, DeviceType deviceType) {
        this(deviceId, livestockId, deviceType, null, null);
    }
}
