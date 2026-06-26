package com.smartlivestock.datagen.domain.port.dto;

import com.smartlivestock.iot.domain.model.DeviceType;

public record ActiveInstallationInfo(Long deviceId, Long livestockId, DeviceType deviceType) {}
