package com.smartlivestock.datagen.domain.port.dto;

import com.smartlivestock.datagen.domain.model.DatagenFarmRules;
import com.smartlivestock.iot.domain.model.DeviceType;

public record ActiveInstallationInfo(Long deviceId, Long livestockId, DeviceType deviceType,
                                     Double latitude, Double longitude,
                                     DatagenFarmRules rules) {
    // Backward-compat for callers without coordinates
    public ActiveInstallationInfo(Long deviceId, Long livestockId, DeviceType deviceType) {
        this(deviceId, livestockId, deviceType, null, null,
                DatagenFarmRules.defaults());
    }

    public ActiveInstallationInfo(Long deviceId, Long livestockId, DeviceType deviceType,
                                  Double latitude, Double longitude) {
        this(deviceId, livestockId, deviceType, latitude, longitude,
                DatagenFarmRules.defaults());
    }
}
