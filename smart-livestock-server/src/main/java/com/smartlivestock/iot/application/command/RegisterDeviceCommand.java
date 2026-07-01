package com.smartlivestock.iot.application.command;

import com.smartlivestock.iot.domain.model.DeviceType;

public record RegisterDeviceCommand(String deviceCode, DeviceType deviceType, Long tenantId, String devEui) {
}
